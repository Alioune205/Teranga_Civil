import sys
path = 'apps/ai/views.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''            return Response({'error': "Le service IA est temporairement indisponible."}, status=500)'''
replacement = '''            return Response({
                'question': question,
                'answer': f"ERREUR BACKEND DÉTECTÉE : {str(e)}",
                'context_used': {}
            })'''

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced!")
else:
    print("Target not found.")
