import fitz
doc = fitz.open('certificat_residence_fictif.pdf')
page = doc.load_page(0)
pix = page.get_pixmap()
pix.save('C:/Users/senep/.gemini/antigravity-ide/brain/69704cf6-39b3-48ed-8c23-d8a83e781d23/certificat_residence_fictif.png')
