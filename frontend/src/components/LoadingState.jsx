import { motion } from 'framer-motion';

/**
 * Loading State Component
 * Beautiful skeleton loader with shimmer effect
 */
const LoadingState = ({ count = 3 }) => {
  return (
    <div className="space-y-4">
      {Array.from({ length: count }).map((_, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="glass rounded-xl p-6 shadow-lg"
        >
          <div className="flex items-start gap-4">
            {/* Checkbox skeleton */}
            <div className="w-6 h-6 rounded-full skeleton flex-shrink-0" />
            
            {/* Content skeleton */}
            <div className="flex-1 space-y-3">
              <div className="h-5 w-3/4 rounded skeleton" />
              <div className="h-4 w-full rounded skeleton" />
              <div className="h-4 w-2/3 rounded skeleton" />
            </div>
            
            {/* Action button skeleton */}
            <div className="w-8 h-8 rounded skeleton flex-shrink-0" />
          </div>
        </motion.div>
      ))}
    </div>
  );
};

export default LoadingState;

