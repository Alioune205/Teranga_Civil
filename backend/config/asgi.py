"""
ASGI config for TERANGA CIVIL project.
"""
import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')

# Initialize Django ASGI application early to ensure AppRegistry
# is populated before importing code that may import ORM models.
django_asgi_app = get_asgi_application()

from apps.dashboard.routing import websocket_urlpatterns as dashboard_patterns
from apps.notifications.routing import websocket_urlpatterns as notification_patterns

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(
            dashboard_patterns + notification_patterns
        )
    ),
})
