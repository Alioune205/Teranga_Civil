# Bilan des Corrections — Intégration Mobile/Backend du 14 Juin

Ce document récapitule l'ensemble des correctifs appliqués sur la branche `DevAliouneSene` suite au bilan d'intégration du 14 juin. L'intégralité de ces correctifs a été validée par la suite de tests automatisée (100% de succès) et poussée sur GitHub.

---

## 1. Bug Bloquant : Upload de documents (Erreur 500)
**Problème :** L'upload de fichiers plantait car le modèle `Document` attendait des champs inexistants (`sha256_hash` et `mime_type`).
**Solutions apportées :**
- Ajout des champs `sha256_hash` (CharField 64, indexé) et `mime_type` (CharField 100) au modèle `Document`.
- Création et application de la migration de base de données (`0005_document_sha256_mime`).
- Modification de `views.py` pour extraire automatiquement le `mime_type` depuis le contenu du fichier (`uploaded_file.content_type`) lors de l'upload.
- La logique de déduplication (rejet des doublons stricts via hash SHA256) fonctionne désormais correctement (renvoie une HTTP 409).
- Ajout d'une suite de tests complète couvrant les 4 flux d'upload (naissance soi-même, naissance tiers, décès, mariage) et le comportement anti-doublon.

## 2. Noms des parents sur le PDF de Naissance (PR #4)
**Problème :** Les PDF générés affichaient "N/A" pour les noms des parents à cause de clés de métadonnées incorrectes.
**Solutions apportées :**
- Correction du script `pdf_generator.py` : utilisation de la clé `nom_pere` au lieu de `prenom_pere`.
- Mise en place d'un mécanisme de fallback de `prenom_mere` vers `nom_mere` pour assurer la rétrocompatibilité des anciens dossiers.
- Mise à jour des libellés affichés sur le PDF : **"Nom Père"**, **"Prénoms Mère"**, **"Nom Mère"**.

## 3. Parseur OCR pour Extrait de Naissance
**Problème :** L'IA ne savait parser que les CNI et bloquait sur les extraits de naissance en pensant que le dossier existait déjà.
**Solutions apportées :**
- Création de la fonction dédiée `_parse_extrait_naissance_fields()` dans `apps/ai/ocr.py`.
- L'extracteur principal `extract_cni_data` accepte désormais un paramètre `dossier_type` pour router intelligemment vers le bon parseur (CNI ou Extrait de Naissance).
- Suppression de la vérification de doublon `check_dossier_duplicate` dans `OcrExtractView`, car cette route sert au pré-remplissage interactif et non à la soumission finale.

## 4. Confidentialité des demandes pour un Tiers
**Problème :** Le flag `is_for_third_party` n'était pas sauvegardé en base de données, ce qui posait un risque de voir les données du demandeur fuiter sur le certificat du tiers.
**Solutions apportées :**
- Le `DossierCreateSerializer` intercepte désormais le flag `is_for_third_party` dans la requête et le persiste proprement dans le champ JSON `metadata`.
- Sécurité renforcée dans le générateur PDF : si `metadata['is_for_third_party']` est vrai, le système refuse catégoriquement d'utiliser les informations du demandeur connecté comme solution de repli (fallback).

## 5. Environnement de Test : Seed Data incomplet
**Problème :** Le jeu de données initial (registre 101/1998) était incomplet et ne permettait pas de tester correctement la pré-complétion.
**Solutions apportées :**
- Refonte du script `seed_data.py`.
- Injection des registres complets `100/2000` (Moussa Diop) et `101/2000` (Awa Fall) incluant tous les champs requis : sexe, lieu de naissance, noms des parents, et professions.
- Logique intelligente : si le registre existe déjà, le script le complète plutôt que d'échouer.

## 6. Variables d'Environnement et Performances OCR
**Problème :** Il manquait des variables pour l'IA Ndiogoye et des doutes subsistaient sur l'instanciation de l'OCR.
**Solutions apportées :**
- Confirmation que la librairie `EasyOCR` est bien instanciée sous forme de Singleton (chargement unique au démarrage du module).
- Ajout de la variable `GROQ_API_KEY` dans le fichier local `.env`.
- Documentation complète de la procédure dans `.env.example` avec les liens vers la console Groq.

## 7. Corrections Additionnelles (Dashboard)
**Problème :** Certains tests du Dashboard échouaient suite à des différences de nommage entre l'API et les attentes des développeurs mobiles.
**Solutions apportées :**
- Ajout des alias anglais `dossiers_by_type` et `top_agents` dans la réponse de l'API Dashboard tout en conservant les clés françaises pour le frontend web.
- Création de l'alias d'URL `/export/csv/` pour corriger les erreurs de ReverseMatch.
- Correction interne des tests Dashboard pour gérer proprement les flux `StreamingHttpResponse` et l'encodage `charset=utf-8`.

---
*Ce document récapitulatif peut être partagé avec l'équipe Mobile et Backend.*
