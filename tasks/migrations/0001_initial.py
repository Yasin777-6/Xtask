# Generated manually for initial Task model

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Task',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(help_text='Task title (required, max 200 characters)', max_length=200)),
                ('description', models.TextField(blank=True, help_text='Optional task description', null=True)),
                ('completed', models.BooleanField(default=False, help_text='Task completion status')),
                ('created_at', models.DateTimeField(auto_now_add=True, help_text='Timestamp when task was created')),
            ],
            options={
                'verbose_name': 'Task',
                'verbose_name_plural': 'Tasks',
                'ordering': ['-created_at'],
            },
        ),
    ]

