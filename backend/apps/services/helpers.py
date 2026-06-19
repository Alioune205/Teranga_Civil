"""
General helper functions.
"""
import re


def clean_phone_number(phone_str):
    """
    Cleans phone number from spaces, dashes, dots, parentheses.
    Extracts the pure digits.
    """
    if not phone_str:
        return ""
    return re.sub(r'[\s\-\.\(\)]', '', phone_str)


def format_senegal_phone(phone_str):
    """
    Formats a phone number with Senegalese standard layout:
    +221 77 123 45 67
    """
    digits = clean_phone_number(phone_str)
    
    # Strip +221 or 221 prefix if present
    if digits.startswith('+221'):
        digits = digits[4:]
    elif digits.startswith('221'):
        digits = digits[3:]
        
    if len(digits) == 9:
        operator = digits[:2]
        part1 = digits[2:5]
        part2 = digits[5:7]
        part3 = digits[7:9]
        return f"+221 {operator} {part1} {part2} {part3}"
        
    return phone_str


def normalize_text(text):
    """
    Basic text normalization (lowercase, stripping accents, whitespace).
    """
    if not text:
        return ""
    text = text.strip().lower()
    
    # Simple accent replacements
    replacements = {
        '[éèêë]': 'e',
        '[àâä]': 'a',
        '[îï]': 'i',
        '[ôö]': 'o',
        '[ûü]': 'u',
        '[ç]': 'c'
    }
    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text)
        
    return text
