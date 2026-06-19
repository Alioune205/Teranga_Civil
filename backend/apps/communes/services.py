import math
import requests
from django.conf import settings


def haversine_distance(lat1, lon1, lat2, lon2):
    """Distance en km entre deux coordonnées GPS (formule de Haversine)."""
    R = 6371
    phi1, phi2 = math.radians(lat1), math.radians(float(lat2))
    dphi = math.radians(float(lat2) - lat1)
    dlambda = math.radians(float(lon2) - lon1)
    a = (math.sin(dphi / 2) ** 2
         + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2)
    return round(R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


def valider_coordonnees(lat, lng):
    """Valide que les coordonnées GPS sont dans les plages acceptables."""
    if not (-90 <= lat <= 90):
        raise ValueError("Latitude invalide. Doit être entre -90 et 90.")
    if not (-180 <= lng <= 180):
        raise ValueError("Longitude invalide. Doit être entre -180 et 180.")


def get_itineraire_google(lat_depart, lng_depart, lat_arrivee, lng_arrivee, mode="driving"):
    """
    Appelle la Directions API Google Maps côté serveur.
    La clé API ne quitte jamais le backend.

    Retourne un dict avec :
    - polyline encodée (pour affichage sur carte Flutter)
    - distance_texte (ex: "3,2 km")
    - distance_metres (int)
    - duree_texte (ex: "12 mins")
    - duree_secondes (int)
    - etapes (liste des instructions de navigation)
    """
    api_key = settings.GOOGLE_MAPS_API_KEY
    if not api_key:
        raise Exception("Clé API Google Maps manquante sur le serveur.")
        
    url = "https://maps.googleapis.com/maps/api/directions/json"

    params = {
        "origin": f"{lat_depart},{lng_depart}",
        "destination": f"{lat_arrivee},{lng_arrivee}",
        "mode": mode,          # driving, walking, bicycling, transit
        "language": "fr",
        "key": api_key,
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
    except requests.exceptions.Timeout:
        raise Exception("Délai d'attente dépassé pour l'API Google Maps.")
    except requests.exceptions.RequestException as e:
        raise Exception(f"Erreur réseau lors de l'appel Google Maps : {str(e)}")

    if data.get("status") != "OK":
        error_message = data.get("error_message", data.get("status", "Erreur inconnue"))
        raise Exception(f"Google Maps API erreur : {error_message}")

    route = data["routes"][0]
    leg = route["legs"][0]

    # Extraire les étapes de navigation
    etapes = []
    for step in leg.get("steps", []):
        etapes.append({
            "instruction": step.get("html_instructions", ""),
            "distance": step["distance"]["text"],
            "duree": step["duration"]["text"],
            "mode": step.get("travel_mode", mode).lower(),
        })

    return {
        "polyline": route["overview_polyline"]["points"],
        "distance_texte": leg["distance"]["text"],
        "distance_metres": leg["distance"]["value"],
        "duree_texte": leg["duration"]["text"],
        "duree_secondes": leg["duration"]["value"],
        "etapes": etapes,
        "bounds": route.get("bounds", {}),
    }
