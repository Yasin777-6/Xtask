# 🚀 Xtask - Full-Stack Task Management Application

A beautiful, modern full-stack task management application built with Django REST Framework and React.

![Backend](https://img.shields.io/badge/Django-4.2-green) ![DRF](https://img.shields.io/badge/DRF-3.14-red) ![React](https://img.shields.io/badge/React-18.2-blue) ![Vite](https://img.shields.io/badge/Vite-5.0-646CFF)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Development](#development)
- [Docker Deployment](#docker-deployment)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)

## 🎯 Overview

Xtask is a production-ready task management application featuring:

- **Backend**: Django REST Framework API with SQLite database
- **Frontend**: Modern React application with stunning animations
- **Design**: Beautiful UI with dark mode support
- **Features**: Full CRUD operations, filtering, real-time updates

## ✨ Features

### Backend Features
- ✅ RESTful API with Django REST Framework
- ✅ Task CRUD operations
- ✅ Input validation and error handling
- ✅ Filtering by completion status
- ✅ Search functionality
- ✅ CORS enabled for frontend
- ✅ Admin panel integration
- ✅ Comprehensive test suite

### Frontend Features
- 🎨 **Stunning Design** - Modern UI with glassmorphism effects
- 🌓 **Dark Mode** - Beautiful dark theme with smooth transitions
- 🎬 **Smooth Animations** - Framer Motion powered interactions
- 📱 **Fully Responsive** - Perfect on all devices
- 🎊 **Celebration Effects** - Confetti when completing tasks
- ⚡ **Real-time Updates** - Instant UI feedback
- 🔔 **Toast Notifications** - Friendly user feedback
- 💫 **Loading States** - Beautiful skeleton loaders

## 🛠️ Tech Stack

### Backend
- **Django** 4.2 - Web framework
- **Django REST Framework** 3.14 - API framework
- **django-cors-headers** 4.3 - CORS handling
- **SQLite** - Database

### Frontend
- **React** 18.2 - UI library
- **Vite** 5.0 - Build tool
- **Tailwind CSS** 3.3 - Styling
- **Framer Motion** 10.16 - Animations
- **Axios** 1.6 - HTTP client
- **Lucide React** - Icons
- **React Hot Toast** - Notifications
- **Canvas Confetti** - Celebrations

## 🚀 Quick Start

### Prerequisites

- **Python** 3.8+
- **Node.js** 18+
- **npm/yarn/pnpm**

### Backend Setup

```bash
# Navigate to project root
cd xtask

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Start server
python manage.py runserver
```

Backend will be available at `http://localhost:8000`

### Frontend Setup

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Create .env file
echo "VITE_API_URL=http://localhost:8000/api" > .env

# Start development server
npm run dev
```

Frontend will be available at `http://localhost:5173`

## 📁 Project Structure

```
xtask/
├── backend/                    # Django backend
│   ├── manage.py
│   ├── requirements.txt
│   ├── xtask/                 # Project settings
│   │   ├── settings.py
│   │   ├── urls.py
│   │   └── wsgi.py
│   └── tasks/                 # Tasks app
│       ├── models.py
│       ├── serializers.py
│       ├── views.py
│       ├── urls.py
│       ├── admin.py
│       └── tests.py
│
├── frontend/                   # React frontend
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── hooks/             # Custom hooks
│   │   ├── services/          # API services
│   │   └── App.jsx
│   ├── package.json
│   ├── vite.config.js
│   └── tailwind.config.js
│
├── docker-compose.yml          # Docker Compose configs
├── Dockerfile                  # Backend Dockerfile
└── README.md                   # This file
```

## 💻 Development

### Running Both Services

**Terminal 1 - Backend:**
```bash
cd xtask
python manage.py runserver
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

### Running Tests

**Backend Tests:**
```bash
python manage.py test
```

**Frontend Tests:**
```bash
cd frontend
npm test
```

## 🐳 Docker Deployment

### Development Mode

```bash
# Start both backend and frontend in development mode
docker-compose -f docker-compose.dev.yml up --build
```

### Production Mode

```bash
# Build and start production containers
docker-compose -f docker-compose.fullstack.yml up --build
```

### Services

- **Backend**: `http://localhost:8000`
- **Frontend**: `http://localhost:80` (production) or `http://localhost:5173` (dev)

## 📚 API Documentation

### Base URL
```
http://localhost:8000/api
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/tasks/` | Get all tasks |
| POST | `/tasks/` | Create new task |
| GET | `/tasks/{id}/` | Get single task |
| PATCH | `/tasks/{id}/` | Update task |
| DELETE | `/tasks/{id}/` | Delete task |

### Query Parameters

- `completed` - Filter by completion status (`true`/`false`)
- `search` - Search in title and description
- `ordering` - Order by field (`created_at`, `title`, etc.)

### Example Requests

**Create Task:**
```bash
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title": "New Task", "description": "Task description"}'
```

**Get All Tasks:**
```bash
curl http://localhost:8000/api/tasks/
```

**Filter Completed Tasks:**
```bash
curl "http://localhost:8000/api/tasks/?completed=true"
```

For detailed API documentation, see [Backend README](README.md).

## 🎨 Design Philosophy

### Backend
- **RESTful Principles** - Clean, predictable API design
- **DRY Code** - ModelViewSet for efficient CRUD
- **Validation** - Comprehensive input validation
- **Error Handling** - Graceful error responses

### Frontend
- **Component-Based** - Reusable, modular components
- **Custom Hooks** - Separated business logic
- **Service Layer** - Abstracted API calls
- **Accessibility** - ARIA labels and keyboard navigation

## 🔒 Security Considerations

### Backend
- CORS configured for specific origins
- Input validation on all endpoints
- SQL injection protection (Django ORM)
- XSS protection (Django templates)

### Frontend
- Environment variables for API URL
- Input sanitization
- XSS protection (React)
- HTTPS in production

## 🚀 Deployment

### Backend Deployment

1. Set `DEBUG = False` in settings
2. Configure `ALLOWED_HOSTS`
3. Use PostgreSQL for production
4. Set up static file serving
5. Use environment variables for secrets

### Frontend Deployment

1. Build production bundle: `npm run build`
2. Serve with nginx or similar
3. Configure API URL in environment
4. Enable HTTPS
5. Set up CDN for static assets

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is open source and available for educational purposes.

## 🙏 Acknowledgments

- Design inspiration from Notion, Linear, and Todoist
- Icons from [Lucide](https://lucide.dev)
- Fonts from [Google Fonts](https://fonts.google.com)

## 📞 Support

For issues or questions:
- Backend: See [Backend README](README.md)
- Frontend: See [Frontend README](frontend/README.md)
- Open an issue on GitHub

---

**Made with ❤️ and lots of ☕**

