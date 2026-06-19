"""
Admin configuration for User and CitizenProfile.
"""
from django.contrib import admin
from unfold.admin import ModelAdmin, StackedInline
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User, CitizenProfile


class CitizenProfileInline(StackedInline):
    model = CitizenProfile
    can_delete = False
    verbose_name = 'Profil citoyen'
    verbose_name_plural = 'Profil citoyen'


@admin.register(User)
class UserAdmin(BaseUserAdmin, ModelAdmin):
    model = User
    list_display = ('email', 'first_name', 'last_name', 'role', 'commune', 'is_verified', 'is_active')
    list_filter = ('role', 'is_verified', 'is_active', 'commune')
    search_fields = ('email', 'first_name', 'last_name', 'phone')
    ordering = ('-created_at',)
    inlines = [CitizenProfileInline]

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Informations personnelles', {'fields': ('first_name', 'last_name', 'phone')}),
        ('Rôle & Commune', {'fields': ('role', 'commune', 'is_verified')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Dates', {'fields': ('last_login',)}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'last_name', 'phone', 'role', 'password1', 'password2'),
        }),
    )


@admin.register(CitizenProfile)
class CitizenProfileAdmin(ModelAdmin):
    list_display = ('user', 'cni_number', 'gender', 'date_of_birth')
    search_fields = ('user__email', 'user__first_name', 'user__last_name', 'cni_number')
    list_filter = ('gender',)
