from rest_framework import serializers
from .models import Task


class TaskSerializer(serializers.ModelSerializer):
    """
    Serializer for Task model with custom validation.
    
    Provides:
    - Field validation (title: 1-200 chars, description: max 1000 chars)
    - Custom error messages
    - Full CRUD operations support
    """
    
    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'completed', 'created_at']
        read_only_fields = ['id', 'created_at']  # These fields are auto-generated

    def validate_title(self, value):
        """
        Validate title field:
        - Required (handled by CharField)
        - Must be 1-200 characters
        - Cannot be empty or whitespace only
        """
        if not value or not value.strip():
            raise serializers.ValidationError("Title cannot be empty.")
        
        if len(value.strip()) < 1:
            raise serializers.ValidationError("Title must be at least 1 character long.")
        
        if len(value) > 200:
            raise serializers.ValidationError("Title cannot exceed 200 characters.")
        
        return value.strip()

    def validate_description(self, value):
        """
        Validate description field:
        - Optional (can be None or empty)
        - Max 1000 characters if provided
        """
        if value and len(value) > 1000:
            raise serializers.ValidationError("Description cannot exceed 1000 characters.")
        
        return value

