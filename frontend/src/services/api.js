import axios from 'axios';
import toast from 'react-hot-toast';

// Create axios instance with base configuration
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 seconds timeout
});

// Request interceptor for logging (optional, can be removed in production)
api.interceptors.request.use(
  (config) => {
    // Add any auth tokens here if needed in the future
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    // Handle different error types
    if (error.response) {
      // Server responded with error status
      const { status, data } = error.response;
      
      if (status === 404) {
        toast.error('Task not found');
      } else if (status === 400) {
        // Validation errors
        const errors = data;
        if (typeof errors === 'object') {
          Object.keys(errors).forEach((key) => {
            const errorMessages = Array.isArray(errors[key]) ? errors[key] : [errors[key]];
            errorMessages.forEach((msg) => toast.error(`${key}: ${msg}`));
          });
        } else {
          toast.error('Invalid request');
        }
      } else if (status >= 500) {
        toast.error('Server error. Please try again later.');
      }
    } else if (error.request) {
      // Request made but no response received
      toast.error('Unable to connect to server. Please check your connection.');
    } else {
      // Something else happened
      toast.error('An unexpected error occurred');
    }
    
    return Promise.reject(error);
  }
);

// API methods for tasks
export const taskAPI = {
  // Get all tasks with optional filtering
  getAll: async (params = {}) => {
    const response = await api.get('/tasks/', { params });
    return response.data;
  },

  // Get single task by ID
  getById: async (id) => {
    const response = await api.get(`/tasks/${id}/`);
    return response.data;
  },

  // Create new task
  create: async (taskData) => {
    const response = await api.post('/tasks/', taskData);
    return response.data;
  },

  // Update task (partial update)
  update: async (id, taskData) => {
    const response = await api.patch(`/tasks/${id}/`, taskData);
    return response.data;
  },

  // Delete task
  delete: async (id) => {
    await api.delete(`/tasks/${id}/`);
    return id;
  },
};

export default api;

