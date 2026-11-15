import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../models/user_model.dart';
import '../../services/admin_report_pdf_service.dart';
import '../../services/admin_report_service.dart';
import '../../widgets/app_alert.dart';
import '../../widgets/curved_header_scaffold.dart';

/// Layar Cetak Laporan Admin ObeSight (Tahap 1: Konfigurasi & Pratinjau Ekspor PDF)
class AdminPrintReportScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminPrintReportScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminPrintReportScreen> createState() => _AdminPrintReportScreenState();
}

class _AdminPrintReportScreenState extends State<AdminPrintReportScreen> {
  ReportConfig _config = const ReportConfig();
  int _availablePatientsCount = 0;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _refreshAvailablePatients();
  }

  void _refreshAvailablePatients() {
    final count = AdminReportService.instance.countAvailablePatientsForPeriod(_config.period);
    setState(() {
      _availablePatientsCount = count;
    });
  }

  void _onPeriodSelected(ReportPeriod period) {
    if (_config.period == period) return;
    setState(() {
      _config = _config.copyWith(period: period);
    });
    _refreshAvailablePatients();
  }

  void _onUserLimitSelected(String value) {
    if (value == 'Semua pengguna') {
      setState(() {
        _config = _config.copyWith(userLimit: () => null);
      });
      return;
    }

    if (value == 'Kustom') {
      _showCustomUserLimitDialog();
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed != null) {
      setState(() {
        _config = _config.copyWith(userLimit: () => parsed);
      });
    }
  }

  void _showCustomUserLimitDialog() {
    final controller = TextEditingController(
      text: _config.userLimit != null ? _config.userLimit.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog<int>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            'Kustom Jumlah Pengguna',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F1E36),
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan jumlah batas pengguna yang ingin dihitung (minimal 1):',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 25',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF267352), width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Jumlah pengguna tidak boleh kosong';
                    }
                    final num = int.tryParse(val.trim());
                    if (num == null || num < 1) {
                      return 'Masukkan angka bulat minimal 1';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  final limit = int.parse(controller.text.trim());
                  Navigator.of(ctx).pop(limit);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF267352),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Terapkan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        );
      },
    ).then((customLimit) {
      if (customLimit != null && mounted) {
        setState(() {
          _config = _config.copyWith(userLimit: () => customLimit);
        });
      }
    });
  }

  void _onTypeSelected(ReportType type) {
    if (_config.type == type) return;
    setState(() {
      _config = _config.copyWith(type: type);
    });
  }

  void _onSectionToggled(ReportSection section, bool isChecked) {
    final updated = Set<ReportSection>.from(_config.selectedSections);
    if (isChecked) {
      updated.add(section);
    } else {
      updated.remove(section);
    }
    setState(() {
      _config = _config.copyWith(selectedSections: updated);
    });
  }

  Future<void> _handleDownloadOrPrint() async {
    // Validasi jika laporan internal dan semua checkbox dimatikan
    if (_config.type == ReportType.internal && _config.selectedSections.isEmpty) {
      AppAlert.showError(
        context,
        'Pilih minimal satu bagian laporan untuk mencetak Laporan Internal.',
      );
      return;
    }

    setState(() => _isPrinting = true);
    try {
      final reportData = await AdminReportService.instance.fetchPrintReportData(_config);
      final pdfBytes = await AdminReportPdfService.generateReportPdf(
        reportData,
        _config,
        adminName: widget.adminUser.name,
      );

      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final fileName = _config.type == ReportType.eksternal
          ? 'Laporan_Eksternal_ObeSight_$dateStr.pdf'
          : 'Laporan_Internal_ObeSight_$dateStr.pdf';

      await Printing.layoutPdf(
        name: fileName,
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        AppAlert.showError(context, 'Gagal mencetak dokumen laporan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periodDates = AdminReportService.resolveReportPeriodDates(_config.period);
    final periodRangeStr = AdminReportService.formatReportPeriodRange(
      periodDates.start,
      periodDates.end,
    );

    final isInternal = _config.type == ReportType.internal;
    final isPrintDisabled = isInternal && _config.selectedSections.isEmpty;

    return CurvedHeaderScaffold(
      title: 'Cetak Laporan',
      centerTitle: true,
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU HIJAU MUDA: Ringkasan data & aktivitas
            _buildHeaderSummaryCard(isDark),
            const SizedBox(height: 20),

            // 2. BARIS: Periode Laporan (Dropdown + Teks Rentang Nyata)
            _buildPeriodRow(isDark, periodRangeStr),
            const SizedBox(height: 18),

            // 3. BARIS: Jumlah Data Pengguna (Dropdown + Teks Tersedia X Pengguna)
            _buildUserLimitRow(isDark),
            const SizedBox(height: 24),

            // 4. BAGIAN: Pilih Jenis Laporan (2 Kartu Radio)
            Text(
              'Pilih Jenis Laporan',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F1E36),
              ),
            ),
            const SizedBox(height: 12),
            _buildReportTypeCard(
              isDark: isDark,
              type: ReportType.eksternal,
              title: 'Laporan Eksternal',
              shortTitle: 'Cetak Laporan Ringkas',
              description:
                  'Ringkas untuk pihak luar: distribusi IMT, rekapitulasi skrining, tingkat risiko, dan perbedaan jenis kelamin.',
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 12),
            _buildReportTypeCard(
              isDark: isDark,
              type: ReportType.internal,
              title: 'Laporan Internal',
              shortTitle: 'Cetak Laporan Lengkap',
              description:
                  'Lengkap untuk pengelola: 15 bagian mulai dari pengguna, IMT, skrining, aktivitas, makanan, tidur, hingga analisis.',
              icon: Icons.description_rounded,
            ),
            const SizedBox(height: 24),

            // 5. BAGIAN: Pilih Bagian Laporan (opsional - 8 Checkbox)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Bagian Laporan (opsional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1E36),
                  ),
                ),
                if (!isInternal) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hanya tersedia untuk Laporan Internal.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildSectionsCheckboxesGrid(isDark, isInternal),
            const SizedBox(height: 32),

            // 6. TOMBOL BESAR: Unduh / Cetak Laporan PDF
            _buildPrintButton(isDark, isPrintDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2D1F) : const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1B4D36) : const Color(0xFFCCE8D9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF267352),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan ObeSight',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1E36),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ringkasan data dan aktivitas pengguna',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(bool isDark, String periodRangeStr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2D1F) : const Color(0xFFE8F5EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFF267352),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Periode Laporan',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<ReportPeriod>(
                tooltip: 'Pilih periode laporan',
                initialValue: _config.period,
                offset: const Offset(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: _onPeriodSelected,
                itemBuilder: (ctx) => [
                  _buildPeriodMenuItem(ReportPeriod.satuBulan, 'Satu bulan (30 hari)', isDark),
                  _buildPeriodMenuItem(ReportPeriod.triwulan, 'Triwulan (90 hari)', isDark),
                  _buildPeriodMenuItem(ReportPeriod.setahun, 'Setahun (365 hari)', isDark),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _config.period.label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F1E36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                periodRangeStr,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<ReportPeriod> _buildPeriodMenuItem(
    ReportPeriod period,
    String label,
    bool isDark,
  ) {
    final isSelected = _config.period == period;
    return PopupMenuItem<ReportPeriod>(
      value: period,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            size: 16,
            color: const Color(0xFF267352),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF0F1E36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLimitRow(bool isDark) {
    final currentLabel = _config.userLimit == null
        ? 'Semua pengguna'
        : '${_config.userLimit} pengguna';

    final isExceeding =
        _config.userLimit != null && _config.userLimit! > _availablePatientsCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2D1F) : const Color(0xFFE8F5EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.people_alt_rounded,
            color: Color(0xFF267352),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jumlah Data Pengguna',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                tooltip: 'Pilih jumlah data pengguna',
                initialValue: currentLabel,
                offset: const Offset(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                onSelected: _onUserLimitSelected,
                itemBuilder: (ctx) => [
                  _buildUserLimitMenuItem('10', isDark),
                  _buildUserLimitMenuItem('30', isDark),
                  _buildUserLimitMenuItem('50', isDark),
                  _buildUserLimitMenuItem('100', isDark),
                  _buildUserLimitMenuItem('Semua pengguna', isDark),
                  _buildUserLimitMenuItem('Kustom', isDark),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F1E36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isExceeding
                    ? 'Tersedia $_availablePatientsCount pengguna pada periode ini (menggunakan semua yang tersedia).'
                    : 'Tersedia $_availablePatientsCount pengguna pada periode ini',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isExceeding
                      ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildUserLimitMenuItem(String value, bool isDark) {
    final isSelected = (_config.userLimit == null && value == 'Semua pengguna') ||
        (_config.userLimit != null && _config.userLimit.toString() == value);

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            size: 16,
            color: const Color(0xFF267352),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF0F1E36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard({
    required bool isDark,
    required ReportType type,
    required String title,
    required String shortTitle,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _config.type == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTypeSelected(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F2D1F) : const Color(0xFFE8F5EE))
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF267352)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF267352).withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF267352)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F1E36),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF267352).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type == ReportType.eksternal ? 'Ringkas' : 'Lengkap',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF267352)
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? const Color(0xFF267352) : const Color(0xFF94A3B8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsCheckboxesGrid(bool isDark, bool isInternal) {
    const col1 = [
      ReportSection.dataPengguna,
      ReportSection.dataImt,
      ReportSection.hasilSkrining,
    ];
    const col2 = [
      ReportSection.aktivitasFisik,
      ReportSection.makananMinuman,
      ReportSection.polaTidur,
    ];
    const col3 = [
      ReportSection.trenAktivitas,
      ReportSection.analisisKesimpulan,
    ];

    return Opacity(
      opacity: isInternal ? 1.0 : 0.45,
      child: IgnorePointer(
        ignoring: !isInternal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCheckboxColumn(col1, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildCheckboxColumn(col2, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildCheckboxColumn(col3, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxColumn(List<ReportSection> sections, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((sec) => _buildCheckboxItem(sec, isDark)).toList(),
    );
  }

  Widget _buildCheckboxItem(ReportSection sec, bool isDark) {
    final isChecked = _config.selectedSections.contains(sec);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _onSectionToggled(sec, !isChecked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFF267352) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isChecked
                        ? const Color(0xFF267352)
                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sec.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF0F1E36),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintButton(bool isDark, bool isDisabled) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDisabled
            ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
            : const Color(0xFF267352),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF267352).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (isDisabled || _isPrinting) ? null : _handleDownloadOrPrint,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPrinting)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.print_rounded,
                    color: isDisabled
                        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                        : Colors.white,
                    size: 26,
                  ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unduh / Cetak Laporan',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDisabled
                              ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                              : Colors.white,
                        ),
                      ),
                      Text(
                        'Laporan akan diunduh dalam format PDF',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: isDisabled
                              ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
