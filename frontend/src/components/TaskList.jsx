import { motion, AnimatePresence } from 'framer-motion';
import { useTasks } from '../hooks/useTasks';
import TaskItem from './TaskItem';
import TaskForm from './TaskForm';
import FilterButtons from './FilterButtons';
import EmptyState from './EmptyState';
import LoadingState from './LoadingState';
import DarkModeToggle from './DarkModeToggle';
import { useDarkMode } from '../hooks/useDarkMode';
import { Toaster } from 'react-hot-toast';
import { Sparkles } from 'lucide-react';

/**
 * Task List Component
 * Main container component that orchestrates all task management features
 */
const TaskList = () => {
  const { isDark, toggleDarkMode } = useDarkMode();
  const {
    tasks,
    loading,
    filter,
    setFilter,
    createTask,
    toggleComplete,
    deleteTask,
  } = useTasks();

  return (
    <div className="min-h-screen py-8 px-4 sm:px-6 lg:px-8">
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 3000,
          style: {
            background: isDark ? '#1e293b' : '#fff',
            color: isDark ? '#e2e8f0' : '#1e293b',
            border: `1px solid ${isDark ? '#334155' : '#e2e8f0'}`,
          },
          success: {
            iconTheme: {
              primary: '#6366f1',
              secondary: '#fff',
            },
          },
          error: {
            iconTheme: {
              primary: '#ef4444',
              secondary: '#fff',
            },
          },
        }}
      />

      {/* Header */}
      <motion.header
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="max-w-4xl mx-auto mb-8"
      >
        <div className="flex items-center justify-between mb-6">
          <div>
            <motion.h1
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 }}
              className="text-4xl sm:text-5xl font-bold text-gradient font-display mb-2"
            >
              Xtask
            </motion.h1>
            <motion.p
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2 }}
              className="text-slate-600 dark:text-slate-400"
            >
              Beautiful task management made simple
            </motion.p>
          </div>
          <motion.div
            initial={{ opacity: 0, scale: 0 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.3, type: 'spring' }}
          >
            <DarkModeToggle isDark={isDark} onToggle={toggleDarkMode} />
          </motion.div>
        </div>

        {/* Filter Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          <FilterButtons filter={filter} onFilterChange={setFilter} />
        </motion.div>
      </motion.header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto">
        {/* Loading State */}
        {loading && <LoadingState count={3} />}

        {/* Task List */}
        {!loading && tasks.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="space-y-4 flex flex-col items-center"
          >
            <AnimatePresence mode="popLayout">
              {tasks.map((task, index) => (
                <motion.div
                  key={task.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.05 }}
                  className="w-full max-w-2xl"
                >
                  <TaskItem
                    task={task}
                    onToggle={toggleComplete}
                    onDelete={deleteTask}
                  />
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        )}

        {/* Empty State */}
        {!loading && tasks.length === 0 && (
          <EmptyState filter={filter} />
        )}

        {/* Stats */}
        {!loading && tasks.length > 0 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="mt-8 text-center"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 glass rounded-full">
              <Sparkles className="w-4 h-4 text-primary-500" />
              <span className="text-sm text-slate-600 dark:text-slate-400">
                {tasks.length} {tasks.length === 1 ? 'task' : 'tasks'}
              </span>
            </div>
          </motion.div>
        )}
      </main>

      {/* Task Form */}
      <TaskForm onSubmit={createTask} />
    </div>
  );
};

export default TaskList;

