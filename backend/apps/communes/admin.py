"""
Admin configuration for Commune.
"""
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Commune, Mairie


@admin.register(Commune)
class CommuneAdmin(ModelAdmin):
    list_display = ('name', 'region', 'department', 'code', 'is_active')
    list_filter = ('region', 'department', 'is_active')
    search_fields = ('name', 'region', 'department', 'code')
    ordering = ('name',)

@admin.register(Mairie)
class MairieAdmin(ModelAdmin):
    list_display = ('nom', 'commune', 'latitude', 'longitude', 'est_active')
    list_filter = ('commune__region', 'commune', 'est_active')
    search_fields = ('nom', 'commune__name')
    list_editable = ('est_active',)
