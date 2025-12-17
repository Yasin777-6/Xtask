import { motion } from 'framer-motion';
import { Sun, Moon } from 'lucide-react';

/**
 * Dark Mode Toggle Component
 * Beautiful animated toggle with sun/moon icons
 */
const DarkModeToggle = ({ isDark, onToggle }) => {
  return (
    <motion.button
      onClick={onToggle}
      className="relative p-3 rounded-full bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm border border-slate-200 dark:border-slate-700 shadow-lg hover:shadow-xl transition-all duration-300 group"
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      aria-label="Toggle dark mode"
    >
      <motion.div
        className="relative w-5 h-5"
        initial={false}
        animate={{ rotate: isDark ? 180 : 0 }}
        transition={{ duration: 0.3, ease: 'easeInOut' }}
      >
        {isDark ? (
          <Moon className="w-5 h-5 text-indigo-400" />
        ) : (
          <Sun className="w-5 h-5 text-amber-500" />
        )}
      </motion.div>
      
      {/* Glow effect */}
      <motion.div
        className="absolute inset-0 rounded-full opacity-0 group-hover:opacity-100"
        style={{
          background: isDark
            ? 'radial-gradient(circle, rgba(99, 102, 241, 0.3) 0%, transparent 70%)'
            : 'radial-gradient(circle, rgba(251, 191, 36, 0.3) 0%, transparent 70%)',
        }}
        transition={{ duration: 0.3 }}
      />
    </motion.button>
  );
};

export default DarkModeToggle;

