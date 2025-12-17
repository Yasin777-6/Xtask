from django.contrib import admin
from .models import Task


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    """
    Admin interface configuration for Task model.
    
    Provides:
    - List display with key fields
    - Search functionality
    - Filtering by completion status and creation date
    - Read-only fields for auto-generated data
    """
    list_display = ['id', 'title', 'completed', 'created_at']
    list_filter = ['completed', 'created_at']
    search_fields = ['title', 'description']
    readonly_fields = ['id', 'created_at']
    list_editable = ['completed']  # Allow quick editing of completion status
    
    fieldsets = (
        ('Task Information', {
            'fields': ('id', 'title', 'description')
        }),
        ('Status', {
            'fields': ('completed',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
