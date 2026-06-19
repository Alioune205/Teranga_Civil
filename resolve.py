import os

files = [
    r"backend\apps\ai\views.py",
    r"backend\apps\dossiers\models.py",
    r"backend\apps\dossiers\serializers.py"
]

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    import re
    # We will just accept the incoming changes (origin/Kalz) for these conflicts
    # Pattern: <<<<<<< HEAD ... ======= (keep this part? No, keep the kalz part) >>>>>>> origin/Kalz
    # Actually, it's safer to just run git checkout --theirs for these files!
    
