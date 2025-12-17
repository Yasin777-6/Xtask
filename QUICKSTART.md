# 🚀 Quick Start Guide

Get Xtask up and running in 5 minutes!

## Option 1: Local Development (Recommended for Development)

### Step 1: Backend Setup

```bash
# Navigate to project root
cd xtask

# Create and activate virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# OR
source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start backend server
python manage.py runserver
```

✅ Backend running at `http://localhost:8000`

### Step 2: Frontend Setup

```bash
# Open new terminal, navigate to frontend
cd frontend

# Install dependencies
npm install

# Create .env file
echo "VITE_API_URL=http://localhost:8000/api" > .env

# Start frontend server
npm run dev
```

✅ Frontend running at `http://localhost:5173`

**That's it!** Open `http://localhost:5173` in your browser.

---

## Option 2: Docker (Recommended for Production)

### Development Mode

```bash
# Start both services
docker-compose -f docker-compose.dev.yml up --build
```

- Backend: `http://localhost:8000`
- Frontend: `http://localhost:5173`

### Production Mode

```bash
# Start production build
docker-compose -f docker-compose.fullstack.yml up --build
```

- Backend: `http://localhost:8000`
- Frontend: `http://localhost:80`

---

## Option 3: Backend Only (API Testing)

```bash
# Follow Step 1 from Option 1
# Then test API:

# Get all tasks
curl http://localhost:8000/api/tasks/

# Create task
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Task", "description": "My first task"}'
```

---

## Troubleshooting

### Backend Issues

**Port 8000 already in use:**
```bash
python manage.py runserver 8001
```

**Migration errors:**
```bash
python manage.py makemigrations
python manage.py migrate
```

### Frontend Issues

**Port 5173 already in use:**
- Vite will automatically use the next available port

**API connection errors:**
- Check `.env` file has correct API URL
- Ensure backend is running
- Check CORS settings in `xtask/settings.py`

### Docker Issues

**Port conflicts:**
- Change ports in `docker-compose.yml`

**Build errors:**
```bash
docker-compose down
docker-compose up --build --force-recreate
```

---

## Next Steps

1. ✅ Create your first task
2. ✅ Toggle dark mode (top-right)
3. ✅ Filter tasks (All/Active/Completed)
4. ✅ Complete a task (see confetti! 🎊)
5. ✅ Explore the beautiful animations

---

## Need Help?

- Backend docs: See `README.md`
- Frontend docs: See `frontend/README.md`
- Full docs: See `README.PROJECT.md`

Happy coding! 🎉

