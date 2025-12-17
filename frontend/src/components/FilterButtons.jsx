import { motion } from 'framer-motion';
import { List, Circle, CheckCircle2 } from 'lucide-react';

/**
 * Filter Buttons Component
 * Beautiful filter buttons with smooth transitions
 */
const FilterButtons = ({ filter, onFilterChange }) => {
  const filters = [
    { id: 'all', label: 'All', icon: List },
    { id: 'active', label: 'Active', icon: Circle },
    { id: 'completed', label: 'Completed', icon: CheckCircle2 },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex gap-2 p-1 glass rounded-xl shadow-lg"
    >
      {filters.map(({ id, label, icon: Icon }) => (
        <motion.button
          key={id}
          onClick={() => onFilterChange(id)}
          className={`relative flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg font-medium transition-all duration-300 ${
            filter === id
              ? 'text-white'
              : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100'
          }`}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          {/* Active background */}
          {filter === id && (
            <motion.div
              layoutId="activeFilter"
              className="absolute inset-0 bg-gradient-to-r from-primary-500 to-secondary-500 rounded-lg shadow-lg"
              transition={{ type: 'spring', stiffness: 500, damping: 30 }}
            />
          )}
          
          <Icon className={`relative z-10 w-4 h-4 ${filter === id ? 'text-white' : ''}`} />
          <span className="relative z-10">{label}</span>
        </motion.button>
      ))}
    </motion.div>
  );
};

export default FilterButtons;

