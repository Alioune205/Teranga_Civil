from django.urls import path

from .views import NdiogoyeChatView, NdiogoyeFeedbackView, AdminAssistantQueryView, OcrExtractView, OcrCameraView, OcrConfirmView

urlpatterns = [
    # Ndiogoye Chat
    path("ndiogoye/chat/", NdiogoyeChatView.as_view(), name="ndiogoye-chat"),
    path("ndiogoye/feedback/", NdiogoyeFeedbackView.as_view(), name="ndiogoye-feedback"),
    path("assistant-query/", AdminAssistantQueryView.as_view(), name="assistant-query"),
    
    # OCR — Upload de fichier (image/PDF)
    path('ocr/extract/', OcrExtractView.as_view(), name='ocr_extract'),
    # OCR — Capture caméra (image base64 depuis le navigateur)
    path('ocr/camera/', OcrCameraView.as_view(), name='ocr_camera'),
    # OCR — Confirmation des données extraites
    path('ocr/confirm/', OcrConfirmView.as_view(), name='ocr_confirm'),
]
