import json
from channels.generic.websocket import AsyncWebsocketConsumer

class DashboardConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # On abonne l'utilisateur au groupe 'admin_dashboard'
        self.group_name = 'admin_dashboard'
        
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        # Désabonnement lors de la déconnexion
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    # Réception d'un message broadcasté (venant de Django)
    async def dashboard_update(self, event):
        message = event.get('message', '')
        data = event.get('data', {})

        # Transmission du message vers le client (React) via WebSocket
        await self.send(text_data=json.dumps({
            'message': message,
            'data': data
        }))
