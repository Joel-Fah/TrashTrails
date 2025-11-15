# TrashTrails Backend

A Django 5 backend that powers TrashTrails. This guide is scoped to the backend folder only and walks new contributors through installing dependencies, wiring environment variables, running the dev server, compiling Tailwind assets, testing, and preparing for production deploys.

---

## Contents
- [Stack Overview](#stack-overview)
- [Prerequisites](#prerequisites)
- [Project Layout](#project-layout)
- [Environment Variables](#environment-variables)
- [Quick Start (Local Development)](#quick-start-local-development)
- [Asset Pipeline (Tailwind)](#asset-pipeline-tailwind)
- [Useful Management Commands](#useful-management-commands)
- [Testing & Quality Checks](#testing--quality-checks)
- [Production / Deployment Notes](#production--deployment-notes)
- [Troubleshooting](#troubleshooting)

---

## Stack Overview
- **Language:** Python 3.13+
- **Framework:** Django 5.2 with ASGI-ready `backend` project and `core` app
- **Styling:** `django-tailwind` + custom `theme` app (Tailwind CLI)
- **Storage:** SQLite for dev, PostgreSQL (Supabase) + S3-compatible storage for prod
- **Static files:** WhiteNoise locally, `django-storages` + Supabase S3 in prod

## Prerequisites
1. **Python** 3.13 (matches `.pyc` artifacts) and `pip`
2. **Virtual environment tool** (`python -m venv` recommended)
3. **Node.js** 18+ and `npm` (required for Tailwind builds)
4. **Git**
5. **PostgreSQL** (or Supabase) only if you want to mirror production locally

Optional but useful: `direnv` or similar for auto-loading the `.env` files.

## Project Layout
```
backend/           Django project (settings, URLs, ASGI/WSGI)
core/              Main app for business logic, models, views
manage.py          Django management entry point
requirements.txt   Python dependencies
static/, templates/Shared assets/templates used by Django
theme/             Tailwind-powered Django app (see `static_src/` for npm project)
```

## Environment Variables
Two env files are tracked:
- `dev.env` – minimal settings for local work (defaults to SQLite + debug).
- `prod.env.example` – template for production secrets. Copy to `prod.env` and fill in before deploying.

Load `dev.env` before running commands (see Quick Start) so `DJANGO_SETTINGS_MODULE=backend.settings.development` is set. For IDEs, configure the same variable in run configurations.

Key variables you may need beyond the defaults:
- `SECRET_KEY` – only required if you override the development constant.
- `SUPABASE_POSTGRESQL_URL` – PostgreSQL DSN for staging/prod.
- `SUPABASE_S3_*` keys – S3-compatible bucket credentials for static/media in prod.
- `ALLOWED_HOSTS`, `SITE_URL`, `CSRF_TRUSTED_ORIGINS` – network hardening for prod.

## Quick Start (Local Development)
1. **Clone & enter backend folder**
   ```powershell
   git clone <repo-url>
   cd TrashTrails\src\backend
   ```
2. **Create and activate a virtualenv**
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\activate
   ```
3. **Install Python dependencies**
   ```powershell
   pip install --upgrade pip
   pip install -r requirements.txt
   ```
4. **Load development env vars** (PowerShell example)
   ```powershell
   set-content -Path .env.local -Value (Get-Content dev.env)
   Get-Content dev.env | foreach { $name,$value = $_ -split '='; setx $name ($value.Trim("'")) }  # optional helper
   ```
   Or simply export `DJANGO_SETTINGS_MODULE=backend.settings.development` in your shell.
5. **Run migrations & create a superuser**
   ```powershell
   python manage.py migrate
   python manage.py createsuperuser
   ```
6. **Install Tailwind dependencies** (one-time)
   ```powershell
   cd theme\static_src
   npm install
   cd ..\..
   ```
7. **Start the dev processes** (two terminals recommended)
   - Terminal A – Django API:
     ```powershell
     python manage.py runserver
     ```
   - Terminal B – Tailwind watcher:
     ```powershell
     python manage.py tailwind start
     ```
   Visit <http://127.0.0.1:8000> and log into `/admin/` with your superuser credentials.

## Asset Pipeline (Tailwind)
- **Development watch:** `python manage.py tailwind start` wraps the npm dev script and outputs to `theme/static/css/dist/`.
- **Manual npm fallback:**
  ```powershell
  cd theme\static_src
  npm run dev
  ```
- **Production build:**
  ```powershell
  npm --prefix theme\static_src run build
  ```
  This minifies CSS and writes to `theme/static/css/dist/styles.css` before `collectstatic` runs.

## Useful Management Commands
| Command | Purpose |
| --- | --- |
| `python manage.py runserver` | Start Django dev server (uses `dev.env`). |
| `python manage.py tailwind start` | Watch Tailwind assets via django-tailwind. |
| `python manage.py migrate` | Apply database migrations. |
| `python manage.py createsuperuser` | Create admin credentials. |
| `python manage.py shell_plus` (if django-extensions added) | Enhanced shell. |
| `python manage.py collectstatic` | Gather static assets (run before deploying). |
| `python manage.py check --deploy` | Run Django deployment checklist. |

## Testing & Quality Checks
Run unit tests and system checks before opening a pull request:
```powershell
python manage.py test
python manage.py check
```
If you touch Tailwind/JS, also run:
```powershell
npm --prefix theme\static_src run build
```

## Production / Deployment Notes
1. **Set `DJANGO_SETTINGS_MODULE=backend.settings.production`.**
2. **Provide all secrets** from `prod.env.example` (database URL, Supabase bucket keys, allowed hosts, etc.).
3. **Install dependencies & run migrations** on the server just like locally.
4. **Build Tailwind CSS** (`npm --prefix theme/static_src run build`).
5. **Collect static files** so WhiteNoise/S3 can serve them:
   ```powershell
   python manage.py collectstatic --noinput
   ```
6. **Use a production-grade server** such as `gunicorn` (already in requirements) behind nginx/uvicorn workers. Example:
   ```powershell
   gunicorn backend.wsgi --bind 0.0.0.0:8000 --workers 3
   ```

## Troubleshooting
- **`DJANGO_SETTINGS_MODULE` errors:** Ensure `dev.env` is loaded or export the variable manually.
- **Static files missing:** Run the Tailwind watcher or `npm --prefix theme/static_src run build`, then rerun `collectstatic`.
- **Database lock / mismatch:** Delete `db.sqlite3` for a clean slate (dev only) and re-run migrations.
- **Import errors for `django-tailwind`:** Reinstall requirements and confirm Node deps are installed inside `theme/static_src`.

Need more? Reach out in the #backend channel with logs and steps you’ve tried.
