"""
Test settings for TrashTrails
Used in CI/CD pipelines and automated checks
"""

import os
from .base import *

# Load test env if present (optional)
load_dotenv(os.path.join(BASE_DIR, 'dev.env'))

# Security
SECRET_KEY = "github-actions-test-secret"
DEBUG = False
ALLOWED_HOSTS = ["localhost", "127.0.0.1"]

# Use fast local DB
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "test_db.sqlite3",
    }
}

# Disable external services
AWS_ACCESS_KEY_ID = ""
AWS_SECRET_ACCESS_KEY = ""
AWS_STORAGE_BUCKET_NAME = ""
AWS_S3_ENDPOINT_URL = ""

# Local storage only
STORAGES = {
    "staticfiles": {
        "BACKEND": "django.core.files.storage.StaticFilesStorage",
    },
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
        "LOCATION": os.path.join(BASE_DIR, "media"),
    },
}

# JWT — shorter lifetimes for tests
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=5),
    "REFRESH_TOKEN_LIFETIME": timedelta(minutes=30),
}

# Swagger off in CI
SWAGGER_ENABLED = False

# Email backend (no external calls)
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
