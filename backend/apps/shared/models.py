"""
Shared abstract models for TERANGA CIVIL.
"""
import uuid

from django.db import models


class TimeStampedModel(models.Model):
    """
    Abstract base model providing UUID primary key and timestamp fields.
    All project models should inherit from this.
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        verbose_name='ID',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de création',
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Date de modification',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Actif',
    )

    class Meta:
        abstract = True
        ordering = ['-created_at']
