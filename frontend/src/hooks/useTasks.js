import { useState, useEffect, useCallback } from 'react';
import { taskAPI } from '../services/api';
import toast from 'react-hot-toast';

/**
 * Custom hook for managing tasks
 * Provides state management and CRUD operations for tasks
 */
export const useTasks = () => {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filter, setFilter] = useState('all'); // 'all', 'active', 'completed'

  // Fetch all tasks
  const fetchTasks = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await taskAPI.getAll();
      // Handle paginated response
      const taskList = data.results || data;
      setTasks(taskList);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching tasks:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // Create new task
  const createTask = useCallback(async (taskData) => {
    try {
      const newTask = await taskAPI.create(taskData);
      setTasks((prev) => [newTask, ...prev]);
      toast.success('Task created successfully! 🎉');
      return newTask;
    } catch (err) {
      toast.error('Failed to create task');
      throw err;
    }
  }, []);

  // Update task
  const updateTask = useCallback(async (id, taskData) => {
    try {
      const updatedTask = await taskAPI.update(id, taskData);
      setTasks((prev) =>
        prev.map((task) => (task.id === id ? updatedTask : task))
      );
      
      // Show success message based on what was updated
      if (taskData.completed !== undefined) {
        if (taskData.completed) {
          toast.success('Task completed! 🎊');
        } else {
          toast.success('Task marked as active');
        }
      } else {
        toast.success('Task updated successfully');
      }
      
      return updatedTask;
    } catch (err) {
      toast.error('Failed to update task');
      throw err;
    }
  }, []);

  // Delete task
  const deleteTask = useCallback(async (id) => {
    try {
      await taskAPI.delete(id);
      setTasks((prev) => prev.filter((task) => task.id !== id));
      toast.success('Task deleted successfully');
    } catch (err) {
      toast.error('Failed to delete task');
      throw err;
    }
  }, []);

  // Toggle task completion
  const toggleComplete = useCallback(
    async (id, currentStatus) => {
      await updateTask(id, { completed: !currentStatus });
    },
    [updateTask]
  );

  // Filter tasks based on current filter
  const filteredTasks = tasks.filter((task) => {
    if (filter === 'active') return !task.completed;
    if (filter === 'completed') return task.completed;
    return true; // 'all'
  });

  // Fetch tasks on mount
  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  return {
    tasks: filteredTasks,
    allTasks: tasks,
    loading,
    error,
    filter,
    setFilter,
    createTask,
    updateTask,
    deleteTask,
    toggleComplete,
    refetch: fetchTasks,
  };
};

