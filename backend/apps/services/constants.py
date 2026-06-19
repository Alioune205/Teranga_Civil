"""
Constants for Senegal territorial administration and system statuses.
"""

# Senegalese Regions
SENEGAL_REGIONS = [
    'Dakar',
    'Diourbel',
    'Fatick',
    'Kaffrine',
    'Kaolack',
    'Kédougou',
    'Kolda',
    'Louga',
    'Matam',
    'Saint-Louis',
    'Sédhiou',
    'Tambacounda',
    'Thiès',
    'Ziguinchor',
]

# File constraints
MAX_UPLOAD_SIZE_MB = 10
ALLOWED_EXTENSIONS = ['pdf', 'jpg', 'jpeg', 'png']

# Custom System Error Codes
ERROR_INVALID_REF = 'ERR_001'
ERROR_FILE_TOO_LARGE = 'ERR_002'
ERROR_INVALID_EXTENSION = 'ERR_003'
ERROR_TRANSITION_NOT_ALLOWED = 'ERR_004'
ERROR_CNI_INVALID = 'ERR_005'
ERROR_PHONE_INVALID = 'ERR_006'
