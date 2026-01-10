# Local development settings for TrashTrails
import dj_database_url
from dotenv import load_dotenv
from datetime import timedelta

from .base import *

# Load prod env file
load_dotenv(
    os.path.join(BASE_DIR, '.env')
)

# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-g=lrpqm8*=@r+l!15j=04uq6t#rzb-n)skno#lfni$u+vgj9xj'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['*']

# Application definition
INSTALLED_APPS += ['django_browser_reload']

# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    },
    # 'supabase': dj_database_url.parse(os.getenv('SUPABASE_POSTGRESQL_URL')),
}

# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/

STATIC_URL = 'theme/static/'
MEDIA_URL = '/media/'

MEDIA_ROOT = os.path.join(BASE_DIR / 'media/')

# Whitenoise settings
STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
        "LOCATION": MEDIA_ROOT,
    },
}

LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/'


SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
}

SWAGGER_ENABLED = True