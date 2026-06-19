import uuid

from django.db import models


class NdiogoyeChatLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session_id = models.CharField(max_length=255, db_index=True)
    user_query = models.TextField()
    ndiogoye_response = models.TextField()
    intent = models.CharField(max_length=50, blank=True, null=True)
    confidence_score = models.FloatField(blank=True, null=True)
    rating = models.IntegerField(
        blank=True, null=True, help_text="1 pour positif, -1 pour négatif"
    )
    feedback_comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Session {self.session_id} - {self.created_at}"
