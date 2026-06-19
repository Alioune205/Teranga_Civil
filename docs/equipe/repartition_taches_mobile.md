# Répartition des Tâches : Équipe Mobile Flutter (Résidence, Décès & Mariage)

L'équipe Mobile (composée de 3 développeurs) intègre tous les nouveaux certificats dans l'application citoyen.

## 📱 DEV MOBILE 1
**Rôle** : Lead UI / UX & Formulaires
- **Tâche 1** : Créer l'écran `residence_form_screen.dart`. Y intégrer les champs requis (Pièce d'identité, Attestation délégué, Copie CNI) et la note : *"Ce certificat aura une validité de 3 mois"*.
- **Tâche 2** : Créer l'écran `deces_form_screen.dart` (Permis d'inhumation). Implémenter la logique réactive : Si l'utilisateur coche la case "Décès à domicile", faire apparaître dynamiquement deux champs de téléversement obligatoires pour les CNIs de "Témoin 1" et "Témoin 2".
- **Tâche 3** : Créer l'écran `mariage_form_screen.dart` et demander le téléversement des CNIs des mariés et des témoins.

## 📱 DEV MOBILE 2
**Rôle** : Lead API, Riverpod & Uploads Multi-part
- **Tâche 4** : Créer et configurer tous les providers (`residence_provider.dart`, `deces_provider.dart`, `mariage_provider.dart`).
- **Tâche 5** : Gérer la soumission des données à l'API Django en `Multipart/form-data` via le client Dio.
- **Tâche 6** : Afficher les erreurs du backend (ex: Erreur "Délai d'un an dépassé" pour le décès).

## 📱 DEV MOBILE 3
**Rôle** : Intégration Native & Optimisation Fichiers
- **Tâche 7** : Développer le module de capture de documents (`image_picker` ou `file_picker`).
- **Tâche 8** : Implémenter la compression d'images côté client avant l'envoi (max 2 Mo par scan).
- **Tâche 9** : Gérer les permissions natives (caméra et stockage).
