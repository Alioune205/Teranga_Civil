import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from django.db import connection

try:
    with connection.cursor() as cursor:
        cursor.execute("DROP TABLE IF EXISTS ai_ndiogoyechatlog CASCADE;")
        cursor.execute("DELETE FROM django_migrations WHERE app='ai';")
    print("Database fixed successfully.")
except Exception as e:
    print("Error:", e)
