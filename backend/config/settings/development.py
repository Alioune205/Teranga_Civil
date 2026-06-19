"""
TERANGA CIVIL — Development Settings
"""
from .base import *  # noqa: F401,F403

# ==============================================================================
# CORE
# ==============================================================================

DEBUG = True

# ==============================================================================
# DATABASE — SQLite fallback for development
# ==============================================================================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Try PostgreSQL if configured
DB_NAME = config('DB_NAME', default='')
if DB_NAME:
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': DB_NAME,
        'USER': config('DB_USER', default='postgres'),
        'PASSWORD': config('DB_PASSWORD', default='postgres'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
        'OPTIONS': {
            'connect_timeout': 5,
        },
    }

# ==============================================================================
# CORS — Permissive in development
# ==============================================================================

CORS_ALLOW_ALL_ORIGINS = True

# ==============================================================================
# EMAIL — Console backend for development
# ==============================================================================

EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# ==============================================================================
# THROTTLING — Relaxed for development
# ==============================================================================

REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {
    'anon': '1000/hour',
    'user': '10000/hour',
    'login': '100/minute', # Relaxed for dev
    'otp': '100/minute',   # Relaxed for dev
    'google_maps_api': '10/minute', # Included for dev
}

# ==============================================================================
# CACHING & WEBSOCKETS (Local Memory for Windows Dev)
# ==============================================================================

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer"
    }
}

# ==============================================================================
# LOGGING
# ==============================================================================

# Ensure logs directory exists
import os
os.makedirs(BASE_DIR / 'logs', exist_ok=True)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': str(BASE_DIR / 'logs' / 'app.log'),
            'formatter': 'verbose',
            'delay': True,
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'apps': {
            'handlers': ['console', 'file'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}

# ==============================================================================
# CELERY (Local Eager Mode to bypass Redis on Windows)
# ==============================================================================
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_STORE_EAGER_RESULT = True

