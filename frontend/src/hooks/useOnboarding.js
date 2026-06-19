// src/hooks/useOnboarding.js
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { driver } from 'driver.js';
import 'driver.js/dist/driver.css';

export function useOnboarding() {
  const location = useLocation();

  useEffect(() => {
    // Ne se déclenche que sur la page d'accueil /dashboard
    if (location.pathname !== '/dashboard') return;
    
    const hasSeenOnboarding = localStorage.getItem('onboarding_done');
    if (hasSeenOnboarding) return;

    // Laisse le temps au DOM de se construire
    const timer = setTimeout(() => {
      // Les sélecteurs dépendent des classes Tailwind présentes
      const kpiContainer = document.querySelector('.grid.grid-cols-1.md\\:grid-cols-3');
      const headerObj = document.querySelector('header');
      const sidebarObj = document.querySelector('aside');

      const steps = [
        {
          popover: {
            title: 'Bienvenue sur Teranga Civil ! 👋',
            description: 'Prenez 30 secondes pour découvrir votre espace d\'administration.',
          }
        }
      ];

      if (sidebarObj) {
        steps.push({
          element: sidebarObj,
          popover: {
            title: 'Menu Principal',
            description: 'Accédez à la Banque des Demandes, la gestion des Citoyens et vos Paramètres.',
            side: 'right',
            align: 'start'
          }
        });
      }

      if (kpiContainer) {
        steps.push({
          element: kpiContainer,
          popover: {
            title: 'Indicateurs en temps réel',
            description: 'Ces cartes résument l\'activité. Cliquez dessus pour filtrer directement vos dossiers.',
            side: 'bottom',
            align: 'start'
          }
        });
      }

      if (headerObj) {
        steps.push({
          element: headerObj,
          popover: {
            title: 'Notifications & Profil',
            description: 'Consultez vos alertes, changez le thème visuel, et accédez à votre profil.',
            side: 'bottom',
            align: 'end'
          }
        });
      }

      const driverObj = driver({
        showProgress: true,
        animate: true,
        nextBtnText: 'Suivant',
        prevBtnText: 'Précédent',
        doneBtnText: 'Terminer',
        steps: steps,
        onDestroyStarted: () => {
          localStorage.setItem('onboarding_done', 'true');
          driverObj.destroy();
        },
      });

      driverObj.drive();
    }, 1500);

    return () => clearTimeout(timer);
  }, [location.pathname]);
}
