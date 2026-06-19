# Module Odoo : ISEP - Attestation sur l'Honneur

## Description

Module Odoo 16 permettant de générer des attestations sur l'honneur officielles
pour les candidats de l'ISEP Amadou Traware.

## Fonctionnalités

- Formulaire de saisie des informations candidat (civilité, nom, prénom, date de naissance, nationalité)
- Workflow de validation : Brouillon -> Validé -> Annulé
- Génération PDF du certificat avec le logo ISEP
- Référence automatique : ISEP/ATT/ANNEE/XXXX
- Historique et messagerie (chatter Odoo)
- Recherche et filtres par statut / nationalité

## Installation

1. Copier le dossier `isep_attestation_honneur` dans le répertoire `addons` de votre instance Odoo
2. Redémarrer le serveur Odoo : `python manage.py` ou `./odoo-bin -c odoo.conf`
3. Aller dans Paramètres > Activer le mode développeur
4. Aller dans Applications > Mettre à jour la liste des applications
5. Rechercher "ISEP Attestation" et cliquer sur Installer

## Utilisation

1. Le menu **ISEP - Attestations** apparaît dans la barre de navigation
2. Créer une nouvelle attestation en renseignant les informations du candidat
3. Cliquer sur **Valider** pour confirmer l'attestation
4. Cliquer sur **Imprimer / PDF** pour générer le document PDF officiel

## Compatibilité

- Odoo 16.0
- Python 3.8+

## Auteur

ISEP Amadou Traware
