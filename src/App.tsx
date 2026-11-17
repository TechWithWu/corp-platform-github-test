/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  CheckCircle2,
  Circle,
  Plus,
  Trash2,
  Play,
  Pause,
  RotateCcw,
  Volume2,
  VolumeX,
  Sun,
  Moon,
  Copy,
  Check,
  Headphones,
  Sliders,
  Calendar,
  Clock,
  Sparkles,
  BarChart2,
  AlertCircle
} from 'lucide-react';

interface Task {
  id: string;
  title: string;
  priority: 'high' | 'normal' | 'low';
  completed: boolean;
  createdAt: number;
}

type FilterType = 'all' | 'active' | 'completed';
type TimerMode = 'pomodoro' | 'shortBreak' | 'longBreak';

const TIMER_DURATIONS: Record<TimerMode, number> = {
  pomodoro: 25 * 60,
  shortBreak: 5 * 60,
  longBreak: 15 * 60,
};

export default function App() {
  // Theme state
  const [isDark, setIsDark] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('dayflow_theme');
      if (saved) return saved === 'dark';
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }
    return false;
  });

  // Apply dark mode class to <html>
  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
      localStorage.setItem('dayflow_theme', 'dark');
    } else {
      root.classList.remove('dark');
      localStorage.setItem('dayflow_theme', 'light');
    }
  }, [isDark]);

  // Tasks state
  const [tasks, setTasks] = useState<Task[]>(() => {
    const saved = localStorage.getItem('dayflow_tasks');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        // fallback
      }
    }
    return [
      { id: '1', title: 'Review today’s key priorities and roadmap', priority: 'high', completed: true, createdAt: Date.now() - 3600000 },
      { id: '2', title: 'Deep work sprint: complete core deliverables', priority: 'high', completed: false, createdAt: Date.now() - 1800000 },
      { id: '3', title: 'Organize notes & draft end-of-day summary', priority: 'normal', completed: false, createdAt: Date.now() },
    ];
  });

  useEffect(() => {
    localStorage.setItem('dayflow_tasks', JSON.stringify(tasks));
  }, [tasks]);

  const [newTaskTitle, setNewTaskTitle] = useState('');
  const [newTaskPriority, setNewTaskPriority] = useState<'high' | 'normal' | 'low'>('normal');
  const [taskFilter, setTaskFilter] = useState<FilterType>('all');

  // Timer state
  const [timerMode, setTimerMode] = useState<TimerMode>('pomodoro');
  const [timeLeft, setTimeLeft] = useState<number>(TIMER_DURATIONS.pomodoro);
  const [isRunning, setIsRunning] = useState<boolean>(false);
  const [completedSessions, setCompletedSessions] = useState<number>(() => {
    return parseInt(localStorage.getItem('dayflow_sessions') || '2', 10);
  });
  const [soundEnabled, setSoundEnabled] = useState<boolean>(true);

  // Scratchpad state
  const [notes, setNotes] = useState<string>(() => {
    return localStorage.getItem('dayflow_notes') || 'Quick thoughts & brain dumps:\n- Focus on one task at a time for optimal momentum.\n- Remember to hydrate every 45 minutes.';
  });
  const [copiedNote, setCopiedNote] = useState<boolean>(false);

  // Ambient Sound Generator (synthesized via Web Audio API, 100% offline & self-contained)
  const [ambientPlaying, setAmbientPlaying] = useState<boolean>(false);
  const [ambientVolume, setAmbientVolume] = useState<number>(0.25);
  const ambientAudioCtxRef = useRef<AudioContext | null>(null);
  const ambientGainNodeRef = useRef<GainNode | null>(null);
  const ambientSourceRef = useRef<AudioBufferSourceNode | null>(null);

  // Date representation
  const todayFormatted = useMemo(() => {
    return new Intl.DateTimeFormat('en-US', {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
    }).format(new Date());
  }, []);

  // Web Audio Chime generator
  const playChime = () => {
    if (!soundEnabled) return;
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      const ctx = new AudioCtx();
      const now = ctx.currentTime;
      // Two-note peaceful harmonic chime (F5 -> C6)
      const notesToPlay = [698.46, 1046.5];
      notesToPlay.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + idx * 0.12);
        gain.gain.setValueAtTime(0.18, now + idx * 0.12);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + idx * 0.12 + 1.2);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now + idx * 0.12);
        osc.stop(now + idx * 0.12 + 1.2);
      });
    } catch {
      // Audio not permitted or supported
    }
  };

  // Ambient Rain Audio Synthesis
  const toggleAmbientSound = () => {
    if (ambientPlaying) {
      if (ambientSourceRef.current) {
        try {
          ambientSourceRef.current.stop();
          ambientSourceRef.current.disconnect();
        } catch {
          // ignore
        }
        ambientSourceRef.current = null;
      }
      if (ambientAudioCtxRef.current) {
        ambientAudioCtxRef.current.close().catch(() => {});
        ambientAudioCtxRef.current = null;
      }
      setAmbientPlaying(false);
    } else {
      try {
        const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
        const ctx = new AudioCtx();
        ambientAudioCtxRef.current = ctx;

        // Create 4 seconds of looping low-pass filtered noise to simulate gentle rain
        const bufferSize = ctx.sampleRate * 4;
        const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
        const data = buffer.getChannelData(0);
        let lastOut = 0.0;
        for (let i = 0; i < bufferSize; i++) {
          const white = Math.random() * 2 - 1;
          // Pink-ish noise filter
          data[i] = (lastOut + 0.02 * white) / 1.02;
          lastOut = data[i];
          data[i] *= 3.5;
        }

        const source = ctx.createBufferSource();
        source.buffer = buffer;
        source.loop = true;

        const filter = ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(650, ctx.currentTime);

        const gainNode = ctx.createGain();
        gainNode.gain.setValueAtTime(ambientVolume, ctx.currentTime);
        ambientGainNodeRef.current = gainNode;

        source.connect(filter);
        filter.connect(gainNode);
        gainNode.connect(ctx.destination);

        source.start();
        ambientSourceRef.current = source;
        setAmbientPlaying(true);
      } catch (err) {
        console.error('Audio initialization error:', err);
      }
    }
  };

  // Update ambient volume
  const handleVolumeChange = (newVol: number) => {
    setAmbientVolume(newVol);
    if (ambientGainNodeRef.current && ambientAudioCtxRef.current) {
      ambientGainNodeRef.current.gain.setValueAtTime(newVol, ambientAudioCtxRef.current.currentTime);
    }
  };

  // Clean up audio on unmount
  useEffect(() => {
    return () => {
      if (ambientSourceRef.current) {
        try {
          ambientSourceRef.current.stop();
        } catch {}
      }
      if (ambientAudioCtxRef.current) {
        ambientAudioCtxRef.current.close().catch(() => {});
      }
    };
  }, []);

  // Timer interval handling
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;
    if (isRunning && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft((prev) => prev - 1);
      }, 1000);
    } else if (isRunning && timeLeft === 0) {
      setIsRunning(false);
      playChime();
      if (timerMode === 'pomodoro') {
        const newCount = completedSessions + 1;
        setCompletedSessions(newCount);
        localStorage.setItem('dayflow_sessions', newCount.toString());
      }
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isRunning, timeLeft, timerMode, completedSessions, soundEnabled]);

  const switchTimerMode = (mode: TimerMode) => {
    setIsRunning(false);
    setTimerMode(mode);
    setTimeLeft(TIMER_DURATIONS[mode]);
  };

  const resetTimer = () => {
    setIsRunning(false);
    setTimeLeft(TIMER_DURATIONS[timerMode]);
  };

  // Format MM:SS with tabular mono numerals
  const formattedTime = useMemo(() => {
    const mins = Math.floor(timeLeft / 60);
    const secs = timeLeft % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }, [timeLeft]);

  // Timer progress calculation for SVG ring
  const timerPercentage = useMemo(() => {
    const total = TIMER_DURATIONS[timerMode];
    return ((total - timeLeft) / total) * 100;
  }, [timeLeft, timerMode]);

  // Task management handlers
  const handleAddTask = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = newTaskTitle.trim();
    if (!trimmed) return;
    const newTask: Task = {
      id: Date.now().toString(),
      title: trimmed,
      priority: newTaskPriority,
      completed: false,
      createdAt: Date.now(),
    };
    setTasks((prev) => [newTask, ...prev]);
    setNewTaskTitle('');
  };

  const toggleTask = (id: string) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t))
    );
  };

  const deleteTask = (id: string) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
  };

  const clearCompletedTasks = () => {
    setTasks((prev) => prev.filter((t) => !t.completed));
  };

  const markAllComplete = () => {
    setTasks((prev) => prev.map((t) => ({ ...t, completed: true })));
  };

  // Filtered tasks
  const filteredTasks = useMemo(() => {
    if (taskFilter === 'active') return tasks.filter((t) => !t.completed);
    if (taskFilter === 'completed') return tasks.filter((t) => t.completed);
    return tasks;
  }, [tasks, taskFilter]);

  const completedCount = useMemo(() => tasks.filter((t) => t.completed).length, [tasks]);
  const completionPercentage = useMemo(() => {
    if (tasks.length === 0) return 0;
    return Math.round((completedCount / tasks.length) * 100);
  }, [completedCount, tasks.length]);

  // Notes word & character count
  const notesStats = useMemo(() => {
    const words = notes.trim() ? notes.trim().split(/\s+/).length : 0;
    const chars = notes.length;
    return { words, chars };
  }, [notes]);

  const handleNotesChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value;
    setNotes(val);
    localStorage.setItem('dayflow_notes', val);
  };

  const handleCopyNotes = () => {
    navigator.clipboard.writeText(notes);
    setCopiedNote(true);
    setTimeout(() => setCopiedNote(false), 2000);
  };

  const handleClearNotes = () => {
    if (window.confirm('Clear all scratchpad notes?')) {
      setNotes('');
      localStorage.setItem('dayflow_notes', '');
    }
  };

  // Quick reset day helper
  const handleResetDay = () => {
    if (window.confirm('Reset today’s completed tasks and focus sessions? (Uncompleted tasks will remain)')) {
      setTasks((prev) => prev.map((t) => ({ ...t, completed: false })));
      setCompletedSessions(0);
      localStorage.setItem('dayflow_sessions', '0');
    }
  };

  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 text-neutral-900 dark:text-neutral-100 flex flex-col font-sans transition-colors duration-200">
      {/* Top Bar Contract: 3 distinct zones separated by gap-8 */}
      <header className="border-b border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-8">
          {/* Zone 1: Brand title, one line */}
          <div className="flex items-center gap-3 shrink-0">
            <span className="text-xl font-bold tracking-tight text-neutral-900 dark:text-white whitespace-nowrap">
              DayFlow
            </span>
          </div>

          {/* Zone 2: Informational context / clean unboxed metadata with separators */}
          <div className="hidden md:flex items-center gap-3 text-xs font-medium text-neutral-500 dark:text-neutral-400">
            <span className="flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-neutral-400 dark:text-neutral-500" />
              <span>{todayFormatted}</span>
            </span>
            <span aria-hidden="true">·</span>
            <span className="tabular-nums">{completedCount} of {tasks.length} tasks done</span>
            <span aria-hidden="true">·</span>
            <span className="tabular-nums">{completedSessions * 25} min focused</span>
          </div>

          {/* Zone 3: Primary utility actions */}
          <div className="flex items-center gap-2 shrink-0">
            {/* Ambient Sound Trigger */}
            <button
              onClick={toggleAmbientSound}
              title={ambientPlaying ? 'Stop Soft Rain Focus Audio' : 'Start Soft Rain Focus Audio'}
              className={`p-2 rounded-lg text-xs font-medium transition-colors flex items-center gap-1.5 ${
                ambientPlaying
                  ? 'bg-amber-100 dark:bg-amber-950/60 text-amber-900 dark:text-amber-200 border border-amber-300 dark:border-amber-800'
                  : 'text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800'
              }`}
            >
              <Headphones className="w-4 h-4" />
              <span className="hidden sm:inline whitespace-nowrap">
                {ambientPlaying ? 'Rain On' : 'Focus Audio'}
              </span>
            </button>

            {/* Dark Mode Switcher */}
            <button
              onClick={() => setIsDark(!isDark)}
              title={isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme'}
              className="p-2 rounded-lg text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
            >
              {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>

            {/* Quick Reset Option */}
            <button
              onClick={handleResetDay}
              title="Reset day progress"
              className="px-3 py-1.5 text-xs font-medium text-neutral-700 dark:text-neutral-300 bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 rounded-lg transition-colors whitespace-nowrap shrink-0"
            >
              Reset Day
            </button>
          </div>
        </div>
      </header>

      {/* Main Viewport Content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Subtle greeting & daily overview bar */}
        <section className="mb-8">
          <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pb-6 border-b border-neutral-200 dark:border-neutral-800">
            <div>
              <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-neutral-900 dark:text-white">
                Daily Focus Studio
              </h1>
              <p className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">
                Single-page personal workspace for focused execution and mindful progress.
              </p>
            </div>

            {/* Completion strip */}
            <div className="flex items-center gap-4 bg-white dark:bg-neutral-900 p-3 rounded-xl border border-neutral-200 dark:border-neutral-800 shrink-0">
              <div className="w-28 sm:w-36">
                <div className="flex justify-between text-xs text-neutral-500 dark:text-neutral-400 mb-1">
                  <span>Task Progress</span>
                  <span className="font-mono tabular-nums font-semibold text-neutral-900 dark:text-neutral-100">
                    {completionPercentage}%
                  </span>
                </div>
                <div className="w-full h-2 bg-neutral-100 dark:bg-neutral-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-emerald-500 rounded-full transition-all duration-300"
                    style={{ width: `${completionPercentage}%` }}
                  />
                </div>
              </div>

              <div className="h-8 w-px bg-neutral-200 dark:bg-neutral-800" />

              <div className="text-right">
                <div className="text-xs text-neutral-500 dark:text-neutral-400">Flow Sessions</div>
                <div className="text-sm font-semibold font-mono tabular-nums text-neutral-900 dark:text-neutral-100">
                  {completedSessions} <span className="text-xs font-normal text-neutral-400">done</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Ambient audio volume slider banner (revealed when ambient audio is active) */}
        {ambientPlaying && (
          <div className="mb-6 p-3 bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900/60 rounded-xl flex items-center justify-between gap-4 text-xs text-amber-900 dark:text-amber-200">
            <div className="flex items-center gap-2">
              <Headphones className="w-4 h-4 text-amber-700 dark:text-amber-400 shrink-0" />
              <span>Soft Rain focus audio is currently playing in your browser.</span>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-neutral-500 dark:text-neutral-400">Volume</span>
              <input
                type="range"
                min="0.05"
                max="0.8"
                step="0.05"
                value={ambientVolume}
                onChange={(e) => handleVolumeChange(parseFloat(e.target.value))}
                className="w-24 accent-amber-600 dark:accent-amber-500 cursor-pointer"
              />
              <button
                onClick={toggleAmbientSound}
                className="text-amber-800 dark:text-amber-300 hover:underline font-medium"
              >
                Mute
              </button>
            </div>
          </div>
        )}

        {/* Two-Column Structured Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Column 1: Daily Tasks (7 columns) */}
          <div className="lg:col-span-7 space-y-6">
            <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-6 shadow-xs">
              {/* Card Header */}
              <div className="flex items-center justify-between mb-5">
                <div>
                  <h2 className="text-base font-semibold text-neutral-900 dark:text-white">
                    Today’s Tasks
                  </h2>
                  <div className="flex items-center gap-2 text-xs text-neutral-500 dark:text-neutral-400 mt-0.5">
                    <span className="font-mono tabular-nums">{tasks.filter((t) => !t.completed).length} pending</span>
                    <span aria-hidden="true">·</span>
                    <span className="font-mono tabular-nums">{completedCount} completed</span>
                  </div>
                </div>

                {/* Filter Segmented Control */}
                <div className="flex items-center p-1 bg-neutral-100 dark:bg-neutral-800/80 rounded-lg">
                  <button
                    onClick={() => setTaskFilter('all')}
                    className={`px-3 py-1 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                      taskFilter === 'all'
                        ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-xs'
                        : 'text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white'
                    }`}
                  >
                    All ({tasks.length})
                  </button>
                  <button
                    onClick={() => setTaskFilter('active')}
                    className={`px-3 py-1 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                      taskFilter === 'active'
                        ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-xs'
                        : 'text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white'
                    }`}
                  >
                    Active
                  </button>
                  <button
                    onClick={() => setTaskFilter('completed')}
                    className={`px-3 py-1 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                      taskFilter === 'completed'
                        ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-xs'
                        : 'text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white'
                    }`}
                  >
                    Done
                  </button>
                </div>
              </div>

              {/* Add Task Input Form */}
              <form onSubmit={handleAddTask} className="mb-6">
                <div className="flex flex-col sm:flex-row gap-2">
                  <div className="relative flex-1">
                    <input
                      type="text"
                      placeholder="Add a new priority task..."
                      value={newTaskTitle}
                      onChange={(e) => setNewTaskTitle(e.target.value)}
                      className="w-full px-4 py-2.5 bg-neutral-50 dark:bg-neutral-950 border border-neutral-200 dark:border-neutral-800 rounded-xl text-sm text-neutral-900 dark:text-neutral-100 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-neutral-900 dark:focus:ring-neutral-100 transition-all"
                    />
                  </div>

                  {/* Priority selector */}
                  <div className="flex items-center gap-2 shrink-0">
                    <select
                      value={newTaskPriority}
                      onChange={(e) => setNewTaskPriority(e.target.value as 'high' | 'normal' | 'low')}
                      className="px-3 py-2.5 bg-neutral-50 dark:bg-neutral-950 border border-neutral-200 dark:border-neutral-800 rounded-xl text-xs font-medium text-neutral-700 dark:text-neutral-300 focus:outline-none focus:ring-2 focus:ring-neutral-900 dark:focus:ring-neutral-100 cursor-pointer"
                    >
                      <option value="normal">Normal Priority</option>
                      <option value="high">High Priority</option>
                      <option value="low">Low Priority</option>
                    </select>

                    <button
                      type="submit"
                      disabled={!newTaskTitle.trim()}
                      className="px-4 py-2.5 bg-neutral-900 hover:bg-neutral-800 dark:bg-neutral-100 dark:hover:bg-white text-white dark:text-neutral-900 rounded-xl text-xs font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center gap-1.5 whitespace-nowrap shrink-0"
                    >
                      <Plus className="w-4 h-4" />
                      <span>Add</span>
                    </button>
                  </div>
                </div>
              </form>

              {/* Task List */}
              <div className="space-y-2">
                {filteredTasks.length === 0 ? (
                  <div className="py-12 text-center border border-dashed border-neutral-200 dark:border-neutral-800 rounded-xl">
                    <AlertCircle className="w-6 h-6 text-neutral-400 mx-auto mb-2" />
                    <p className="text-sm font-medium text-neutral-700 dark:text-neutral-300">
                      {taskFilter === 'all'
                        ? 'No tasks yet today.'
                        : taskFilter === 'active'
                        ? 'No active tasks remaining!'
                        : 'No completed tasks yet.'}
                    </p>
                    <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-1">
                      {taskFilter === 'all'
                        ? 'Add your first task above to start your flow.'
                        : 'Great work keeping on top of your priorities.'}
                    </p>
                  </div>
                ) : (
                  filteredTasks.map((task) => (
                    <div
                      key={task.id}
                      className={`group flex items-center justify-between p-3 rounded-xl border transition-all ${
                        task.completed
                          ? 'bg-neutral-50/60 dark:bg-neutral-950/40 border-neutral-200/60 dark:border-neutral-800/60 opacity-75'
                          : 'bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 hover:border-neutral-300 dark:hover:border-neutral-700 shadow-2xs'
                      }`}
                    >
                      <div className="flex items-center gap-3 min-w-0 flex-1">
                        <button
                          onClick={() => toggleTask(task.id)}
                          className="text-neutral-400 hover:text-neutral-900 dark:hover:text-neutral-100 transition-colors shrink-0"
                        >
                          {task.completed ? (
                            <CheckCircle2 className="w-5 h-5 text-emerald-600 dark:text-emerald-500" />
                          ) : (
                            <Circle className="w-5 h-5 text-neutral-300 dark:text-neutral-600 hover:text-neutral-500" />
                          )}
                        </button>

                        <div className="min-w-0 flex-1">
                          <p
                            className={`text-sm truncate ${
                              task.completed
                                ? 'line-through text-neutral-400 dark:text-neutral-500'
                                : 'text-neutral-800 dark:text-neutral-200 font-medium'
                            }`}
                          >
                            {task.title}
                          </p>
                        </div>

                        {/* Priority marker - Clean unboxed text with subtle color distinction */}
                        <div className="text-xs font-medium shrink-0 px-2">
                          {task.priority === 'high' && (
                            <span className="text-rose-600 dark:text-rose-400">High</span>
                          )}
                          {task.priority === 'low' && (
                            <span className="text-neutral-400 dark:text-neutral-500">Low</span>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center gap-1 shrink-0 ml-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => deleteTask(task.id)}
                          title="Delete task"
                          className="p-1.5 text-neutral-400 hover:text-rose-600 dark:hover:text-rose-400 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Task Footer Actions */}
              {tasks.length > 0 && (
                <div className="mt-6 pt-4 border-t border-neutral-100 dark:border-neutral-800/80 flex items-center justify-between text-xs text-neutral-500 dark:text-neutral-400">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={markAllComplete}
                      className="hover:text-neutral-900 dark:hover:text-white transition-colors"
                    >
                      Mark all done
                    </button>
                    <span aria-hidden="true">·</span>
                    <button
                      onClick={clearCompletedTasks}
                      className="hover:text-rose-600 dark:hover:text-rose-400 transition-colors"
                    >
                      Clear completed ({completedCount})
                    </button>
                  </div>

                  <span className="font-mono tabular-nums text-neutral-400">
                    {tasks.length} total
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* Column 2: Pomodoro Focus Timer & Scratchpad (5 columns) */}
          <div className="lg:col-span-5 space-y-6">
            {/* Focus Timer Card */}
            <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-6 shadow-xs">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold text-neutral-900 dark:text-white flex items-center gap-2">
                  <Clock className="w-4 h-4 text-neutral-500" />
                  <span>Focus Timer</span>
                </h2>

                <button
                  onClick={() => setSoundEnabled(!soundEnabled)}
                  title={soundEnabled ? 'Chime sound is active' : 'Chime sound is muted'}
                  className="p-1.5 text-neutral-500 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors"
                >
                  {soundEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4 text-neutral-400" />}
                </button>
              </div>

              {/* Mode Selector Tabs */}
              <div className="flex items-center justify-center p-1 bg-neutral-100 dark:bg-neutral-800/80 rounded-xl mb-6">
                <button
                  onClick={() => switchTimerMode('pomodoro')}
                  className={`flex-1 py-1.5 text-xs font-medium rounded-lg transition-colors whitespace-nowrap ${
                    timerMode === 'pomodoro'
                      ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-xs'
                      : 'text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white'
                  }`}
                >
                  Focus (25m)
                </button>
                <button
                  onClick={() => switchTimerMode('shortBreak')}
                  className={`flex-1 py-1.5 text-xs font-medium rounded-lg transition-colors whitespace-nowrap ${
                    timerMode === 'shortBreak'
                      ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-xs'
                      : 'text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white'
                  }`}
                >
                  Short (5m)
                </button>
                <button
                  onClick={() => switchTimerMode('longBreak')}
                  className={`flex-1 py-1.5 text-xs font-medium rounded-lg transition-colors whitespace-nowrap ${
                    timerMode === 'longBreak'
                      ? 'bg-white dark:bg-neutral-700 text-neutral-900 dark:text-white shadow-xs'
                      : 'text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white'
                  }`}
                >
                  Long (15m)
                </button>
              </div>

              {/* Circular Timer Visual Display */}
              <div className="flex flex-col items-center justify-center py-4">
                <div className="relative w-48 h-48 flex items-center justify-center">
                  <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
                    <circle
                      cx="50"
                      cy="50"
                      r="44"
                      className="text-neutral-100 dark:text-neutral-800 stroke-current"
                      strokeWidth="6"
                      fill="transparent"
                    />
                    <circle
                      cx="50"
                      cy="50"
                      r="44"
                      className="text-neutral-900 dark:text-neutral-100 stroke-current transition-all duration-500 ease-linear"
                      strokeWidth="6"
                      strokeDasharray={276.46}
                      strokeDashoffset={276.46 - (276.46 * timerPercentage) / 100}
                      strokeLinecap="round"
                      fill="transparent"
                    />
                  </svg>

                  <div className="absolute flex flex-col items-center justify-center text-center">
                    <span className="text-4xl font-bold font-mono tabular-nums tracking-tight text-neutral-900 dark:text-white">
                      {formattedTime}
                    </span>
                    <span className="text-xs text-neutral-400 mt-1 capitalize font-medium">
                      {timerMode === 'pomodoro' ? 'Deep Work' : 'Break Time'}
                    </span>
                  </div>
                </div>

                {/* Timer Controls */}
                <div className="flex items-center gap-3 mt-6">
                  <button
                    onClick={() => setIsRunning(!isRunning)}
                    className="px-6 py-2.5 bg-neutral-900 hover:bg-neutral-800 dark:bg-neutral-100 dark:hover:bg-white text-white dark:text-neutral-900 rounded-xl text-sm font-semibold transition-colors flex items-center gap-2 shadow-xs whitespace-nowrap"
                  >
                    {isRunning ? (
                      <>
                        <Pause className="w-4 h-4" />
                        <span>Pause</span>
                      </>
                    ) : (
                      <>
                        <Play className="w-4 h-4 fill-current" />
                        <span>Start</span>
                      </>
                    )}
                  </button>

                  <button
                    onClick={resetTimer}
                    title="Reset timer"
                    className="p-2.5 bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 text-neutral-700 dark:text-neutral-300 rounded-xl transition-colors"
                  >
                    <RotateCcw className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Sessions indicator */}
              <div className="mt-6 pt-4 border-t border-neutral-100 dark:border-neutral-800/80 flex items-center justify-between text-xs text-neutral-500 dark:text-neutral-400">
                <span>Completed today</span>
                <span className="font-mono tabular-nums font-semibold text-neutral-800 dark:text-neutral-200">
                  {completedSessions} sessions ({completedSessions * 25} min)
                </span>
              </div>
            </div>

            {/* Quick Scratchpad Card */}
            <div className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-6 shadow-xs">
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-base font-semibold text-neutral-900 dark:text-white">
                  Scratchpad Notes
                </h2>
                <div className="flex items-center gap-2">
                  <button
                    onClick={handleCopyNotes}
                    title="Copy note to clipboard"
                    className="px-2.5 py-1 text-xs text-neutral-600 dark:text-neutral-400 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors flex items-center gap-1.5"
                  >
                    {copiedNote ? (
                      <>
                        <Check className="w-3.5 h-3.5 text-emerald-600" />
                        <span className="text-emerald-600 font-medium">Copied</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5" />
                        <span>Copy</span>
                      </>
                    )}
                  </button>
                  <button
                    onClick={handleClearNotes}
                    title="Clear scratchpad"
                    className="p-1 text-neutral-400 hover:text-rose-600 dark:hover:text-rose-400 rounded transition-colors"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              <textarea
                value={notes}
                onChange={handleNotesChange}
                placeholder="Type temporary notes, links, or quick ideas here. Saves automatically..."
                rows={5}
                className="w-full p-3 bg-neutral-50 dark:bg-neutral-950 border border-neutral-200 dark:border-neutral-800 rounded-xl text-xs sm:text-sm text-neutral-800 dark:text-neutral-200 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-neutral-900 dark:focus:ring-neutral-100 transition-all resize-y leading-relaxed"
              />

              <div className="mt-3 flex items-center justify-between text-xs text-neutral-400 dark:text-neutral-500">
                <span className="font-mono tabular-nums">
                  {notesStats.words} words · {notesStats.chars} chars
                </span>
                <span className="text-[11px] text-neutral-400">Autosaves locally</span>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="mt-auto border-t border-neutral-200 dark:border-neutral-800 py-6 bg-white dark:bg-neutral-900 text-xs text-neutral-500 dark:text-neutral-400">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-neutral-800 dark:text-neutral-200">DayFlow</span>
            <span aria-hidden="true">·</span>
            <span>Client-side, privacy-first single page app</span>
          </div>
          <div>
            <span>Data stored securely in local browser storage</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
