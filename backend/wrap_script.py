import sys
path = 'apps/ai/views.py'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target_start = '    def post(self, request, *args, **kwargs):'

if target_start in content:
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if line.startswith('    def post(self, request, *args, **kwargs):'):
            lines.insert(i+1, '        try:')
            # Indent everything until the end of the class
            for j in range(i+2, len(lines)):
                if lines[j].startswith('class ') or lines[j].startswith('    def '):
                    break
                if lines[j].strip() != '':
                    lines[j] = '    ' + lines[j]
            # Add except block
            end_idx = j
            if j == len(lines) - 1 and not lines[j].startswith('class ') and not lines[j].startswith('    def '):
                end_idx = len(lines)
            
            except_block = [
                '        except Exception as _e:',
                '            import traceback',
                '            from rest_framework.response import Response',
                '            return Response({',
                '                "question": request.data.get("question", ""),',
                '                "answer": f"Désolé, une erreur technique est survenue : {str(_e)}",',
                '                "context_used": {}',
                '            }, status=200)'
            ]
            lines = lines[:end_idx] + except_block + lines[end_idx:]
            break

    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print("Wrapped!")
