import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Check, Trash2, Loader2 } from 'lucide-react';
import confetti from 'canvas-confetti';

/**
 * Task Item Component
 * Beautiful task card with animations and interactions
 */
const TaskItem = ({ task, onToggle, onDelete }) => {
  const [isDeleting, setIsDeleting] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const handleToggle = async () => {
    await onToggle(task.id, task.completed);
    
    // Confetti animation when completing a task
    if (!task.completed) {
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#6366f1', '#8b5cf6', '#ec4899'],
      });
    }
  };

  const handleDelete = async () => {
    setIsDeleting(true);
    try {
      await onDelete(task.id);
    } catch (error) {
      setIsDeleting(false);
      setShowDeleteConfirm(false);
    }
  };

  return (
    <AnimatePresence mode="wait">
      <motion.div
        layout
        initial={{ opacity: 0, y: 20, scale: 0.9 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, x: 100, scale: 0.8 }}
        transition={{
          type: 'spring',
          stiffness: 300,
          damping: 30,
        }}
        className="glass rounded-xl p-5 shadow-lg card-hover group"
      >
        <div className="flex items-start gap-4">
          {/* Checkbox */}
          <motion.button
            onClick={handleToggle}
            className={`relative flex-shrink-0 w-6 h-6 rounded-full border-2 transition-all duration-300 ${
              task.completed
                ? 'bg-gradient-to-r from-primary-500 to-secondary-500 border-transparent'
                : 'border-slate-300 dark:border-slate-600 hover:border-primary-500'
            }`}
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            aria-label={task.completed ? 'Mark as incomplete' : 'Mark as complete'}
          >
            <AnimatePresence>
              {task.completed && (
                <motion.div
                  initial={{ scale: 0, rotate: -180 }}
                  animate={{ scale: 1, rotate: 0 }}
                  exit={{ scale: 0, rotate: 180 }}
                  transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  className="absolute inset-0 flex items-center justify-center"
                >
                  <Check className="w-4 h-4 text-white" strokeWidth={3} />
                </motion.div>
              )}
            </AnimatePresence>
          </motion.button>

          {/* Content */}
          <div className="flex-1 min-w-0">
            <motion.h3
              className={`text-lg font-semibold mb-1 ${
                task.completed
                  ? 'line-through text-slate-500 dark:text-slate-500'
                  : 'text-slate-800 dark:text-slate-100'
              }`}
              initial={false}
              animate={{
                opacity: task.completed ? 0.6 : 1,
              }}
              transition={{ duration: 0.3 }}
            >
              {task.title}
            </motion.h3>

            {task.description && (
              <motion.p
                className={`text-sm ${
                  task.completed
                    ? 'line-through text-slate-400 dark:text-slate-600'
                    : 'text-slate-600 dark:text-slate-400'
                }`}
                initial={false}
                animate={{
                  opacity: task.completed ? 0.5 : 1,
                }}
                transition={{ duration: 0.3 }}
              >
                {task.description}
              </motion.p>
            )}

            {/* Timestamp */}
            <motion.p
              className="text-xs text-slate-400 dark:text-slate-500 mt-2"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.2 }}
            >
              {new Date(task.created_at).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
              })}
            </motion.p>
          </div>

          {/* Delete Button */}
          <AnimatePresence>
            {!showDeleteConfirm ? (
              <motion.button
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0 }}
                whileHover={{ scale: 1.1, rotate: 5 }}
                whileTap={{ scale: 0.9 }}
                onClick={() => setShowDeleteConfirm(true)}
                className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                aria-label="Delete task"
              >
                <Trash2 className="w-5 h-5" />
              </motion.button>
            ) : (
              <motion.div
                initial={{ opacity: 0, scale: 0 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0 }}
                className="flex gap-2"
              >
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={handleDelete}
                  disabled={isDeleting}
                  className="px-3 py-1.5 text-xs font-medium bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors disabled:opacity-50"
                >
                  {isDeleting ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    'Confirm'
                  )}
                </motion.button>
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => setShowDeleteConfirm(false)}
                  disabled={isDeleting}
                  className="px-3 py-1.5 text-xs font-medium bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-300 dark:hover:bg-slate-600 transition-colors"
                >
                  Cancel
                </motion.button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Completion indicator bar */}
        {task.completed && (
          <motion.div
            initial={{ scaleX: 0 }}
            animate={{ scaleX: 1 }}
            className="mt-3 h-1 bg-gradient-to-r from-primary-500 to-secondary-500 rounded-full"
            style={{ transformOrigin: 'left' }}
          />
        )}
      </motion.div>
    </AnimatePresence>
  );
};

export default TaskItem;

