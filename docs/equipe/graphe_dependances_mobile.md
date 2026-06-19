# Matrice des Dépendances : Équipe Mobile Flutter

Voici le graphe d'organisation pour les 3 développeurs de l'équipe Mobile.

## 📊 Graphe de Dépendances Mobile

```mermaid
graph TD
    %% Définition des membres
    DEV_MOB_3["DEV MOBILE 3\n(Caméra, Permissions & Compression)"]
    DEV_MOB_1["DEV MOBILE 1\n(UI Formulaires & Logique visuelle)"]
    DEV_MOB_2["DEV MOBILE 2\n(API, Dio & Riverpod)"]
    BACKEND["Équipe Backend (API)\n(Ibrahima)"]

    %% Dépendances
    DEV_MOB_3 -->|Fournit les images compressées prêtes à l'emploi| DEV_MOB_1
    DEV_MOB_1 -->|Assemble les UI et passe les données du formulaire à| DEV_MOB_2
    DEV_MOB_2 -->|Envoie le payload complet à| BACKEND
    BACKEND -->|Renvoie les erreurs métiers (ex: délai dépassé) à| DEV_MOB_2
    DEV_MOB_2 -->|Déclenche l'affichage des erreurs sur l'UI de| DEV_MOB_1

    %% Styles
    style DEV_MOB_3 fill:#ffebcd,stroke:#333,stroke-width:2px
    style DEV_MOB_1 fill:#e0ffff,stroke:#333,stroke-width:2px
    style DEV_MOB_2 fill:#ffe4e1,stroke:#333,stroke-width:2px
    style BACKEND fill:#eee,stroke:#333,stroke-dasharray: 5 5
```

---

## 🛠️ Explications du Flux de Travail Mobile

### 1. **La base technique native** : DEV MOBILE 3
Il doit commencer en premier (ou de façon isolée). Il crée les composants de prise de photo, demande les permissions OS (iOS/Android), et gère la compression. Sans lui, le formulaire ne peut pas collecter de vraies pièces jointes optimisées.

### 2. **L'assembleur visuel** : DEV MOBILE 1
Il construit les écrans (`residence_form_screen.dart`). 
*Dépendance* : Il intègre les boutons "Prendre une photo" développés par **DEV MOBILE 3**. Ensuite, il gère la logique d'interface : faire apparaître 2 champs supplémentaires si la case "Décès à domicile" est cochée. Une fois le formulaire rempli, il envoie un objet structuré à DEV MOBILE 2.

### 3. **Le connecteur API (Fin de chaîne Mobile)** : DEV MOBILE 2
Il gère l'état global (Riverpod) et les appels HTTP (Dio). 
*Dépendance* : Il attend l'objet contenant les textes et les images du **DEV MOBILE 1**, puis l'envoie au Backend. Il doit également être en contact avec **l'équipe Backend (Ibrahima)** pour comprendre exactement le format attendu (Multipart) et réceptionner les codes d'erreur (ex: Erreur 400 pour bloquer l'interface).
