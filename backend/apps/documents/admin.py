"""
Admin configuration for Document.
"""
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Document


@admin.register(Document)
class DocumentAdmin(ModelAdmin):
    list_display = ('original_filename', 'dossier', 'file_type', 'file_size', 'uploaded_by', 'ocr_status', 'created_at')
    list_filter = ('file_type', 'ocr_status')
    search_fields = ('original_filename', 'dossier__reference', 'description')
    readonly_fields = ('file_size', 'original_filename', 'created_at', 'updated_at')
    ordering = ('-created_at',)
