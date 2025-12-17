from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.filters import SearchFilter, OrderingFilter
from .models import Task
from .serializers import TaskSerializer


class TaskViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Task model providing CRUD operations.
    
    Uses ModelViewSet which automatically provides:
    - list() - GET /api/tasks/ (retrieve all tasks)
    - create() - POST /api/tasks/ (create new task)
    - retrieve() - GET /api/tasks/{id}/ (get single task)
    - update() - PUT /api/tasks/{id}/ (full update)
    - partial_update() - PATCH /api/tasks/{id}/ (partial update, used for status)
    - destroy() - DELETE /api/tasks/{id}/ (delete task)
    
    Additional features:
    - Filtering by completion status: /api/tasks/?completed=true
    - Ordering by created_at (newest first) - configured in model Meta
    """
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['title', 'description']  # Enable search in title and description
    ordering_fields = ['created_at', 'title']  # Enable ordering
    ordering = ['-created_at']  # Default ordering: newest first

    def get_queryset(self):
        """
        Override to add custom filtering logic for completion status.
        Supports filtering by completed status: /api/tasks/?completed=true
        """
        queryset = super().get_queryset()
        completed = self.request.query_params.get('completed', None)
        
        if completed is not None:
            # Convert string to boolean
            completed_bool = completed.lower() in ('true', '1', 'yes')
            queryset = queryset.filter(completed=completed_bool)
        
        return queryset

    def destroy(self, request, *args, **kwargs):
        """
        Override destroy to provide better error handling for non-existent tasks.
        """
        try:
            instance = self.get_object()
            self.perform_destroy(instance)
            return Response(
                {'message': 'Task deleted successfully.'},
                status=status.HTTP_204_NO_CONTENT
            )
        except Task.DoesNotExist:
            return Response(
                {'error': 'Task not found.'},
                status=status.HTTP_404_NOT_FOUND
            )

    def retrieve(self, request, *args, **kwargs):
        """
        Override retrieve to provide better error handling for non-existent tasks.
        """
        try:
            return super().retrieve(request, *args, **kwargs)
        except Task.DoesNotExist:
            return Response(
                {'error': 'Task not found.'},
                status=status.HTTP_404_NOT_FOUND
            )
