import os
from PIL import Image

def make_transparent(img_path, out_path):
    try:
        img = Image.open(img_path).convert("RGBA")
        datas = img.getdata()

        new_data = []
        for item in datas:
            # Change all white (also shades of whites) to transparent
            # item is (R, G, B, A)
            if item[0] > 200 and item[1] > 200 and item[2] > 200:
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)

        img.putdata(new_data)
        img.save(out_path, "PNG")
        print(f"Converted: {out_path}")
    except Exception as e:
        print(f"Failed {img_path}: {e}")

assets_dir = r"C:\Users\HP\Documents\Institut_Supérieur_d'enseignement_professionnelle_(ISEP)\Hackathon\backend\assets\seals"

for root, dirs, files in os.walk(assets_dir):
    for file in files:
        if file.lower().endswith('.jpg') or file.lower().endswith('.jpeg'):
            in_path = os.path.join(root, file)
            out_path = os.path.join(root, file.rsplit('.', 1)[0] + '.png')
            make_transparent(in_path, out_path)
