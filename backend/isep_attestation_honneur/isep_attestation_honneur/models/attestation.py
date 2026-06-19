# -*- coding: utf-8 -*-
from odoo import models, fields, api
from odoo.exceptions import ValidationError
import re


class AttestationHonneur(models.Model):
    _name = 'isep.attestation.honneur'
    _description = 'Attestation sur l\'Honneur - ISEP'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'date_creation desc'

    # Référence automatique
    name = fields.Char(
        string='Référence',
        readonly=True,
        copy=False,
        default='Nouveau'
    )

    # Informations du candidat
    civilite = fields.Selection(
        selection=[('M', 'M.'), ('Mme', 'Mme')],
        string='Civilité',
        required=True,
        tracking=True,
    )
    nom = fields.Char(
        string='Nom',
        required=True,
        tracking=True,
    )
    prenom = fields.Char(
        string='Prénom',
        required=True,
        tracking=True,
    )
    date_naissance = fields.Date(
        string='Date de naissance',
        required=True,
        tracking=True,
    )
    nationalite = fields.Char(
        string='Nationalité(s)',
        required=True,
        tracking=True,
    )

    # Déclarations sur l'honneur
    decl_non_nationalite_francaise = fields.Boolean(
        string='Ne pas posséder la nationalité française',
        default=True,
        required=True,
        help='En cas de double nationalité, c\'est la nationalité française qui sera prise en compte.',
    )
    decl_non_naturalisation = fields.Boolean(
        string='Ne pas avoir une demande de naturalisation en cours',
        default=True,
        required=True,
    )
    decl_non_presentation_concours = fields.Boolean(
        string='Ne m\'être jamais présenté au concours d\'admission',
        default=True,
        required=True,
    )

    # Informations administratives
    lieu_signature = fields.Char(
        string='Lieu de signature',
        required=True,
        default='Dakar',
    )
    date_signature = fields.Date(
        string='Date de signature',
        required=True,
        default=fields.Date.today,
    )
    date_creation = fields.Datetime(
        string='Date de création',
        default=fields.Datetime.now,
        readonly=True,
    )

    state = fields.Selection(
        selection=[
            ('brouillon', 'Brouillon'),
            ('valide', 'Validé'),
            ('annule', 'Annulé'),
        ],
        string='Statut',
        default='brouillon',
        tracking=True,
    )

    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if vals.get('name', 'Nouveau') == 'Nouveau':
                vals['name'] = self.env['ir.sequence'].next_by_code('isep.attestation.honneur') or 'Nouveau'
        return super().create(vals_list)

    def action_valider(self):
        for rec in self:
            if not rec.decl_non_nationalite_francaise:
                raise ValidationError(
                    'Le candidat doit déclarer ne pas posséder la nationalité française.'
                )
            if not rec.decl_non_naturalisation:
                raise ValidationError(
                    'Le candidat doit déclarer ne pas avoir de demande de naturalisation en cours.'
                )
            if not rec.decl_non_presentation_concours:
                raise ValidationError(
                    'Le candidat doit déclarer ne s\'être jamais présenté au concours d\'admission.'
                )
            rec.state = 'valide'

    def action_annuler(self):
        self.state = 'annule'

    def action_brouillon(self):
        self.state = 'brouillon'

    def action_imprimer(self):
        return self.env.ref(
            'isep_attestation_honneur.action_report_attestation_honneur'
        ).report_action(self)

    def _get_nom_complet(self):
        return f"{self.nom.upper()} {self.prenom.upper()}"
