// src/utils/parseApiError.js

/**
 * Extrait un message d'erreur compréhensible par l'utilisateur à partir d'une erreur Axios.
 * @param {Error} error - L'objet erreur retourné par le bloc catch d'Axios
 * @param {string} defaultMessage - Le message par défaut si l'erreur est indéterminée
 * @returns {string} Le message d'erreur formaté
 */
export function parseApiError(error, defaultMessage = 'Une erreur inattendue s\'est produite.') {
  // 1. Vérifier si on a une réponse de l'API avec des données
  const data = error?.response?.data;
  
  // Les APIs Django REST Framework / Custom renvoient souvent l'erreur dans l'une de ces clés
  if (data) {
    if (data.detail) return data.detail;
    if (data.error) return data.error;
    if (data.message) return data.message;
    
    // S'il s'agit d'un objet d'erreurs de validation DRF (ex: { email: ["Ce champ est obligatoire"] })
    if (typeof data === 'object' && Object.keys(data).length > 0) {
      const firstKey = Object.keys(data)[0];
      const firstError = data[firstKey];
      if (Array.isArray(firstError) && typeof firstError[0] === 'string') {
        return firstError[0]; // Renvoie la première erreur de validation
      }
    }
  }

  // 2. Si pas de message clair dans les data, on gère par code HTTP
  const status = error?.response?.status;
  switch (status) {
    case 400: return 'Données invalides. Vérifiez les informations saisies.';
    case 401: return 'Session expirée ou identifiants incorrects. Veuillez vous reconnecter.';
    case 403: return 'Vous n\'avez pas les droits nécessaires pour effectuer cette action.';
    case 404: return 'Ressource introuvable.';
    case 409: return 'Conflit : Cette ressource existe déjà ou est dans un état incompatible.';
    case 429: return 'Trop de requêtes. Veuillez patienter quelques instants.';
    case 500: return 'Erreur serveur. Nos équipes ont été notifiées.';
    case 502:
    case 503:
    case 504: return 'Le service est temporairement indisponible. Réessayez plus tard.';
  }

  // 3. Fallback sur le message de l'objet Error JS si présent (ex: "Network Error")
  if (error?.message) {
    if (error.message.includes('Network Error')) return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    return error.message;
  }

  // 4. Dernier recours
  return defaultMessage;
}
