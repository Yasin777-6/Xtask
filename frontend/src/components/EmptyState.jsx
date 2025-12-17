import { motion } from 'framer-motion';
import { CheckSquare, Sparkles } from 'lucide-react';

/**
 * Empty State Component
 * Beautiful illustration when no tasks are present
 */
const EmptyState = ({ filter }) => {
  const messages = {
    all: {
      title: 'No tasks yet!',
      description: 'Create your first task to get started on your journey to productivity.',
      icon: CheckSquare,
    },
    active: {
      title: 'No active tasks',
      description: 'All your tasks are completed! Great job! 🎉',
      icon: Sparkles,
    },
    completed: {
      title: 'No completed tasks',
      description: 'Complete some tasks to see them here.',
      icon: CheckSquare,
    },
  };

  const { title, description, icon: Icon } = messages[filter] || messages.all;

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
      className="flex flex-col items-center justify-center py-16 px-4"
    >
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
        className="mb-6"
      >
        <div className="relative">
          <div className="absolute inset-0 bg-gradient-to-r from-primary-400 to-secondary-400 rounded-full blur-2xl opacity-50" />
          <div className="relative bg-gradient-to-br from-primary-500 to-secondary-500 p-6 rounded-full">
            <Icon className="w-12 h-12 text-white" />
          </div>
        </div>
      </motion.div>

      <motion.h3
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="text-2xl font-bold text-slate-800 dark:text-slate-100 mb-2 font-display"
      >
        {title}
      </motion.h3>

      <motion.p
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="text-slate-600 dark:text-slate-400 text-center max-w-md"
      >
        {description}
      </motion.p>
    </motion.div>
  );
};

export default EmptyState;

