from django.contrib.auth import get_user_model
User = get_user_model()
user, created = User.objects.get_or_create(
    email='citoyen@test.com', 
    defaults={
        'first_name':'Modou', 
        'last_name':'Fall', 
        'phone': '+221771234567', 
        'role':'citizen', 
        'is_verified':True, 
        'is_active':True
    }
)
user.set_password('Passer123')
user.save()
print('Citizen account ready:', user.email)
