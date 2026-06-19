import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer

logger = logging.getLogger('system')

class DashboardConsumer(AsyncWebsocketConsumer):
    """
    WebSocket Consumer pour le Dashboard (DEV 2A).
    Permet de mettre à jour en temps réel les statistiques et les tableaux 
    de bord sans rafraîchir la page.
    """
    
    async def connect(self):
        self.group_name = 'dashboard_updates'

        # Join the dashboard group
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()
        logger.info(f"WebSocket: Dashboard client connected: {self.channel_name}")

    async def disconnect(self, close_code):
        # Leave the dashboard group
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )
        logger.info(f"WebSocket: Dashboard client disconnected: {self.channel_name}")

    async def receive(self, text_data=None, bytes_data=None):
        """
        Peut être utilisé si le Dashboard envoie des événements au serveur,
        par exemple pour changer les filtres en direct.
        """
        pass

    async def dashboard_update(self, event):
        """
        Gère les messages envoyés au groupe 'dashboard_updates'.
        """
        message = event.get('message', {})
        update_type = event.get('update_type', 'general')

        await self.send(text_data=json.dumps({
            'type': update_type,
            'payload': message
        }))


class MobileConsumer(AsyncWebsocketConsumer):
    """
    WebSocket Consumer pour l'App Mobile Flutter (DEV 3/4).
    Notifie le citoyen en direct des changements de statut de ses dossiers.
    """
    
    async def connect(self):
        # We assume the user ID is passed in the query string or URL route
        # In a real app, we'd extract it from the authenticated scope (e.g. self.scope["user"])
        self.user_id = self.scope['url_route']['kwargs'].get('user_id', 'anonymous')
        self.group_name = f'user_{self.user_id}'

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()
        logger.info(f"WebSocket: Mobile client connected for user {self.user_id}")

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    async def notification_push(self, event):
        """
        Gère les messages envoyés au citoyen spécifiquement.
        """
        notification = event.get('notification', {})
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'payload': notification
        }))
