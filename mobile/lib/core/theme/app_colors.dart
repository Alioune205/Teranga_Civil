import 'package:flutter/material.dart';

/// Palette de couleurs officielle TERANGA CIVIL.
///
/// Design « refonte mobile » : bleu profond « pro » (`#0B285D`) + accent bleu
/// (`#153B80`) + neutres ardoise. Mêmes noms de tokens — seules les valeurs
/// changent, donc tout l'app hérite automatiquement du nouveau look.
abstract class AppColors {
  AppColors._();

  // ── Couleurs principales (bleu profond) ──────────────────────────────────
  static const Color primary      = Color(0xFF0B285D);
  static const Color primaryLight = Color(0xFF153B80);
  static const Color primaryDark  = Color(0xFF061533);
  static const Color secondary    = Color(0xFF153B80); // accent bleu
  static const Color secondaryDark = Color(0xFF0B285D);

  // ── Or → recoloré bleu ───────────────────────────────────────────────────
  static const Color gold      = Color(0xFF153B80);
  static const Color goldLight = Color(0xFFEAF0FB);

  // ── Fond & surfaces ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);

  // ── Textes (ardoise) ─────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint      = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Statuts dossiers ─────────────────────────────────────────────────────
  static const Color statusAmber = Color(0xFFF59E0B); // warning
  static const Color statusRed   = Color(0xFFEF4444); // error
  static const Color statusGreen = Color(0xFF10B981); // success
  static const Color statusBlue  = Color(0xFF3B82F6); // info

  // ── Backgrounds statuts ──────────────────────────────────────────────────
  static const Color statusAmberLight = Color(0xFFFEF3C7);
  static const Color statusRedLight   = Color(0xFFFEE2E2);
  static const Color statusGreenLight = Color(0xFFD1FAE5);
  static const Color statusBlueLight  = Color(0xFFDBEAFE);

  // ── Bordures & séparateurs ───────────────────────────────────────────────
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF0B285D);
  static const Color divider     = Color(0xFFF1F5F9);

  // ── États boutons ────────────────────────────────────────────────────────
  static const Color buttonDisabledBg   = Color(0xFFCBD5E1);
  static const Color buttonDisabledText = Color(0xFF94A3B8);

  // ── Erreur / validation inline ───────────────────────────────────────────
  static const Color error      = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // ── Succès ───────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  // ── Overlay & ombres (teinte ardoise) ────────────────────────────────────
  static const Color overlay = Color(0x800F172A);
  static const Color shadow  = Color(0x0A0F172A);
  static const Color shadowStrong = Color(0x140F172A);

  // ── Transparent ──────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;

  // ── Dégradés ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0B285D), Color(0xFF153B80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé d'en-tête utilisé partout : #0B285D → #1B4A9C (haut → bas).
  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF0B285D), Color(0xFF1B4A9C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF153B80), Color(0xFF0B285D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF153B80), Color(0xFF1B4A9C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0B285D), Color(0xFF143C82), Color(0xFF1B4A9C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );
}
