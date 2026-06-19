"""
TERANGA CIVIL — Base Settings
Common settings shared across all environments.
"""
import os
from pathlib import Path
from datetime import timedelta

from decouple import config, Csv
from django.urls import reverse_lazy

# ==============================================================================
# PATHS
# ==============================================================================

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# ==============================================================================
# CORE SETTINGS
# ==============================================================================

SECRET_KEY = config(
    'SECRET_KEY',
    default='django-insecure-dev-key-change-in-production'
)

GROQ_API_KEY = config(
    'GROQ_API_KEY',
    default=''
)

GEMINI_API_KEY = config(
    'GEMINI_API_KEY',
    default=''
)

import os
from dotenv import load_dotenv

# Charge les variables depuis le fichier .env (si existant)
load_dotenv()

GOOGLE_MAPS_API_KEY = os.environ.get('GOOGLE_MAPS_API_KEY')
if not GOOGLE_MAPS_API_KEY:
    # Pour ne pas crasher les builds ou migrations si la clé manque
    print("WARNING: GOOGLE_MAPS_API_KEY manquante dans .env")

ALLOWED_HOSTS = config(
    'ALLOWED_HOSTS',
    default='localhost,127.0.0.1',
    cast=Csv()
)

# CORS Configuration pour débloquer le Frontend (DEV 2A et 2B)
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

from corsheaders.defaults import default_headers
CORS_ALLOW_HEADERS = list(default_headers) + [
    'x-app-version',
    'x-platform',
    'x-device-id',
]

# Custom User Model
AUTH_USER_MODEL = 'users.User'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ==============================================================================
# APPLICATIONS
# ==============================================================================

DJANGO_APPS = [
    'daphne',
    'unfold',
    'unfold.contrib.filters',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'drf_spectacular',
    'django_filters',
    'corsheaders',
    'channels',
]

LOCAL_APPS = [
    'apps.shared',
    'apps.users',
    'apps.authentication',
    'apps.roles',
    'apps.communes',
    'apps.dossiers',
    'apps.documents',
    'apps.audit_logs',
    'apps.notifications',
    'apps.qr',
    'apps.ai',
    'apps.dashboard',
    'apps.system',
    'apps.integrations',
    'apps.services',
    'apps.payments',
    'apps.etat_civil',
    'apps.appointments',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# ==============================================================================
# MIDDLEWARE
# ==============================================================================

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'apps.audit_logs.middleware.AuditLogMiddleware',
    'apps.payments.middleware.ReadOnlyForSuperAdminMiddleware',
    'apps.system.middleware.PerformanceMonitoringMiddleware',
]

# ==============================================================================
# CELERY CONFIGURATION
# ==============================================================================
CELERY_BROKER_URL = config('CELERY_BROKER_URL', default='redis://localhost:6379/1')
CELERY_RESULT_BACKEND = config('CELERY_RESULT_BACKEND', default='redis://localhost:6379/1')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'

# Configuration Celery Beat (Tâches périodiques)
CELERY_BEAT_SCHEDULE = {
    'verifier-sla-chaque-15-min': {
        'task': 'apps.etat_civil.tasks_attribution.task_verifier_sla_et_escalader',
        'schedule': 900.0,  # 15 minutes
    },
    'recalculer-scores-nuit': {
        'task': 'apps.etat_civil.tasks_attribution.task_recalculer_scores_agents',
        'schedule': 86400.0,  # Chaque jour
    },
}

# ==============================================================================
# URL CONFIGURATION
# ==============================================================================

ROOT_URLCONF = 'config.urls'

# ==============================================================================
# TEMPLATES
# ==============================================================================

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# ==============================================================================
# WSGI / ASGI
# ==============================================================================

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

# ==============================================================================
# CACHING (Redis)
# ==============================================================================

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': config('REDIS_URL', default='redis://127.0.0.1:6379/1'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# ==============================================================================
# CHANNELS (WebSockets)
# ==============================================================================

DEBUG = config('DEBUG', default=False, cast=bool)

if DEBUG or config('USE_IN_MEMORY_CHANNELS', default=False, cast=bool):
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels.layers.InMemoryChannelLayer',
        },
    }
else:
    CHANNEL_LAYERS = {
        'default': {
            'BACKEND': 'channels_redis.core.RedisChannelLayer',
            'CONFIG': {
                'hosts': [(config('REDIS_HOST', default='127.0.0.1'), config('REDIS_PORT', default=6379, cast=int))],
            },
        },
    }

PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.BCryptSHA256PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher',
    'django.contrib.auth.hashers.Argon2PasswordHasher',
]

# ==============================================================================
# PASSWORD VALIDATION
# ==============================================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation'
        '.UserAttributeSimilarityValidator'
    },
    {
        'NAME': 'django.contrib.auth.password_validation'
        '.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8}
    },
    {
        'NAME': 'django.contrib.auth.password_validation'
        '.CommonPasswordValidator'
    },
    {
        'NAME': 'django.contrib.auth.password_validation'
        '.NumericPasswordValidator'
    },
]

# ==============================================================================
# INTERNATIONALIZATION
# ==============================================================================

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Africa/Dakar'
USE_I18N = True
USE_TZ = True

# ==============================================================================
# STATIC & MEDIA FILES
# ==============================================================================

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# ==============================================================================
# DJANGO REST FRAMEWORK
# ==============================================================================

REST_FRAMEWORK = {
    # Authentication
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),

    # Permissions
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),

    # Pagination
    'DEFAULT_PAGINATION_CLASS': (
        'apps.shared.pagination.StandardPagination'
    ),
    'PAGE_SIZE': 20,

    # Filtering
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),

    # Renderers
    'DEFAULT_RENDERER_CLASSES': (
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ),

    # Throttling
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
        'rest_framework.throttling.ScopedRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour',
        'login': '5/minute', # Anti brute-force pour le login
        'otp': '3/minute',   # Anti-spam pour l'envoi d'OTP
        'google_maps_api': '10/minute', # Protection quota API externe
    },

    # Schema
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',

    # Exception handling
    'EXCEPTION_HANDLER': (
        'apps.shared.exceptions.custom_exception_handler'
    ),

    # Date/Time formats
    'DATETIME_FORMAT': '%Y-%m-%dT%H:%M:%S%z',
    'DATE_FORMAT': '%Y-%m-%d',
}

# ==============================================================================
# SIMPLE JWT
# ==============================================================================

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(
        minutes=config(
            'ACCESS_TOKEN_LIFETIME', default=30, cast=int
        )
    ),
    'REFRESH_TOKEN_LIFETIME': timedelta(
        minutes=config(
            'REFRESH_TOKEN_LIFETIME', default=1440, cast=int
        )
    ),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,

    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,

    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',

    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',

    'TOKEN_OBTAIN_SERIALIZER': (
        'apps.authentication.serializers'
        '.CustomTokenObtainPairSerializer'
    ),
}

# ==============================================================================
# DRF SPECTACULAR (Swagger / OpenAPI)
# ==============================================================================

SPECTACULAR_SETTINGS = {
    'TITLE': 'TERANGA CIVIL API',
    'DESCRIPTION': (
        'API backend pour la plateforme GovTech TERANGA CIVIL — '
        "Digitalisation des démarches administratives et d'état "
        'civil pour les collectivités territoriales du Sénégal.'
    ),
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'SCHEMA_PATH_PREFIX': '/api/',
    'COMPONENT_SPLIT_REQUEST': True,
    'TAGS': [
        {'name': 'Auth', 'description': 'Authentification JWT'},
        {'name': 'Users', 'description': 'Gestion des utilisateurs'},
        {'name': 'Profiles', 'description': 'Profils citoyens'},
        {'name': 'Roles', 'description': 'Gestion des rôles RBAC'},
        {'name': 'Communes', 'description': 'Collectivités territoriales'},
        {'name': 'Dossiers', 'description': 'Demandes administratives'},
        {'name': 'Documents', 'description': 'Pièces jointes et documents'},
        {'name': 'Audit Logs', 'description': 'Traçabilité des actions'},
        {'name': 'Dashboard', 'description': 'Statistiques et KPIs'},
        {'name': 'Notifications', 'description': 'Notifications'},
    ],
}

# ==============================================================================
# FILE UPLOAD SETTINGS
# ==============================================================================

FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10 MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10 MB

# Allowed file types for document uploads
ALLOWED_DOCUMENT_TYPES = ['pdf', 'jpg', 'jpeg', 'png']
MAX_DOCUMENT_SIZE = 10 * 1024 * 1024  # 10 MB

# ==============================================================================
# LOGGING
# ==============================================================================

LOGS_DIR = BASE_DIR / 'logs'
os.makedirs(LOGS_DIR, exist_ok=True)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': (
                '{levelname} {asctime} {module} '
                '{process:d} {thread:d} {message}'
            ),
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
        'system_file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': LOGS_DIR / 'system.log',
            'maxBytes': 1024 * 1024 * 5,  # 5 MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
        'error_file': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': LOGS_DIR / 'errors.log',
            'maxBytes': 1024 * 1024 * 5,  # 5 MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'system_file', 'error_file'],
            'level': 'INFO',
            'propagate': True,
        },
        'system': {
            'handlers': ['console', 'system_file', 'error_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'apps': {
            'handlers': ['console', 'error_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'errors': {
            'handlers': ['console', 'error_file'],
            'level': 'ERROR',
            'propagate': False,
        },
    },
}

# ==============================================================================
# FIREBASE CONFIGURATION (DEV 1C)
# ==============================================================================

import firebase_admin
from firebase_admin import credentials

FIREBASE_CREDENTIALS_PATH = config(
    'FIREBASE_CREDENTIALS_PATH', default=''
)
if FIREBASE_CREDENTIALS_PATH:
    cred_path = BASE_DIR / FIREBASE_CREDENTIALS_PATH
    if cred_path.exists():
        cred = credentials.Certificate(str(cred_path))
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
    else:
        print(
            f"Warning: Firebase credentials file "
            f"not found at {cred_path}"
        )

# ==============================================================================
# TWILIO & SENDGRID (DEV 2B)
# ==============================================================================

TWILIO_ACCOUNT_SID = config('TWILIO_ACCOUNT_SID', default='')
TWILIO_AUTH_TOKEN = config('TWILIO_AUTH_TOKEN', default='')
TWILIO_PHONE_NUMBER = config('TWILIO_PHONE_NUMBER', default='')

SENDGRID_API_KEY = config('SENDGRID_API_KEY', default='')
SENDGRID_FROM_EMAIL = config('SENDGRID_FROM_EMAIL', default='no-reply@terangacivil.sn')

# ==============================================================================
# UNFOLD (Admin Theme)
# ==============================================================================
UNFOLD = {
    "SITE_TITLE": "Teranga Civil",
    "SITE_HEADER": "Teranga Civil Admin",
    "SITE_SYMBOL": "stars",  # Material icon
    "SHOW_HISTORY": True,
    "SHOW_VIEW_ON_SITE": True,
    "COLORS": {
        "primary": {
            "50": "238 242 255",
            "100": "224 231 255",
            "200": "199 210 254",
            "300": "165 180 252",
            "400": "129 140 248",
            "500": "99 102 241",  # Indigo 500
            "600": "79 70 229",
            "700": "67 56 202",
            "800": "55 48 163",
            "900": "49 46 129",
            "950": "30 27 75",
        },
    },
    "SIDEBAR": {
        "show_search": True,
        "show_all_applications": False,
        "navigation": [
            {
                "title": "Gestion Citoyenne",
                "separator": True,
                "items": [
                    {
                        "title": "Dossiers (Demandes)",
                        "icon": "folder_shared",
                        "link": reverse_lazy("admin:dossiers_dossier_changelist"),
                    },
                    {
                        "title": "Commentaires Dossiers",
                        "icon": "forum",
                        "link": reverse_lazy("admin:dossiers_dossiercomment_changelist"),
                    },
                ],
            },
            {
                "title": "Sécurité & Accès",
                "separator": True,
                "items": [
                    {
                        "title": "Utilisateurs",
                        "icon": "person",
                        "link": reverse_lazy("admin:users_user_changelist"),
                    },
                    {
                        "title": "Groupes & Permissions",
                        "icon": "shield",
                        "link": reverse_lazy("admin:auth_group_changelist"),
                    },
                ],
            },
        ],
    },
}

