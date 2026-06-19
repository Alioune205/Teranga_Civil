# Répartition des Tâches Globale : Résidence, Décès & Mariage (Exclusion du Mobile)

Conformément à vos consignes, l'équipe Flutter (Mobile) est totalement exclue de cette feuille de route. Nos 5 développeurs Web/Backend vont gérer tous les nouveaux services (Résidence, Décès, Mariage).
*Note : L'IA a déjà codé la refonte dynamique des formulaires (Métadonnées) dans `DossierDetail.jsx`.*

## 🧑‍💻 DEV 2A - PAPE ALIOUNE SENE
**Rôle** : Lead Backend PDF (Indépendant & Volume Max)
- **Tâche 1** : Créer le layout `_draw_residence_layout` (Résidence) avec la mention : *"Validité : 3 mois à compter de la date de délivrance"*.
- **Tâche 2** : Créer les layouts `_draw_death_layout` (Décès) et `_draw_burial_permit` (Permis d'inhumation).
- **Tâche 3** : Créer le layout `_draw_marriage_layout` (Mariage) affichant les blocs : ÉPOUX, ÉPOUSE, DÉTAILS DU REGISTRE.
- **Tâche 4** : Modifier le routeur principal `_draw_pdf_content` pour orienter la génération PDF en fonction du type d'acte (Résidence, Décès, Mariage).

## 🧑‍💻 DEV 1C - MAIMOUNA SALL
**Rôle** : Lead Frontend React (Sécurité Documentaire)
- **Tâche 5** : Développer le "Viewer Documentaire Avancé" dans `DossierDetail.jsx` pour examiner les pièces jointes des 3 nouveaux actes.
- **Tâche 6** : Implémenter des cases à cocher obligatoires "Pièce Conforme" avant de débloquer le bouton "Approuver" :
  - *Pour la Résidence* : Vérifier CNI + Attestation Délégué.
  - *Pour le Décès* : Vérifier Constat Médecin + CNIs (avec règle des 2 témoins si décès à domicile).
  - *Pour le Mariage* : Vérifier les CNIs des Époux et des Témoins de mariage.

## 🧑‍💻 DEV 1D - IBRAHIMA KHALILOU DIALLO
**Rôle** : Lead Backend API & Validations Métier (Garde-fou)
- **Tâche 7** : Implémenter le blocage de délai. Ajouter une règle backend pour refuser un certificat de décès si la `date_deces` remonte à plus d'un an.
- **Tâche 8** : Créer le validateur de pièces jointes Backend pour s'assurer que le payload JSON contient bien toutes les images requises pour la Résidence, le Décès ET le Mariage.

## 🧑‍💻 DEV 1B - PATHE FALL
**Rôle** : Frontend React (Guichet Physique / Saisie sur place)
- **Tâche 9** : Intégrer les formulaires de création de "Certificat de Résidence" et "Extrait de Mariage" dans le module **Guichet Rapide** (Interface Web Interne). Cela permet à un agent d'enregistrer une demande pour un citoyen venu physiquement à la mairie.

## 🧑‍💻 DEV 2B - EL HADJI MASSOGUI DIOP
**Rôle** : Tests Backend QA & Configuration Django Admin
- **Tâche 10** : Écrire les Tests Unitaires complets pour valider les règles métiers d'Ibrahima et s'assurer que les PDF de Pape (Résidence, Décès, Mariage) se génèrent sans erreur.
- **Tâche 11** : Mettre à jour l'interface native d'administration (Django Admin) pour qu'un Super Admin puisse consulter et gérer ces 3 nouveaux types de dossiers.
