import re

with open('backend/apps/dossiers/services/pdf_generator.py', 'r', encoding='utf-8') as f:
    text = f.read()

# I will reduce the spacing to exactly 1.0 cm.
# Change "y_body = TEXT_Y - para.height - 1.0 * cm" to "- 0.5 * cm"
# Because text_y = l_b_y - 0.5 * cm. So total is 1.0 cm.

text = text.replace('y_body = TEXT_Y - para.height - 1.0 * cm', 'y_body = TEXT_Y - para.height - 0.5 * cm')

with open('backend/apps/dossiers/services/pdf_generator.py', 'w', encoding='utf-8') as f:
    f.write(text)

print("Adjusted spacing")
