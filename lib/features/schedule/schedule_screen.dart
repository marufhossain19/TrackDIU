import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const String _assetPath = 'images/Transport Schedule DIU.pdf';
  static const String _fileName = 'Transport Schedule DIU.pdf';
  bool _isDownloading = false;

  Future<void> _downloadSchedulePdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final byteData = await rootBundle.load(_assetPath);
      final bytes = byteData.buffer.asUint8List();
      final existingFile = await _resolveDownloadFile();
      if (await existingFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Already Downloaded'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => _openDownloadedFile(existingFile),
            ),
          ),
        );
        return;
      }
      final file = await _writePdfToLocal(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download Complete'),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () => _openDownloadedFile(file),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transport schedule PDF not found at images/Transport Schedule DIU.pdf',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<File> _writePdfToLocal(Uint8List bytes) async {
    final file = await _resolveDownloadFile();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _resolveDownloadFile() async {
    Directory targetDir;
    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        targetDir = downloadsDir;
      } else {
        targetDir = (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }

    return File('${targetDir.path}/$_fileName');
  }

  Future<void> _openDownloadedFile(File file) async {
    final uri = Uri.file(file.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the downloaded file.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF4F8FF);
    final titleColor = isDark ? Colors.white : const Color(0xFF0D2B5B);
    final panelBg = isDark ? const Color(0xFF111827) : Colors.white;
    final panelBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final bodyText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    const heroTextColor = Colors.white;
    const heroSubTextColor = Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0B215A) : Colors.transparent,
        foregroundColor: isDark ? Colors.white : titleColor,
        title: Text(
          'Transport Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Transport Schedule',
                            style: TextStyle(
                              color: heroTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Get the latest DIU bus timing PDF for offline access.',
                            style: TextStyle(
                              color: heroSubTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: panelBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Document',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to save the transport schedule PDF.',
                        style: TextStyle(
                          color: bodyText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isDownloading ? null : _downloadSchedulePdf,
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.1,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            _isDownloading
                                ? 'Downloading...'
                                : 'Download Schedule',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
