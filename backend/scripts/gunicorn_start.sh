#!/bin/bash
# Startup script for Gunicorn (WSGI) and Daphne (ASGI/WebSockets)

# Variables
NAME="teranga_civil_backend"
DIR="/var/www/Teranga-Civil-1/backend"
USER="www-data"
GROUP="www-data"
WORKERS=3
BIND_WSGI="unix:/run/gunicorn.sock"
BIND_ASGI="unix:/run/daphne.sock"
DJANGO_SETTINGS_MODULE="config.settings.production"
DJANGO_WSGI_MODULE="config.wsgi"
DJANGO_ASGI_MODULE="config.asgi:application"

echo "Starting $NAME as `whoami`"

# Activate the virtual environment
cd $DIR
source ../venv/bin/activate
export DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE
export PYTHONPATH=$DIR:$PYTHONPATH

# Start Daphne (WebSockets) in background
exec daphne -u $BIND_ASGI --access-log - --proxy-headers $DJANGO_ASGI_MODULE &

# Start Gunicorn (HTTP REST API)
exec gunicorn ${DJANGO_WSGI_MODULE}:application \
  --name $NAME \
  --workers $WORKERS \
  --user=$USER --group=$GROUP \
  --bind=$BIND_WSGI \
  --log-level=info \
  --log-file=-
