# Teranga-Civil - Plateforme GovTech (MVP Sénégal)

Ce dépôt contient le code source de **SUNU CIVIL**, une plateforme GovTech moderne destinée aux collectivités territoriales du Sénégal pour digitaliser et moderniser l'état civil et les démarches administratives.

---

## 🏗️ Structure Globale du Projet

```text
Hackathon/
├── backend/            # API REST Django (Cœur du Système)
├── frontend_react/     # Dashboard Administratif (React) - À venir
└── mobile_flutter/     # Application Mobile (Flutter) - À venir
```

---

## 🛠️ Guide d'Installation & Lancement (Backend)

Pour installer et exécuter le backend sur votre machine locale, suivez ces étapes :

### 1. Prérequis
- **Python 3.10+** installé.
- **PostgreSQL** installé et configuré (avec une base de données créée, ex: `sunu_civil_db`).

### 2. Cloner le Projet
```bash
git clone <URL_DU_DEPOT_GITHUB>
cd Hackathon/backend
```

### 3. Configurer l'Environnement Virtuel
Sous Windows :
```powershell
python -m venv venv
venv\Scripts\activate
```
Sous macOS/Linux :
```bash
python3 -m venv venv
source venv/bin/activate
```

### 4. Installer les Dépendances
```bash
pip install -r requirements.txt
```

### 5. Configurer les Variables d'Environnement
1. Dupliquez le fichier `.env.example` et renommez-le en `.env`.
2. Ouvrez `.env` et mettez à jour les accès PostgreSQL locaux :
   ```env
   DB_NAME=sunu_civil_db
   DB_USER=votre_utilisateur
   DB_PASSWORD=votre_mot_de_passe
   DB_HOST=127.0.0.1
   DB_PORT=5432
   ```

### 6. Appliquer les Migrations & Charger les Données de Test (Seed)
Créez la structure de la base de données et insérez les données initiales :
```bash
python manage.py migrate
python manage.py seed_data
```

### 7. Lancer le Serveur de Développement
```bash
python manage.py runserver
```
Le serveur sera disponible sur `http://127.0.0.1:8000/`.

---

## 🤝 Workflow de Collaboration & GitHub

### Rôles de l'Équipe
* **DEV 1A (Vous/Core)** : Architecture principale, authentification, rôles, dossiers, documents, audit.
* **DEV 2 (Backend Services)** : Compléter les modules stubs (`apps/notifications`, `apps/qr`, `apps/ai`, `apps/dashboard`).
* **DEV 3 & 4 (Frontend/Mobile)** : Consommer les API.

### Comment collaborer sur Git/GitHub ?

1. **Initialiser le dépôt (à faire une seule fois par DEV 1A)** :
   ```bash
   git init
   git add .
   git commit -m "feat: initial commit with backend core architecture"
   git branch -M main
   git remote add origin <URL_VOTRE_DEPOT_GITHUB>
   git push -u origin main
   ```

2. **Bonnes Pratiques de Collaboration** :
   - **Ne jamais travailler directement sur `main`** : Créez toujours une branche pour vos modifications.
     ```bash
     git checkout -b feat/nom-de-votre-fonctionnalite
     ```
   - **Faire des Pull Requests (PR)** sur GitHub pour fusionner vos modifications dans `main`.
   - **Mettre à jour régulièrement votre code** local avec les changements des autres :
     ```bash
     git pull origin main
     ```

---

## 🔗 Documentation de l'API (Swagger & Redoc)

La documentation interactive de l'API est générée automatiquement et accessible aux développeurs Frontend et Mobile lorsque le serveur backend tourne :

- **Swagger UI** : `http://127.0.0.1:8000/api/docs/`
- **ReDoc** : `http://127.0.0.1:8000/api/docs/redoc/`
- **Schéma Schema JSON** : `http://127.0.0.1:8000/api/docs/schema/`
