from PIL import Image
import os

input_path = r'C:\Users\senep\.gemini\antigravity-ide\brain\9cabbb3a-dccc-4bff-b683-5f2775e7d1c0\baobab_silhouette_1781411190346.png'
output_path = r'C:\Users\senep\Desktop\Teranga-Civil-Developpe\backend\assets\baobab.png'

os.makedirs(os.path.dirname(output_path), exist_ok=True)

try:
    img = Image.open(input_path).convert('RGBA')
    datas = img.getdata()
    
    new_data = []
    # Make anything close to white transparent, and keep the grey parts
    for item in datas:
        # If it's very light (background), make it transparent
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))
        else:
            # It's the baobab tree. Make it light grey with some transparency
            # Let's say we want a very light watermark, 15% opacity
            new_data.append((item[0], item[1], item[2], 30))
            
    img.putdata(new_data)
    img.save(output_path, 'PNG')
    print('Watermark processed successfully:', output_path)
except Exception as e:
    print('Error processing image:', e)
