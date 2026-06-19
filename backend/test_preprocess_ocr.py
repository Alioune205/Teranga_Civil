from PIL import Image, ImageFilter, ImageEnhance
import pytesseract

img = Image.open("test.jpg")

img = img.convert("L")

enhancer = ImageEnhance.Contrast(img)
img = enhancer.enhance(3)

img = img.filter(ImageFilter.SHARPEN)

text = pytesseract.image_to_string(
    img,
    lang="fra"
)

print(text)