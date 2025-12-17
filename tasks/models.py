from django.db import models


class Task(models.Model):
    """
    Task model for the task management application.
    
    Fields:
    - id: Auto-generated unique identifier (BigAutoField)
    - title: Required field, max 200 characters
    - description: Optional text field for task details
    - completed: Boolean flag indicating task completion status
    - created_at: Auto-generated timestamp when task is created
    """
    title = models.CharField(
        max_length=200,
        help_text="Task title (required, max 200 characters)"
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Optional task description"
    )
    completed = models.BooleanField(
        default=False,
        help_text="Task completion status"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when task was created"
    )

    class Meta:
        # Order tasks by creation date, newest first
        ordering = ['-created_at']
        verbose_name = 'Task'
        verbose_name_plural = 'Tasks'

    def __str__(self):
        """String representation of the task."""
        return f"{self.title} ({'Completed' if self.completed else 'Pending'})"
