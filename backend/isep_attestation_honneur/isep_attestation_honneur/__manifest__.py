# -*- coding: utf-8 -*-
{
    'name': 'ISEP - Attestation sur l\'Honneur',
    'version': '16.0.1.0.0',
    'category': 'Human Resources',
    'summary': 'Génération d\'attestations sur l\'honneur pour les candidats ISEP Amadou Traware',
    'description': """
        Module permettant de générer des attestations sur l'honneur
        pour les candidats à l'ISEP Amadou Traware.
        
        Fonctionnalités :
        - Formulaire de saisie des informations du candidat
        - Génération du certificat en PDF avec le logo ISEP
        - Archivage des attestations générées
    """,
    'author': 'ISEP Amadou Traware',
    'website': '',
    'depends': ['base', 'mail'],
    'data': [
        'security/ir.model.access.csv',
        'views/attestation_views.xml',
        'views/menu_views.xml',
        'report/attestation_report.xml',
        'report/attestation_template.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
