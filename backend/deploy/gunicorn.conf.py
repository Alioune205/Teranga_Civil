import multiprocessing
import os

# Socket / Port
bind = "127.0.0.1:8000"

# Workers
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"
timeout = 120

# Logs
accesslog = "/var/log/gunicorn/teranga_civil_access.log"
errorlog = "/var/log/gunicorn/teranga_civil_error.log"
loglevel = "info"

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")
