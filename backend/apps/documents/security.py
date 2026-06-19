"""
Security utilities for documents.
"""
import hashlib

def scan_file(file_obj):
    """
    Mock virus scan. In production, connect to ClamAV.
    """
    return {'status': 'OK', 'message': 'Scan passed'}

def compute_sha256(file_obj):
    """
    Computes the SHA256 hash of a file.
    """
    sha256_hash = hashlib.sha256()
    
    if hasattr(file_obj, 'seek'):
        file_obj.seek(0)
        
    if hasattr(file_obj, 'chunks'):
        for chunk in file_obj.chunks():
            sha256_hash.update(chunk)
    else:
        # Fallback for file-like objects without chunks()
        while chunk := file_obj.read(8192):
            sha256_hash.update(chunk)
            
    if hasattr(file_obj, 'seek'):
        file_obj.seek(0)
        
    return sha256_hash.hexdigest()
