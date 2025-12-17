from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from .models import Task


class TaskModelTest(TestCase):
    """Test cases for Task model."""
    
    def setUp(self):
        """Set up test data."""
        self.task = Task.objects.create(
            title="Test Task",
            description="This is a test task",
            completed=False
        )
    
    def test_task_creation(self):
        """Test that a task can be created with all fields."""
        self.assertEqual(self.task.title, "Test Task")
        self.assertEqual(self.task.description, "This is a test task")
        self.assertFalse(self.task.completed)
        self.assertIsNotNone(self.task.created_at)
        self.assertIsNotNone(self.task.id)
    
    def test_task_str_representation(self):
        """Test the string representation of a task."""
        self.assertIn("Test Task", str(self.task))
        self.assertIn("Pending", str(self.task))
        
        # Test completed task
        self.task.completed = True
        self.task.save()
        self.assertIn("Completed", str(self.task))


class TaskAPITest(TestCase):
    """Test cases for Task API endpoints."""
    
    def setUp(self):
        """Set up test client and test data."""
        self.client = APIClient()
        self.task = Task.objects.create(
            title="Existing Task",
            description="An existing task",
            completed=False
        )
    
    def test_create_task(self):
        """Test creating a new task via POST /api/tasks/."""
        url = reverse('task-list')
        data = {
            'title': 'New Task',
            'description': 'A new task description',
            'completed': False
        }
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Task.objects.count(), 2)  # Original + new task
        self.assertEqual(Task.objects.get(id=response.data['id']).title, 'New Task')
    
    def test_create_task_validation(self):
        """Test that task creation validates required fields."""
        url = reverse('task-list')
        
        # Test empty title
        data = {'title': ''}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Test missing title
        data = {'description': 'No title'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
    
    def test_retrieve_all_tasks(self):
        """Test retrieving all tasks via GET /api/tasks/."""
        url = reverse('task-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)  # Assuming pagination
        self.assertEqual(response.data['results'][0]['title'], 'Existing Task')
    
    def test_retrieve_single_task(self):
        """Test retrieving a single task via GET /api/tasks/{id}/."""
        url = reverse('task-detail', kwargs={'pk': self.task.id})
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Existing Task')
        self.assertEqual(response.data['id'], self.task.id)
    
    def test_update_task_status(self):
        """Test updating task status via PATCH /api/tasks/{id}/."""
        url = reverse('task-detail', kwargs={'pk': self.task.id})
        data = {'completed': True}
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.task.refresh_from_db()
        self.assertTrue(self.task.completed)
    
    def test_delete_task(self):
        """Test deleting a task via DELETE /api/tasks/{id}/."""
        url = reverse('task-detail', kwargs={'pk': self.task.id})
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Task.objects.count(), 0)
    
    def test_delete_nonexistent_task(self):
        """Test deleting a non-existent task returns 404."""
        url = reverse('task-detail', kwargs={'pk': 99999})
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
    
    def test_filter_by_completed_status(self):
        """Test filtering tasks by completion status."""
        # Create a completed task
        Task.objects.create(title="Completed Task", completed=True)
        
        # Filter for completed tasks
        url = reverse('task-list')
        response = self.client.get(url, {'completed': 'true'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should only return completed tasks
        for task in response.data['results']:
            self.assertTrue(task['completed'])
        
        # Filter for incomplete tasks
        response = self.client.get(url, {'completed': 'false'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should only return incomplete tasks
        for task in response.data['results']:
            self.assertFalse(task['completed'])
