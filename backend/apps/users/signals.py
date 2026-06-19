"""
Signals for the Users app.
Auto-creates a CitizenProfile when a citizen user is created.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import User, CitizenProfile


@receiver(post_save, sender=User)
def create_user_profiles(sender, instance, created, **kwargs):
    """
    Automatically create a CitizenProfile when a new citizen user is created,
    or a ProfilAgent when an agent user is created.
    """
    if created:
        if instance.role == User.Role.CITIZEN:
            CitizenProfile.objects.get_or_create(user=instance)
        elif instance.role == 'agent':
            try:
                from apps.etat_civil.models_attribution import ProfilAgent
                ProfilAgent.objects.get_or_create(user=instance)
            except ImportError:
                pass
