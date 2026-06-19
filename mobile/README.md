# TERANGA CIVIL
### *"L'administration proche de vous"*

Application mobile civique sénégalaise permettant aux citoyens de faire des demandes de certificats d'état civil depuis leur téléphone.

---

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter 3.x |
| State management | flutter_riverpod ^2.5.1 |
| Navigation | go_router ^13.0.0 |
| HTTP | dio ^5.4.0 |
| Stockage sécurisé | flutter_secure_storage ^9.0.0 |
| Préférences | shared_preferences ^2.2.2 |
| OTP input | pin_code_fields ^8.0.1 |
| Image picker | image_picker ^1.0.7 |
| Animations | lottie ^3.0.0 |
| Fonts | google_fonts ^6.1.0 (Poppins) |
| Format dates | intl ^0.19.0 |
| SVG | flutter_svg ^2.0.9 |
| Cache images | cached_network_image ^3.3.1 |
| Réseau | connectivity_plus ^5.0.2 |

---

## Palette de couleurs

```
primary:       #1B2A6B   (Navy blue)
secondary:     #4CAF82   (Mint green)
background:    #F5F7FA
surface:       #FFFFFF
textPrimary:   #1B2A6B
textSecondary: #6B7280
statusAmber:   #F59E0B
statusRed:     #EF4444
statusGreen:   #4CAF82
statusBlue:    #3B82F6
```

---

## Architecture

Feature-First + Clean Architecture légère :

```
feature/
  data/
    remote_datasource.dart
    local_datasource.dart
    repository_impl.dart
  domain/
    repository.dart
    models/
    usecases/
  presentation/
    providers/
    screens/
```

**Règle absolue** : `presentation` ne parle jamais directement à `data`. Toujours via `domain`.

---

## Plan de développement

| Étape | Contenu | Statut |
|---|---|---|
| 1 | Initialisation projet, pubspec, structure | ✅ Fait |
| 2 | Core & Thème (couleurs, typo, validators) | ⏳ À venir |
| 3 | Shared Widgets & Layout | ⏳ À venir |
| 4 | Network & Router | ⏳ À venir |
| 5 | Feature AUTH (S01-S06) | ⏳ À venir |
| 6 | Feature HOME + CERTIFICATES (S07-S10A) | ⏳ À venir |
| 7 | Feature PAYMENT + DOSSIERS (S11-S12A) | ⏳ À venir |
| 8 | Feature ASSISTANT + PROFIL + Finalisation | ⏳ À venir |

---

## Installation

```bash
# Récupérer les dépendances
flutter pub get

# Lancer l'app
flutter run

# Lancer les tests
flutter test
```

---

*Développé par l'équipe Frontend ISEP de Diamniadio*
