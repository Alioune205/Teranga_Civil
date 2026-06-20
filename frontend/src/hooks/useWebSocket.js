import { useState, useEffect, useRef } from 'react';

export const useWebSocket = () => {
    const [isConnected, setIsConnected] = useState(false);
    const [lastMessage, setLastMessage] = useState(null);
    const ws = useRef(null);

    useEffect(() => {
        let reconnectInterval = null;

        const connect = () => {
            // L'URL WS dépend de l'environnement, ici configuré pour Django Channels local
            const token = localStorage.getItem('access_token');
            const baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
            const baseWsUrl = baseUrl.replace('http', 'ws').replace('/api', '');
            const wsUrl = `${baseWsUrl}/ws/notifications/?token=${token}`;
            
            ws.current = new WebSocket(wsUrl);

            ws.current.onopen = () => {
                setIsConnected(true);
                if (reconnectInterval) clearInterval(reconnectInterval);
            };

            ws.current.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    setLastMessage(data);
                } catch (e) {
                    console.error("Erreur parsing WS", e);
                }
            };

            ws.current.onclose = () => {
                setIsConnected(false);
                // Reconnexion automatique après 5 secondes
                reconnectInterval = setTimeout(connect, 5000);
            };

            ws.current.onerror = (error) => {
                console.error("WebSocket Error: ", error);
                ws.current.close();
            };
        };

        connect();

        return () => {
            if (ws.current) {
                ws.current.close();
            }
            if (reconnectInterval) {
                clearInterval(reconnectInterval);
            }
        };
    }, []);

    return { isConnected, lastMessage };
};
