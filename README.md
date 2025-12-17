# Xtask

# Django REST Framework Task Management API

A production-ready Django REST Framework backend for a task management application with full CRUD operations, validation, filtering, and comprehensive error handling.

## Table of Contents

- [Setup Instructions](#setup-instructions)
- [API Documentation](#api-documentation)
- [Architecture Decisions](#architecture-decisions)
- [Testing the API](#testing-the-api)
- [Docker Setup](#docker-setup)

## Setup Instructions

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Virtual environment (recommended)

### Virtual Environment Setup

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

### Installing Dependencies

```bash
pip install -r requirements.txt
```

### Database Migrations

```bash
# Create migration files
python manage.py makemigrations

# Apply migrations to create database tables
python manage.py migrate
```

### Creating Superuser

```bash
python manage.py createsuperuser
```

This will allow you to access the Django admin panel at `http://localhost:8000/admin/`

### Running the Server

```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000/api/`

## API Documentation

### Base URL

All API endpoints are prefixed with `/api/`

### Endpoints

#### 1. Get All Tasks

**GET** `/api/tasks/`

Retrieve all tasks, ordered by creation date (newest first).

**Query Parameters:**
- `completed` (optional): Filter by completion status (`true` or `false`)
  - Example: `/api/tasks/?completed=true`
- `search` (optional): Search in title and description
  - Example: `/api/tasks/?search=important`
- `ordering` (optional): Order by field (`created_at`, `title`, `-created_at`, `-title`)
  - Example: `/api/tasks/?ordering=title`

**Response:** `200 OK`

```json
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "title": "Complete project",
      "description": "Finish the Django REST API",
      "completed": false,
      "created_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "title": "Review code",
      "description": "Code review session",
      "completed": true,
      "created_at": "2024-01-14T09:15:00Z"
    }
  ]
}
```

**Example curl command:**
```bash
curl -X GET http://localhost:8000/api/tasks/
```

#### 2. Create New Task

**POST** `/api/tasks/`

Create a new task.

**Request Body:**
```json
{
  "title": "New Task",
  "description": "Task description (optional)",
  "completed": false
}
```

**Validation Rules:**
- `title`: Required, 1-200 characters, cannot be empty or whitespace only
- `description`: Optional, max 1000 characters
- `completed`: Boolean, defaults to `false`

**Response:** `201 Created`

```json
{
  "id": 3,
  "title": "New Task",
  "description": "Task description",
  "completed": false,
  "created_at": "2024-01-15T11:00:00Z"
}
```

**Error Response:** `400 Bad Request`

```json
{
  "title": ["Title cannot be empty."]
}
```

**Example curl command:**
```bash
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title": "New Task", "description": "Task description", "completed": false}'
```

#### 3. Get Single Task

**GET** `/api/tasks/{id}/`

Retrieve a specific task by ID.

**Response:** `200 OK`

```json
{
  "id": 1,
  "title": "Complete project",
  "description": "Finish the Django REST API",
  "completed": false,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Error Response:** `404 Not Found`

```json
{
  "error": "Task not found."
}
```

**Example curl command:**
```bash
curl -X GET http://localhost:8000/api/tasks/1/
```

#### 4. Update Task Status

**PATCH** `/api/tasks/{id}/`

Partially update a task (typically used for updating completion status).

**Request Body:**
```json
{
  "completed": true
}
```

**Response:** `200 OK`

```json
{
  "id": 1,
  "title": "Complete project",
  "description": "Finish the Django REST API",
  "completed": true,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Example curl command:**
```bash
curl -X PATCH http://localhost:8000/api/tasks/1/ \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

#### 5. Delete Task

**DELETE** `/api/tasks/{id}/`

Delete a task by ID.

**Response:** `204 No Content`

**Error Response:** `404 Not Found`

```json
{
  "error": "Task not found."
}
```

**Example curl command:**
```bash
curl -X DELETE http://localhost:8000/api/tasks/1/
```

## Architecture Decisions

### Why Django REST Framework?

Django REST Framework (DRF) was chosen because:
- **Rapid Development**: Provides powerful tools (ViewSets, Serializers) that reduce boilerplate code
- **Built-in Features**: Authentication, permissions, pagination, filtering, and validation out of the box
- **RESTful Design**: Follows REST principles and conventions
- **Extensibility**: Easy to extend and customize for future requirements
- **Community Support**: Large community and extensive documentation

### Database Choice: SQLite

SQLite is used as the default database because:
- **Zero Configuration**: No separate database server required
- **Perfect for Development**: Ideal for prototyping and small to medium applications
- **Easy Deployment**: Single file database, easy to backup and migrate
- **Production Ready**: Can handle moderate traffic (up to ~100K requests/day)
- **Easy Migration**: Can easily switch to PostgreSQL/MySQL later if needed

### Why ModelViewSet over APIView?

ModelViewSet was chosen because:
- **DRY Principle**: Automatically provides all CRUD operations (list, create, retrieve, update, destroy)
- **Less Code**: Reduces code duplication compared to separate APIView classes
- **Consistency**: Ensures consistent API structure across all endpoints
- **Router Integration**: Works seamlessly with DRF routers for automatic URL generation
- **Extensibility**: Easy to override specific methods when custom behavior is needed

### CORS Configuration

CORS (Cross-Origin Resource Sharing) is configured to:
- **Allow Frontend Communication**: Enables requests from `localhost:5173` (Vite default port)
- **Development Flexibility**: Supports frontend frameworks running on different ports
- **Security**: Only allows specific origins, not all origins (more secure than `CORS_ALLOW_ALL_ORIGINS=True`)

**Note**: For production, update `CORS_ALLOWED_ORIGINS` in `settings.py` to include your production frontend URL.

## Testing the API

### Running Tests

```bash
python manage.py test
```

This will run all test cases in `tasks/tests.py`, including:
- Task model creation
- Task API creation
- Task retrieval (all and single)
- Task status update
- Task deletion
- Validation tests
- Filtering tests

### Manual Testing with curl

#### Create a task:
```bash
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Task", "description": "Testing the API"}'
```

#### Get all tasks:
```bash
curl http://localhost:8000/api/tasks/
```

#### Get completed tasks only:
```bash
curl "http://localhost:8000/api/tasks/?completed=true"
```

#### Update task status:
```bash
curl -X PATCH http://localhost:8000/api/tasks/1/ \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

#### Delete a task:
```bash
curl -X DELETE http://localhost:8000/api/tasks/1/
```

### Testing with Postman

1. Import the collection or create requests manually
2. Set base URL: `http://localhost:8000/api/tasks/`
3. Test each endpoint with appropriate HTTP methods
4. Check response status codes and JSON structure

## Docker Setup

### Using Docker Compose (Recommended)

```bash
# Build and start containers
docker-compose up --build

# Run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down
```

The API will be available at `http://localhost:8000/api/`

### Using Dockerfile Directly

```bash
# Build image
docker build -t task-api .

# Run container
docker run -p 8000:8000 task-api
```

### Docker Features

- **Python 3.11**: Latest stable Python version
- **Automatic Migrations**: Runs migrations on container start
- **Volume Mounting**: Code changes are reflected immediately (development)
- **Port Mapping**: Exposes API on port 8000

## Project Structure

```
backend/
├── manage.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── README.md
├── xtask/              # Django project configuration
│   ├── __init__.py
│   ├── settings.py     # Django settings with DRF and CORS config
│   ├── urls.py         # Main URL configuration
│   └── wsgi.py
└── tasks/              # Tasks app
    ├── __init__.py
    ├── models.py       # Task model definition
    ├── serializers.py  # Task serializer with validation
    ├── views.py        # TaskViewSet with CRUD operations
    ├── urls.py         # App URL routing
    ├── admin.py        # Admin panel configuration
    └── tests.py        # Test cases
```

## Key Features

✅ Full CRUD operations (Create, Read, Update, Delete)  
✅ Input validation with custom error messages  
✅ Filtering by completion status  
✅ Search functionality (title and description)  
✅ Ordering support  
✅ 404 error handling for non-existent tasks  
✅ CORS enabled for frontend communication  
✅ Admin panel integration  
✅ Comprehensive test suite  
✅ Docker support for easy deployment  
✅ RESTful API design following best practices  

## Future Enhancements

Potential improvements for production:
- User authentication and authorization
- Task ownership (user-specific tasks)
- Task categories/tags
- Due dates and priorities
- Task comments/notes
- File attachments
- Rate limiting
- API versioning
- Swagger/OpenAPI documentation
- PostgreSQL database for production
- Redis caching
- Celery for background tasks

## License

This project is open source and available for educational purposes.

