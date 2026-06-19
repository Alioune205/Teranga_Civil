# Assets - Seals Directory

Ce dossier contient les fichiers statiques (images) des sceaux et signatures par commune.

## 1. Convention de nommage des dossiers (Communes)
Le nom du dossier DOIT correspondre au nom normalisé de la commune :
- Tout en minuscules
- Sans accents
- Espaces et tirets remplacés par des underscores `_`
- *Exemple:* `Dakar Plateau` -> `dakar_plateau`, `Thiès` -> `thies`, `Ndiaganiao` -> `ndiaganiao`

## 2. Fichiers attendus dans chaque dossier
Chaque sous-dossier de commune doit contenir au moins les 3 fichiers suivants, identifiés par leur préfixe :
- `Cachet_Communal*` (ex: `Cachet_Communal_Commune_De_Keur_Massar.jpg`)
- `Cachet_Nominal*` (ex: `Cachet_Nominal_Officier.png`)
- `Signature_Officier*` (ex: `Signature_Officier.png`) *(Note: "Signarure_Officier*" est toléré par rétrocompatibilité)*

## Formats supportés
- SVG (recommandé pour la meilleure qualité d'impression)
- PNG (avec transparence)
- JPG / JPEG

## Fallback Dynamique
Si le dossier d'une commune n'existe pas ou s'il manque l'un des 3 éléments de validation requis (règle métier R3), le système passera automatiquement en mode **Fallback Dynamique** et dessinera de façon autonome des cercles bleus ("RÉPUBLIQUE DU SÉNÉGAL") et une signature textuelle cursive, en se basant sur les informations de la base de données.
