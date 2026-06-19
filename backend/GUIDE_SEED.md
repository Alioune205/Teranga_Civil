# Guide : Peuplement de la Base de Données (Seed)

Afin de faciliter les tests en local sans avoir à créer manuellement des données à chaque fois, un script complet de peuplement (seed) a été ajouté au projet. Ce script crée automatiquement une structure de données très complète et réaliste (utilisateurs, communes, dossiers, paiements, etc.).

## 🚀 Comment l'utiliser ?

Pour générer ces données, placez-vous dans le dossier `backend` et exécutez la commande suivante (assurez-vous que votre environnement virtuel est activé) :

```bash
python manage.py seed_all_profiles --flush
```

> [!WARNING]
> L'option `--flush` **effacera l'intégralité de votre base de données locale actuelle** avant d'insérer les nouvelles données. Ne l'utilisez que si vous souhaitez repartir de zéro. Si vous souhaitez garder vos données existantes, retirez l'option `--flush` (bien que cela puisse entraîner des conflits selon les données déjà présentes).

L'exécution du script prend quelques minutes (téléchargement des modèles d'IA, génération des fichiers PDF, etc.). 

## 📊 Que contient cette base de données générée ?

Le script insère :
- **5 Communes :** Dakar Plateau, Keur Massar, Thiès, Ndiaganiao, Saint-Louis.
- **41 Utilisateurs internes :** Un super administrateur global et 8 agents pour chaque commune (Admin civil, Accueil, Officiers d'état civil, Caisse, Chef de centre).
- **~46 Citoyens :** Avec profils d'état civil complets.
- **~210 Dossiers :** Tous types de demandes, couvrant tous les statuts (brouillon, soumis, en examen, rejeté, complété), incluant des demandes pour des tiers.
- **Pièces jointes & Paiements :** Faux fichiers PDF, historiques de paiement variés (Wave, Orange Money, etc.).
- **Logs d'audit :** Historique de 50 actions aléatoires dans le système pour vos tests d'interface.

## 🔑 Identifiants de Test

Le mot de passe pour **TOUS** les comptes générés est identique :
**Mot de passe :** `passpass`

### Administrateur Global
- **Email :** `admin@teranga.sn`

### Comptes Agents (Par Commune)
Remplacer `{code}` par l'un des codes suivants selon la commune que vous voulez tester : 
- `DKR-P` (Dakar Plateau)
- `DKR-KM` (Keur Massar)
- `THI-T` (Thiès)
- `THI-N` (Ndiaganiao)
- `STL-S` (Saint-Louis)

- **Admin civil :** `admin_{code}@teranga.sn` 
- **Agent d'accueil :** `accueil1_{code}@teranga.sn` ou `accueil2_{code}@teranga.sn`
- **Officier d'état civil :** `officier1_{code}@teranga.sn` ou `officier2_{code}@teranga.sn`
- **Agent de caisse :** `caisse1_{code}@teranga.sn` ou `caisse2_{code}@teranga.sn`

### Comptes Citoyens
- **Email :** `test1@citoyen.sn`
- **Email :** `test2@citoyen.sn`
- ... (jusqu'à `test46@citoyen.sn`)
