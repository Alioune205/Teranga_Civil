"""
Serializers for Document.
"""
from rest_framework import serializers
from .models import Document


class DocumentSerializer(serializers.ModelSerializer):
    """Full serializer for Document."""
    uploaded_by_name = serializers.CharField(source='uploaded_by.full_name', read_only=True)
    dossier_reference = serializers.CharField(source='dossier.reference', read_only=True)

    class Meta:
        model = Document
        fields = [
            'id',
            'dossier',
            'dossier_reference',
            'file',
            'original_filename',
            'file_type',
            'file_size',
            'mime_type',
            'sha256_hash',
            'description',
            'uploaded_by',
            'uploaded_by_name',
            'ocr_status',
            'ocr_text',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id', 'original_filename', 'file_type', 'file_size',
            'mime_type', 'sha256_hash',
            'uploaded_by', 'uploaded_by_name', 'dossier_reference',
            'ocr_status', 'ocr_text', 'created_at', 'updated_at',
        ]


class DocumentUploadSerializer(serializers.ModelSerializer):
    """Serializer for uploading a document."""

    class Meta:
        model = Document
        fields = ['dossier', 'file', 'description']

    def create(self, validated_data):
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)


class DocumentListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for document lists."""
    uploaded_by_name = serializers.CharField(source='uploaded_by.full_name', read_only=True)

    class Meta:
        model = Document
        fields = [
            'id',
            'dossier',
            'original_filename',
            'file_type',
            'file_size',
            'description',
            'uploaded_by_name',
            'ocr_status',
            'created_at',
        ]
        read_only_fields = fields
