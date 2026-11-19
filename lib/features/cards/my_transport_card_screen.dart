import 'package:flutter/material.dart';

class MyTransportCardScreen extends StatelessWidget {
  const MyTransportCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F7FF);
    final heading = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtitle = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBg = isDark ? const Color(0xFF111827) : const Color(0xFFFDFEFF);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE);
    final textPrimary = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transport Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'My Transport Card',
                style: TextStyle(
                  color: heading,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Digital replica of your campus transport pass',
                style: TextStyle(
                  color: subtitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: AspectRatio(
                    aspectRatio: 1.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A1F44).withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF0A1F44), Color(0xFF1A3A6E)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'TRANSPORT PASS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Daffodil International University',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFF132A5C),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0x33FFC107),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_bus_rounded,
                                      color: Color(0xFFFFC107), size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mirpur → DSC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final compact = constraints.maxWidth < 360;
                                    final avatarSize = compact ? 54.0 : 62.0;
                                    final qrSize = compact ? 54.0 : 62.0;
                                    final nameSize = compact ? 13.5 : 15.0;

                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: constraints.maxWidth,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: avatarSize,
                                          height: avatarSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFE2E8F0),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF475569)
                                                  : const Color(0xFFCBD5E1),
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: compact ? 38 : 44,
                                            color: muted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          width: avatarSize,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: compact ? 8 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Student Name',
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: nameSize,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: compact ? 6 : 8),
                                          _CardInfoRow(
                                            label: 'Department',
                                            value: 'B.Sc. in CSE',
                                            isDark: isDark,
                                          ),
                                          SizedBox(height: compact ? 2 : 4),
                                          _CardInfoRow(
                                            label: 'ID',
                                            value: '0242220005101373',
                                            isDark: isDark,
                                          ),
                                          SizedBox(height: compact ? 2 : 4),
                                          _CardInfoRow(
                                            label: 'Phone',
                                            value: '01XXXXXXXXX',
                                            isDark: isDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: compact ? 6 : 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: qrSize,
                                          height: qrSize,
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF475569)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFE2E8F0),
                                                  Color(0xFFCBD5E1)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.qr_code_2_rounded,
                                                color: Color(0xFF334155),
                                                size: 34,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: compact ? 3 : 5),
                                        Text(
                                          'QR CODE',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: compact ? 9 : 9.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: compact ? 6 : 8),
                                        Text(
                                          'Spring 2026',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: compact ? 11 : 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                      ),
                    ),
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

class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _CardInfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
