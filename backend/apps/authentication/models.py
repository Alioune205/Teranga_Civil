import uuid
from django.db import models
from django.utils import timezone

class OTPToken(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(verbose_name="Adresse email")
    otp_hash = models.CharField(max_length=64, verbose_name="Hash du code OTP")
    salt = models.CharField(max_length=32, verbose_name="Sel")
    expires_at = models.DateTimeField(verbose_name="Date d'expiration")
    is_used = models.BooleanField(default=False, verbose_name="Est utilisé")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Date de création")

    class Meta:
        db_table = 'otp_tokens'
        ordering = ['-created_at']

    def __str__(self):
        return f"OTPToken pour {self.email} (Exp: {self.expires_at})"

    @property
    def is_valid(self):
        return not self.is_used and timezone.now() <= self.expires_at
