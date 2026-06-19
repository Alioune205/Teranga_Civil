import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Card d'upload de document (photo ou galerie).
/// Affiche une prévisualisation si un fichier est sélectionné.
class UploadDocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? filePath;      // null = rien sélectionné
  final bool isRequired;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const UploadDocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.filePath,
    this.isRequired = false,
    this.isLoading = false,
    this.onRemove,
  });

  bool get _hasFile => filePath != null && filePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasFile ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hasFile
              ? AppColors.statusGreenLight
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasFile ? AppColors.success : AppColors.border,
            width: _hasFile ? 2 : 1,
          ),
        ),
        child: _hasFile
            ? _FilePreview(
                filePath: filePath!,
                title: title,
                onRemove: onRemove,
                onReplace: onTap,
              )
            : _EmptyState(
                title: title,
                subtitle: subtitle,
                icon: icon,
                isRequired: isRequired,
                isLoading: isLoading,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isRequired;
  final bool isLoading;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isRequired,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                      ),
                    ),
                  )
                : Icon(icon, color: AppColors.textSecondary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusRedLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Requis',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.statusRed,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: AppColors.secondary, size: 22),
        ],
      ),
    );
  }
}

Widget _thumbError(BuildContext context, Object error, StackTrace? stack) =>
    Container(
      width: 56,
      height: 56,
      color: AppColors.border,
      child: const Icon(Icons.insert_drive_file_outlined,
          color: AppColors.textSecondary),
    );

class _FilePreview extends StatelessWidget {
  final String filePath;
  final String title;
  final VoidCallback? onRemove;
  final VoidCallback onReplace;

  const _FilePreview({
    required this.filePath,
    required this.title,
    required this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Miniature (web : blob via Image.network ; natif : fichier)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(filePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: _thumbError)
                : Image.file(File(filePath),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: _thumbError),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('Document ajouté',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onReplace,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.statusRedLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.statusRed),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Utilitaire pour ouvrir la caméra ou la galerie.
///
/// Les octets du fichier choisi sont mis en cache (clé = chemin renvoyé) au
/// moment de la sélection, ce qui permet de les téléverser ensuite via
/// `MultipartFile.fromBytes` aussi bien en **web** (où `XFile.path` est un
/// blob illisible par `File`) qu'en **natif**.
class DocumentUploadHelper {
  static final _picker = ImagePicker();
  static final Map<String, Uint8List> _bytesCache = {};

  /// Octets du fichier précédemment sélectionné (ou null si non disponibles).
  static Uint8List? bytesFor(String path) => _bytesCache[path];

  static Future<String?> _withBytes(XFile? file) async {
    if (file == null) return null;
    try {
      _bytesCache[file.path] = await file.readAsBytes();
    } catch (_) {/* on garde quand même le chemin pour le natif */}
    return file.path;
  }

  /// Sélection directe depuis la galerie (sans feuille de choix).
  static Future<String?> pickFromGallery(BuildContext context) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    return _withBytes(file);
  }

  /// Prise de photo directe via l'appareil.
  static Future<String?> pickFromCamera(BuildContext context) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    return _withBytes(file);
  }

  static Future<String?> pick(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un document',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text('Prendre une photo',
                    style: AppTextStyles.bodyLarge),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  final nav = Navigator.of(ctx);
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1600,
                    maxHeight: 1600,
                    imageQuality: 80,
                  );
                  nav.pop(await _withBytes(file));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text('Choisir depuis la galerie',
                    style: AppTextStyles.bodyLarge),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  final nav = Navigator.of(ctx);
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1600,
                    maxHeight: 1600,
                    imageQuality: 80,
                  );
                  nav.pop(await _withBytes(file));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
