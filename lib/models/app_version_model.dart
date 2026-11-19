// ====================================================
// models/app_version_model.dart — App version for in-app updates
// ====================================================

class AppVersionModel {
  final String id;
  final String versionName; // e.g. "1.0.1"
  final int versionCode; // e.g. 2
  final String apkUrl; // Direct APK download URL or public CDN/Supabase Storage link
  final String title; // e.g. "Fresh Update Available"
  final List<String> releaseNotes; // List of changes/features
  final bool isMandatory; // true = force update; false = optional/dismissible
  final String? fileSize; // e.g. "60.5 MB"
  final DateTime? releaseDate;

  const AppVersionModel({
    required this.id,
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    this.title = 'New Update Available',
    this.releaseNotes = const [],
    this.isMandatory = false,
    this.fileSize,
    this.releaseDate,
  });

  factory AppVersionModel.fromMap(Map<String, dynamic> map) {
    List<String> notes = [];
    final rawNotes = map['release_notes'];
    if (rawNotes is List) {
      notes = rawNotes.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (rawNotes is String) {
      notes = rawNotes
          .split(RegExp(r'[\r\n]+'))
          .map((s) => s.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return AppVersionModel(
      id: map['id']?.toString() ?? '',
      versionName: map['version_name']?.toString() ?? '1.0.0',
      versionCode: (map['version_code'] as num?)?.toInt() ?? 1,
      apkUrl: map['apk_url']?.toString() ?? '',
      title: map['title']?.toString() ?? 'New Update Available',
      releaseNotes: notes,
      isMandatory: map['is_mandatory'] == true,
      fileSize: map['file_size']?.toString(),
      releaseDate: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'version_name': versionName,
    'version_code': versionCode,
    'apk_url': apkUrl,
    'title': title,
    'release_notes': releaseNotes,
    'is_mandatory': isMandatory,
    'file_size': fileSize,
    'created_at': (releaseDate ?? DateTime.now().toUtc()).toIso8601String(),
  };
}
