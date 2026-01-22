# Local development settings for TrashTrails
import dj_database_url

from .base import *

# Load prod env file
load_dotenv(
    os.path.join(BASE_DIR, 'prod.env')
)

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('SECRET_KEY')

DEBUG = os.getenv("DEBUG", False) == 'True'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS').split(" ") if os.getenv('ALLOWED_HOSTS') else []

# Database
# https://docs.djangoproject.com/en/5.0/ref/settings/#databases

DATABASES = {
    'default': dj_database_url.parse(os.getenv('SUPABASE_POSTGRESQL_URL')),
}


SITE_URL = os.getenv('SITE_URL')
SITE_NAME = os.getenv('SITE_NAME', 'TrashTrails')
DEFAULT_META_DESCRIPTION = os.getenv('DEFAULT_META_DESCRIPTION', "Track and reduce your carbon footprint with TrashTrails.")

CSRF_TRUSTED_ORIGINS = os.getenv('CSRF_TRUSTED_ORIGINS').split(" ")

# Storage settings
# Configure your storage settings for production
AWS_ACCESS_KEY_ID = os.environ.get("SUPABASE_S3_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("SUPABASE_S3_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME = os.environ.get("SUPABASE_S3_BUCKET_NAME")
AWS_S3_REGION_NAME = os.environ.get("SUPABASE_S3_REGION_NAME")
AWS_S3_ENDPOINT_URL = os.environ.get("SUPABASE_S3_ENDPOINT_URL")
AWS_S3_SIGNATURE_VERSION = "s3v4"
AWS_S3_ADDRESSING_STYLE = "path"
AWS_QUERYSTRING_AUTH = False

STORAGES = {
    "staticfiles": {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
        "OPTIONS": {
            "access_key": AWS_ACCESS_KEY_ID,
            "secret_key": AWS_SECRET_ACCESS_KEY,
            "bucket_name": AWS_STORAGE_BUCKET_NAME,
            "region_name": AWS_S3_REGION_NAME,
            "endpoint_url": AWS_S3_ENDPOINT_URL,
            "location": "static",
        },
    },
    "default": {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "access_key": AWS_ACCESS_KEY_ID,
            "secret_key": AWS_SECRET_ACCESS_KEY,
            "bucket_name": AWS_STORAGE_BUCKET_NAME,
            "region_name": AWS_S3_REGION_NAME,
            "endpoint_url": AWS_S3_ENDPOINT_URL,
            "location": "media",
        },
    },
}

# Static and Media files
# Configure your static and media files for production

SWAGGER_ENABLED = True
STATIC_URL = '/static/'
MEDIA_URL = '/media/'
