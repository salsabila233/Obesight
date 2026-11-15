import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'admin_report_service.dart';

/// Service untuk membuat dokumen PDF resmi Laporan ObeSight (Tahap 2: Eksternal & Internal Lengkap)
class AdminReportPdfService {
  // Palet warna resmi tema ObeSight
  static final primaryColor = PdfColor.fromHex('#267352');
  static final secondaryBg = PdfColor.fromHex('#E8F5EE');
  static final darkText = PdfColor.fromHex('#0F1E36');
  static final mutedText = PdfColor.fromHex('#64748B');
  static final borderColor = PdfColor.fromHex('#CCE8D9');
  static final tableHeaderBg = PdfColor.fromHex('#F1F5F9');

  // Palet warna 7 Kategori Obesitas resmi aplikasi ObeSight
  static final colorInsufficient = PdfColor.fromHex('#2563EB'); // Biru
  static final colorNormal = PdfColor.fromHex('#10B981');       // Hijau
  static final colorOverweight1 = PdfColor.fromHex('#FACC15');  // Kuning
  static final colorOverweight2 = PdfColor.fromHex('#FB923C');  // Oranye
  static final colorObesity1 = PdfColor.fromHex('#EA580C');     // Oranye Tua
  static final colorObesity2 = PdfColor.fromHex('#DC2626');     // Merah
  static final colorObesity3 = PdfColor.fromHex('#9333EA');     // Ungu

  static Future<Uint8List> generateReportPdf(
    ReportData reportData,
    ReportConfig config, {
    String? adminName,
  }) async {
    final pdf = pw.Document();

    // Memuat logo aplikasi dari aset jika tersedia
    pw.MemoryImage? logoImage;
    try {
      final byteData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      try {
        final byteData = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (_) {
        // Fallback anggun jika aset tidak tersedia pada testing environment
      }
    }

    if (config.type == ReportType.eksternal) {
      _buildEksternalReport(pdf, reportData, config, adminName, logoImage);
    } else {
      _buildInternalReport(pdf, reportData, config, adminName, logoImage);
    }

    return pdf.save();
  }

  // ===========================================================================
  // 1. LAPORAN EKSTERNAL (Format Surat Dinas, 2 Halaman A4)
  // ===========================================================================
  static void _buildEksternalReport(
    pw.Document pdf,
    ReportData reportData,
    ReportConfig config,
    String? adminName,
    pw.MemoryImage? logoImage,
  ) {
    final periodRangeUpper = _formatPeriodUppercase(reportData.startDate, reportData.endDate);
    final printedDateStr = _formatIndonesianDate(DateTime.now());

    // 1. Rekapitulasi skrining
    final insCount = reportData.obesityCounts[ObesityCategory.insufficientWeight] ?? 0;
    final normCount = reportData.obesityCounts[ObesityCategory.normalWeight] ?? 0;
    final overCount = (reportData.obesityCounts[ObesityCategory.overweightLevel1] ?? 0) +
        (reportData.obesityCounts[ObesityCategory.overweightLevel2] ?? 0);
    final obeCount = (reportData.obesityCounts[ObesityCategory.obesityType1] ?? 0) +
        (reportData.obesityCounts[ObesityCategory.obesityType2] ?? 0) +
        (reportData.obesityCounts[ObesityCategory.obesityType3] ?? 0);

    // Persentase normal untuk kesimpulan
    final normalPct = reportData.obesityPercentages[ObesityCategory.normalWeight] ?? 0.0;
    final totalScreened = reportData.totalScreenedPatients;

    // Kesimpulan otomatis
    String kesimpulanText;
    if (totalScreened == 0) {
      kesimpulanText = 'Belum terdapat data skrining pengguna yang tercatat pada periode ini.';
    } else {
      kesimpulanText =
          'Sebagian besar pengguna (${AdminReportService.formatPercentage(normalPct)}) berstatus gizi normal. $overCount pengguna berstatus overweight dan $obeCount pengguna obesitas tipe 1.';
    }

    // ----------------------------------------------------
    // HALAMAN 1 LAPORAN EKSTERNAL
    // ----------------------------------------------------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Kop Surat Resmi
              _buildHeaderKop(logoImage, 'Panel Administrator · Laporan Eksternal'),
              pw.SizedBox(height: 14),

              // Judul Tengah
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'LAPORAN',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText),
                    ),
                    pw.Text(
                      'HASIL SKRINING OBESITAS PENGGUNA APLIKASI OBESIGHT',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'PERIODE $periodRangeUpper',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // I. PENDAHULUAN
              _buildSectionTitle('I. PENDAHULUAN'),
              pw.SizedBox(height: 4),
              _buildNumberedParagraph(
                'A. Umum/Latar Belakang: ',
                'Skrining obesitas merupakan upaya deteksi dini status gizi berdasarkan Indeks Massa Tubuh (IMT) untuk mencegah penyakit akibat kelebihan berat badan.',
              ),
              pw.SizedBox(height: 4),
              _buildNumberedParagraph(
                'B. Landasan Data: ',
                'Data skrining pengguna aplikasi ObeSight yang tersimpan pada Cloud Firestore dan diolah pada halaman Laporan admin. Data diambil dari ${reportData.selectedPatientsCount} dari ${reportData.totalAvailablePatients} pengguna.',
              ),
              pw.SizedBox(height: 4),
              _buildNumberedParagraph(
                'C. Maksud dan Tujuan: ',
                'Menyajikan gambaran status gizi pengguna sebagai bahan pertimbangan tindak lanjut pihak terkait.',
              ),
              pw.SizedBox(height: 14),

              // II. KEGIATAN YANG DILAKSANAKAN
              _buildSectionTitle('II. KEGIATAN YANG DILAKSANAKAN'),
              pw.SizedBox(height: 4),
              pw.Text(
                'Melakukan rekapitulasi hasil skrining obesitas seluruh pengguna terdaftar pada periode laporan, yang meliputi distribusi IMT, tingkat risiko, dan perbandingan menurut jenis kelamin.',
                style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
              ),
              pw.SizedBox(height: 14),

              // III. HASIL YANG DICAPAI
              _buildSectionTitle('III. HASIL YANG DICAPAI'),
              pw.SizedBox(height: 4),
              pw.Text(
                '1. Rekapitulasi skrining',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Pada periode ini tercatat ${reportData.totalScreenings} kali skrining dari $totalScreened pengguna, dengan hasil terbaru per pengguna sebagai berikut.',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 6),

              // Tabel 1: Rekapitulasi skrining
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.8),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.5),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableHeaderRow(['Uraian', 'Jumlah']),
                  _buildTableRow(['Total skrining', '${reportData.totalScreenings}'], isRightAlign: true),
                  _buildTableRow(['Pengguna yang melakukan skrining', '$totalScreened'], isRightAlign: true),
                  _buildTableRow(['Insufficient Weight', '$insCount'], isRightAlign: true),
                  _buildTableRow(['Normal Weight', '$normCount'], isRightAlign: true),
                  _buildTableRow(['Overweight (Level 1 dan 2)', '$overCount'], isRightAlign: true),
                  _buildTableRow(['Obesitas (Tipe 1, 2, dan 3)', '$obeCount'], isRightAlign: true),
                ],
              ),

              pw.Spacer(),
              // Footer Halaman 1
              _buildPageFooter('Laporan Eksternal ObeSight', 'Halaman 1 dari 2'),
            ],
          );
        },
      ),
    );

    // ----------------------------------------------------
    // HALAMAN 2 LAPORAN EKSTERNAL
    // ----------------------------------------------------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          final pIns = reportData.perempuanInsufficient;
          final pNorm = reportData.perempuanNormal;
          final pOver = reportData.perempuanOverweight;
          final pObe = reportData.perempuanObesity;
          final pTotal = pIns + pNorm + pOver + pObe;

          final lIns = reportData.lakiLakiInsufficient;
          final lNorm = reportData.lakiLakiNormal;
          final lOver = reportData.lakiLakiOverweight;
          final lObe = reportData.lakiLakiObesity;
          final lTotal = lIns + lNorm + lOver + lObe;

          final totWithGender = pTotal + lTotal;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 2. Distribusi IMT menurut kategori
              pw.Text(
                '2. Distribusi IMT menurut kategori',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              _buildCategoryTable(reportData),
              pw.SizedBox(height: 10),

              // 3. Distribusi tingkat risiko
              pw.Text(
                '3. Distribusi tingkat risiko',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              _buildRiskTable(reportData),
              pw.SizedBox(height: 10),

              // 4. Hasil skrining menurut jenis kelamin
              pw.Text(
                '4. Hasil skrining menurut jenis kelamin',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.8),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                children: [
                  _buildTableHeaderRow(['Kategori', 'Perempuan', 'Laki-laki', 'Jumlah']),
                  _buildTableRow(['Insufficient', '$pIns', '$lIns', '${pIns + lIns}'], isRightAlign: true),
                  _buildTableRow(['Normal', '$pNorm', '$lNorm', '${pNorm + lNorm}'], isRightAlign: true),
                  _buildTableRow(['Overweight', '$pOver', '$lOver', '${pOver + lOver}'], isRightAlign: true),
                  _buildTableRow(['Obesitas', '$pObe', '$lObe', '${pObe + lObe}'], isRightAlign: true),
                  _buildTableRow(['Jumlah', '$pTotal', '$lTotal', '$totWithGender'], isRightAlign: true, isBold: true),
                ],
              ),
              pw.SizedBox(height: 6),

              // Batang bertumpuk jenis kelamin
              _buildGenderStackedBarRow(
                label: 'Perempuan ($pTotal)',
                normalCount: pNorm,
                overweightCount: pOver,
                obesityCount: pObe,
                insufficientCount: pIns,
              ),
              _buildGenderStackedBarRow(
                label: 'Laki-laki ($lTotal)',
                normalCount: lNorm,
                overweightCount: lOver,
                obesityCount: lObe,
                insufficientCount: lIns,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Hijau = Normal, kuning = Overweight, oranye = Obesitas, biru = Insufficient.',
                style: pw.TextStyle(fontSize: 7.5, color: mutedText),
              ),
              if (reportData.genderExcludedCount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  '* Catatan: Jenis kelamin dihitung dari ${reportData.perempuanCount + reportData.lakiLakiCount} pengguna yang datanya tersedia.',
                  style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: mutedText),
                ),
              ],
              pw.SizedBox(height: 12),

              // IV. KESIMPULAN DAN SARAN
              _buildSectionTitle('IV. KESIMPULAN DAN SARAN'),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 9),
                  children: [
                    pw.TextSpan(text: 'Kesimpulan: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: kesimpulanText),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 9),
                  children: [
                    pw.TextSpan(text: 'Saran: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(
                      text:
                          'Pengguna dengan kategori overweight dan obesitas dianjurkan memperoleh edukasi gizi dan aktivitas fisik, serta berkonsultasi ke fasilitas kesehatan terdekat.',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // V. PENUTUP
              _buildSectionTitle('V. PENUTUP'),
              pw.SizedBox(height: 3),
              pw.Text(
                'Demikian laporan ini disusun berdasarkan data pada sistem ObeSight sebagai bahan informasi dan tindak lanjut.',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 14),

              // Tanda Tangan Dinas
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Dikeluarkan di : ..........', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Pada tanggal : $printedDateStr', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('Admin ObeSight', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('(${adminName != null && adminName.isNotEmpty ? adminName : "nama admin"})', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              pw.Spacer(),
              // Footer Halaman 2
              _buildPageFooter('Laporan Eksternal ObeSight', 'Halaman 2 dari 2'),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 2. LAPORAN INTERNAL (Bagian 1-15, Sesuai Seleksi Checkbox)
  // ===========================================================================
  static void _buildInternalReport(
    pw.Document pdf,
    ReportData reportData,
    ReportConfig config,
    String? adminName,
    pw.MemoryImage? logoImage,
  ) {
    final periodRangeUpper = _formatPeriodUppercase(reportData.startDate, reportData.endDate);
    final periodRangeFormatted = AdminReportService.formatReportPeriodRange(
      reportData.startDate,
      reportData.endDate,
    );
    final printedDateStr = _formatIndonesianDate(DateTime.now());

    final selected = config.selectedSections;
    final hasPengguna = selected.contains(ReportSection.dataPengguna);
    final hasImt = selected.contains(ReportSection.dataImt);
    final hasSkrining = selected.contains(ReportSection.hasilSkrining);
    final hasTren = selected.contains(ReportSection.trenAktivitas);
    final hasAktivitas = selected.contains(ReportSection.aktivitasFisik);
    final hasNutrisi = selected.contains(ReportSection.makananMinuman);
    final hasTidur = selected.contains(ReportSection.polaTidur);
    final hasAnalisis = selected.contains(ReportSection.analisisKesimpulan);

    // Nomor urut bagian laporan dinamis tanpa loncatan
    int partNumber = 1;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(36),
        ),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              children: [
                _buildHeaderKop(logoImage, 'Panel Administrator · Laporan Internal · Rahasia'),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'LAPORAN INTERNAL',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText),
                      ),
                      pw.Text(
                        'PENGGUNAAN DAN HASIL SKRINING APLIKASI OBESIGHT',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'PERIODE $periodRangeUpper',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],
            );
          }
          return pw.Container(height: 0);
        },
        footer: (pw.Context context) {
          return _buildPageFooter(
            'Laporan Internal ObeSight',
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
          );
        },
        build: (pw.Context context) {
          final items = <pw.Widget>[];

          // ----------------------------------------------------
          // 1. Identitas dan periode laporan (Selalu Ikut)
          // ----------------------------------------------------
          items.add(
            _buildInternalSectionHeader('${partNumber++}. Identitas dan periode laporan'),
          );
          items.add(pw.SizedBox(height: 4));
          items.add(
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.6),
                1: pw.FlexColumnWidth(3),
              },
              children: [
                _buildTableRow(['Nama laporan', 'Laporan Internal ObeSight']),
                _buildTableRow(['Periode', '$periodRangeFormatted (${reportData.daysCount} hari)']),
                _buildTableRow(['Tanggal cetak', printedDateStr]),
                _buildTableRow(['Dicetak oleh', adminName ?? 'Admin ObeSight']),
                _buildTableRow(['Sumber data', 'Cloud Firestore']),
              ],
            ),
          );
          items.add(pw.SizedBox(height: 12));

          // ----------------------------------------------------
          // 2. Ringkasan umum pengguna (Selalu Ikut)
          // ----------------------------------------------------
          items.add(
            _buildInternalSectionHeader('${partNumber++}. Ringkasan umum pengguna'),
          );
          items.add(pw.SizedBox(height: 6));
          items.add(
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildMetricCard(
                    title: 'Total pengguna',
                    value: '${reportData.selectedPatientsCount}',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildMetricCard(
                    title: 'Pengguna baru',
                    value: '${reportData.newUsersCount}',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildMetricCard(
                    title: 'Total skrining',
                    value: '${reportData.totalScreenings}',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _buildMetricCard(
                    title: 'Rata-rata/hari',
                    value: reportData.formattedScreeningsPerDay,
                  ),
                ),
              ],
            ),
          );
          items.add(pw.SizedBox(height: 4));
          items.add(
            pw.Text(
              reportData.screeningsComparisonText.isNotEmpty
                  ? reportData.screeningsComparisonText
                  : 'Total skrining periode ini tercatat ${reportData.totalScreenings} kali.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          );
          items.add(pw.SizedBox(height: 14));

          // ----------------------------------------------------
          // 3. Pengguna menurut jenis kelamin dan usia (ReportSection.dataPengguna)
          // ----------------------------------------------------
          if (hasPengguna) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Pengguna menurut jenis kelamin dan usia'),
            );
            items.add(pw.SizedBox(height: 4));
            items.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Tabel Kiri: Jenis kelamin
                  pw.Expanded(
                    flex: 12,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Table(
                          border: pw.TableBorder.all(color: borderColor, width: 0.8),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(2),
                            1: pw.FlexColumnWidth(1),
                            2: pw.FlexColumnWidth(1),
                          },
                          children: [
                            _buildTableHeaderRow(['Jenis kelamin', 'Pasien', '%']),
                            _buildTableRow(['Perempuan', '${reportData.perempuanCount}', AdminReportService.formatPercentage(reportData.perempuanPercentage)], isRightAlign: true),
                            _buildTableRow(['Laki-laki', '${reportData.lakiLakiCount}', AdminReportService.formatPercentage(reportData.lakiLakiPercentage)], isRightAlign: true),
                            _buildTableRow(['Jumlah', '${reportData.perempuanCount + reportData.lakiLakiCount}', '100'], isRightAlign: true, isBold: true),
                          ],
                        ),
                        if (reportData.genderExcludedCount > 0) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '* Catatan: Jenis kelamin dihitung dari ${reportData.perempuanCount + reportData.lakiLakiCount} pengguna yang datanya tersedia.',
                            style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: mutedText),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Tabel Kanan: Kelompok Usia
                  pw.Expanded(
                    flex: 11,
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderColor, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1),
                      },
                      children: [
                        _buildTableHeaderRow(['Usia', 'Pasien']),
                        _buildTableRow(['<18', '${reportData.ageUnder18Count}'], isRightAlign: true),
                        _buildTableRow(['18-24', '${reportData.age18To24Count}'], isRightAlign: true),
                        _buildTableRow(['25-34', '${reportData.age25To34Count}'], isRightAlign: true),
                        _buildTableRow(['35-44', '${reportData.age35To44Count}'], isRightAlign: true),
                        _buildTableRow(['45-54', '${reportData.age45To54Count}'], isRightAlign: true),
                        _buildTableRow(['55+', '${reportData.age55PlusCount}'], isRightAlign: true),
                        _buildTableRow(['Tidak diketahui', '${reportData.ageUnknownCount}'], isRightAlign: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
            items.add(pw.SizedBox(height: 12));

            // ----------------------------------------------------
            // 4. Pertumbuhan pengguna baru (ReportSection.dataPengguna)
            // ----------------------------------------------------
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Pertumbuhan pengguna baru'),
            );
            items.add(pw.SizedBox(height: 6));
            items.add(_buildNewUserGrowthChart(reportData.newUserTrendPoints, reportData.newUsersCount));
            items.add(pw.SizedBox(height: 14));
          }

          // ----------------------------------------------------
          // 5. Data perhitungan IMT (ReportSection.dataImt)
          // ----------------------------------------------------
          if (hasImt) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Data perhitungan IMT'),
            );
            items.add(pw.SizedBox(height: 4));
            final avgBmiStr = reportData.avgBmi != null
                ? reportData.avgBmi!.toStringAsFixed(1).replaceAll('.', ',')
                : '-';
            final minBmiStr = reportData.minBmi != null
                ? reportData.minBmi!.toStringAsFixed(1).replaceAll('.', ',')
                : '-';
            final maxBmiStr = reportData.maxBmi != null
                ? reportData.maxBmi!.toStringAsFixed(1).replaceAll('.', ',')
                : '-';
            final avgWeightStr = reportData.avgWeight != null
                ? '${reportData.avgWeight!.toStringAsFixed(1).replaceAll('.', ',')} kg'
                : '-';
            final avgHeightStr = reportData.avgHeight != null
                ? '${reportData.avgHeight!.toStringAsFixed(0)} cm'
                : '-';

            items.add(
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.8),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  _buildTableHeaderRow(['Indikator', 'Nilai']),
                  _buildTableRow(['Rata-rata IMT', avgBmiStr], isRightAlign: true),
                  _buildTableRow(['IMT terendah / tertinggi', '$minBmiStr / $maxBmiStr'], isRightAlign: true),
                  _buildTableRow(['Rata-rata berat badan', avgWeightStr], isRightAlign: true),
                  _buildTableRow(['Rata-rata tinggi badan', avgHeightStr], isRightAlign: true),
                ],
              ),
            );
            items.add(pw.SizedBox(height: 12));

            // ----------------------------------------------------
            // 6. Distribusi kategori IMT (ReportSection.dataImt)
            // ----------------------------------------------------
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Distribusi kategori IMT'),
            );
            items.add(pw.SizedBox(height: 4));
            items.add(_buildCategoryTable(reportData));
            items.add(pw.SizedBox(height: 14));
          }

          // ----------------------------------------------------
          // 7 & 8. Rekapitulasi & Tingkat Risiko (ReportSection.hasilSkrining)
          // ----------------------------------------------------
          if (hasSkrining) {
            final ins = reportData.obesityCounts[ObesityCategory.insufficientWeight] ?? 0;
            final norm = reportData.obesityCounts[ObesityCategory.normalWeight] ?? 0;
            final over = (reportData.obesityCounts[ObesityCategory.overweightLevel1] ?? 0) +
                (reportData.obesityCounts[ObesityCategory.overweightLevel2] ?? 0);
            final obe = (reportData.obesityCounts[ObesityCategory.obesityType1] ?? 0) +
                (reportData.obesityCounts[ObesityCategory.obesityType2] ?? 0) +
                (reportData.obesityCounts[ObesityCategory.obesityType3] ?? 0);
            final totScreened = reportData.totalScreenedPatients;
            final obePct = totScreened > 0 ? (obe / totScreened) * 100.0 : 0.0;

            items.add(
              _buildInternalSectionHeader('${partNumber++}. Rekapitulasi hasil skrining obesitas'),
            );
            items.add(pw.SizedBox(height: 3));
            items.add(
              pw.Text(
                'Dari $totScreened pengguna: $ins insufficient, $norm normal, $over overweight, dan $obe obesitas. Terindikasi obesitas sebesar ${AdminReportService.formatPercentage(obePct)}.',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            );
            items.add(pw.SizedBox(height: 12));

            items.add(
              _buildInternalSectionHeader('${partNumber++}. Distribusi tingkat risiko'),
            );
            items.add(pw.SizedBox(height: 4));
            items.add(
              _buildRiskStackedBar(
                rendah: reportData.riskCounts['Rendah'] ?? 0,
                sedang: reportData.riskCounts['Sedang'] ?? 0,
                tinggi: reportData.riskCounts['Tinggi'] ?? 0,
                perluGizi: reportData.riskCounts['Perlu perhatian gizi'] ?? 0,
              ),
            );
            items.add(pw.SizedBox(height: 3));
            items.add(
              pw.Text(
                'Risiko rendah ${reportData.riskCounts['Rendah'] ?? 0} (${AdminReportService.formatPercentage(reportData.riskPercentages['Rendah'] ?? 0)}) · sedang ${reportData.riskCounts['Sedang'] ?? 0} (${AdminReportService.formatPercentage(reportData.riskPercentages['Sedang'] ?? 0)}) · tinggi ${reportData.riskCounts['Tinggi'] ?? 0} (${AdminReportService.formatPercentage(reportData.riskPercentages['Tinggi'] ?? 0)}).',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            );
            items.add(pw.SizedBox(height: 14));
          }

          // ----------------------------------------------------
          // 9. Tren aktivitas skrining (ReportSection.trenAktivitas)
          // ----------------------------------------------------
          if (hasTren) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Tren aktivitas skrining'),
            );
            items.add(pw.SizedBox(height: 4));
            items.add(_buildTrendLineChart(reportData.trendPoints, reportData.totalScreenings));
            items.add(pw.SizedBox(height: 14));
          }

          // ----------------------------------------------------
          // 10. Riwayat hasil skrining (ReportSection.hasilSkrining)
          // ----------------------------------------------------
          if (hasSkrining) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Riwayat hasil skrining'),
            );
            items.add(pw.SizedBox(height: 4));
            items.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Tabel Keaktifan
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderColor, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.5),
                        1: pw.FlexColumnWidth(1),
                      },
                      children: [
                        _buildTableHeaderRow(['Keaktifan', 'Pengguna']),
                        _buildTableRow(['Skrining 1 kali', '${reportData.screenings1TimeCount}'], isRightAlign: true),
                        _buildTableRow(['Skrining 2 kali', '${reportData.screenings2TimesCount}'], isRightAlign: true),
                        _buildTableRow(['3 kali atau lebih', '${reportData.screenings3PlusTimesCount}'], isRightAlign: true),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Tabel Perubahan Kondisi
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderColor, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.5),
                        1: pw.FlexColumnWidth(1),
                      },
                      children: [
                        _buildTableHeaderRow(['Perubahan kondisi*', 'Pengguna']),
                        _buildTableRow(['Membaik', '${reportData.conditionImprovedCount}'], isRightAlign: true),
                        _buildTableRow(['Tetap', '${reportData.conditionUnchangedCount}'], isRightAlign: true),
                        _buildTableRow(['Memburuk', '${reportData.conditionWorsenedCount}'], isRightAlign: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
            items.add(pw.SizedBox(height: 2));
            items.add(
              pw.Text(
                '*Hanya pengguna dengan minimal 2 skrining.',
                style: pw.TextStyle(fontSize: 7.5, color: mutedText, fontStyle: pw.FontStyle.italic),
              ),
            );
            items.add(pw.SizedBox(height: 14));
          }

          // ----------------------------------------------------
          // 11. Aktivitas fisik (ReportSection.aktivitasFisik)
          // ----------------------------------------------------
          if (hasAktivitas) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Aktivitas fisik'),
            );
            items.add(pw.SizedBox(height: 4));
            if (reportData.hasPhysicalActivityData) {
              items.add(
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.8),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                  },
                  children: [
                    _buildTableRow(['Pengguna yang mencatat aktivitas', '${reportData.physicalActivityUsersCount}'], isRightAlign: true),
                    _buildTableRow(['Total durasi aktivitas', '${reportData.physicalActivityTotalMinutes} menit'], isRightAlign: true),
                    _buildTableRow(['Aktivitas terbanyak', reportData.physicalActivityTopName], isRightAlign: true),
                  ],
                ),
              );
            } else {
              items.add(
                pw.Text('Tidak ada data pada periode ini', style: pw.TextStyle(fontSize: 8.5, color: mutedText, fontStyle: pw.FontStyle.italic)),
              );
            }
            items.add(pw.SizedBox(height: 12));
          }

          // ----------------------------------------------------
          // 12. Progress makanan dan minuman (ReportSection.makananMinuman)
          // ----------------------------------------------------
          if (hasNutrisi) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Progress makanan dan minuman'),
            );
            items.add(pw.SizedBox(height: 4));
            if (reportData.hasNutritionData) {
              items.add(
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.8),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                  },
                  children: [
                    _buildTableRow(['Pengguna yang mencatat asupan', '${reportData.nutritionUsersCount}'], isRightAlign: true),
                    _buildTableRow(['Rata-rata catatan makan per hari', '${reportData.nutritionAvgMealsPerDay.toStringAsFixed(1).replaceAll('.', ',')} kali'], isRightAlign: true),
                    _buildTableRow(['Rata-rata minum per hari', '${reportData.nutritionAvgWaterGlassesPerDay.toStringAsFixed(1).replaceAll('.', ',')} gelas'], isRightAlign: true),
                  ],
                ),
              );
            } else {
              items.add(
                pw.Text('Tidak ada data pada periode ini', style: pw.TextStyle(fontSize: 8.5, color: mutedText, fontStyle: pw.FontStyle.italic)),
              );
            }
            items.add(pw.SizedBox(height: 12));
          }

          // ----------------------------------------------------
          // 13. Pola tidur dan istirahat (ReportSection.polaTidur)
          // ----------------------------------------------------
          if (hasTidur) {
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Pola tidur dan istirahat'),
            );
            items.add(pw.SizedBox(height: 4));
            if (reportData.hasSleepData) {
              final h = reportData.sleepAvgDurationMinutes ~/ 60;
              final m = reportData.sleepAvgDurationMinutes % 60;
              items.add(
                pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.8),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                  },
                  children: [
                    _buildTableRow(['Rata-rata durasi tidur', '$h jam $m menit'], isRightAlign: true),
                    _buildTableRow(['Pengguna tidur kurang dari 7 jam', AdminReportService.formatPercentage(reportData.sleepUnder7HoursPct)], isRightAlign: true),
                    _buildTableRow(['Pengguna dengan pengingat istirahat aktif', '${reportData.sleepActiveRestReminderCount}'], isRightAlign: true),
                  ],
                ),
              );
            } else {
              items.add(
                pw.Text('Tidak ada data pada periode ini', style: pw.TextStyle(fontSize: 8.5, color: mutedText, fontStyle: pw.FontStyle.italic)),
              );
            }
            items.add(pw.SizedBox(height: 2));
            items.add(
              pw.Text(
                'Bagian 11 sampai 13 hanya dicetak jika datanya tersedia di Firestore.',
                style: pw.TextStyle(fontSize: 7.5, color: mutedText, fontStyle: pw.FontStyle.italic),
              ),
            );
            items.add(pw.SizedBox(height: 14));
          }

          // ----------------------------------------------------
          // 14 & 15. Analisis, Kesimpulan, dan Rekomendasi (ReportSection.analisisKesimpulan)
          // ----------------------------------------------------
          if (hasAnalisis) {
            // Sintesis teks analisis otomatis berbasis angka
            final normPct = reportData.obesityPercentages[ObesityCategory.normalWeight] ?? 0.0;
            final totalP = reportData.selectedPatientsCount;
            final screenedP = reportData.totalScreenedPatients;

            String peakTrendStr = 'periode pengamatan';
            int maxTrendCount = 0;
            for (final tp in reportData.trendPoints) {
              if (tp.count > maxTrendCount) {
                maxTrendCount = tp.count;
                peakTrendStr = tp.label.toLowerCase();
              }
            }

            final sleepSuffix = reportData.hasSleepData && reportData.sleepAvgDurationMinutes < 420
                ? ', namun rata-rata tidur masih di bawah 7 jam.'
                : '.';
            final analisisText =
                'Seluruh pengguna terdaftar ($screenedP dari $totalP pasien) sudah melakukan skrining, dan sebagian di antaranya mengulang skrining. Aktivitas skrining memuncak pada $peakTrendStr. Mayoritas pengguna berstatus normal (${AdminReportService.formatPercentage(normPct)})$sleepSuffix';

            items.add(
              _buildInternalSectionHeader('${partNumber++}. Analisis hasil laporan'),
            );
            items.add(pw.SizedBox(height: 3));
            items.add(
              pw.Text(analisisText, style: const pw.TextStyle(fontSize: 8.5, height: 1.35)),
            );
            items.add(pw.SizedBox(height: 12));

            // Kesimpulan & Rekomendasi
            items.add(
              _buildInternalSectionHeader('${partNumber++}. Kesimpulan dan rekomendasi'),
            );
            items.add(pw.SizedBox(height: 3));
            items.add(
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 8.5),
                  children: [
                    pw.TextSpan(text: 'Kesimpulan: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                      text:
                          'Penggunaan aplikasi meningkat dibanding periode sebelumnya dan ${AdminReportService.formatPercentage(normPct)} pengguna berstatus gizi normal.',
                    ),
                  ],
                ),
              ),
            );
            items.add(pw.SizedBox(height: 4));
            items.add(
              pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 8.5, height: 1.35),
                  children: [
                    pw.TextSpan(text: 'Rekomendasi: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(
                      text:
                          '(1) mendorong pengguna meningkatkan frekuensi skrining ulang; '
                          '(2) menindaklanjuti pengguna overweight dan obesitas dengan konten edukasi; '
                          '(3) menambah edukasi kualitas tidur; '
                          '(4) melengkapi data jenis kelamin dan usia pengguna.',
                    ),
                  ],
                ),
              ),
            );
            items.add(pw.SizedBox(height: 18));

            // Tanda Tangan Internal
            items.add(
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Dibuat di : ..........', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Pada tanggal : $printedDateStr', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('Admin ObeSight', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('(${adminName != null && adminName.isNotEmpty ? adminName : "nama admin"})', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          return items;
        },
      ),
    );
  }

  // ===========================================================================
  // HELPER KOMPONEN & WIDGET PDF
  // ===========================================================================

  static pw.Widget _buildHeaderKop(pw.MemoryImage? logoImage, String subtitle) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logoImage),
              )
            else
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: primaryColor, width: 2),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'OBE\nSIGHT',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'APLIKASI SKRINING OBESITAS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: darkText,
                      letterSpacing: 1.1,
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'OBESIGHT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(fontSize: 8.5, color: mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 2.2,
          decoration: pw.BoxDecoration(
            color: darkText,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1)),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: darkText,
      ),
    );
  }

  static pw.Widget _buildInternalSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 9.5,
        fontWeight: pw.FontWeight.bold,
        color: darkText,
      ),
    );
  }

  static pw.Widget _buildNumberedParagraph(String boldLabel, String text) {
    return pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 9, height: 1.35),
        children: [
          pw.TextSpan(text: boldLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: text),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableHeaderRow(List<String> titles) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: tableHeaderBg),
      children: titles.map((t) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(
            t,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkText),
          ),
        );
      }).toList(),
    );
  }

  static pw.TableRow _buildTableRow(
    List<String> values, {
    bool isRightAlign = false,
    bool isBold = false,
  }) {
    return pw.TableRow(
      children: values.asMap().entries.map((entry) {
        final idx = entry.key;
        final val = entry.value;
        final alignRight = isRightAlign && idx > 0;
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          child: pw.Text(
            val,
            textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: darkText,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildCategoryTable(ReportData reportData) {
    final configs = [
      (ObesityCategory.insufficientWeight, 'Insufficient Weight', colorInsufficient),
      (ObesityCategory.normalWeight, 'Normal Weight', colorNormal),
      (ObesityCategory.overweightLevel1, 'Overweight Level 1', colorOverweight1),
      (ObesityCategory.overweightLevel2, 'Overweight Level 2', colorOverweight2),
      (ObesityCategory.obesityType1, 'Obesity Type 1', colorObesity1),
      (ObesityCategory.obesityType2, 'Obesity Type 2', colorObesity2),
      (ObesityCategory.obesityType3, 'Obesity Type 3', colorObesity3),
    ];

    final rows = <pw.TableRow>[
      _buildTableHeaderRow(['Kategori', 'Orang', '%', 'Proporsi']),
    ];

    for (final cfg in configs) {
      final count = reportData.obesityCounts[cfg.$1] ?? 0;
      final pct = reportData.obesityPercentages[cfg.$1] ?? 0.0;
      final barWidth = (pct / 100.0) * 140.0;

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 7,
                    height: 7,
                    margin: const pw.EdgeInsets.only(right: 6),
                    color: cfg.$3,
                  ),
                  pw.Text(cfg.$2, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: pw.Text('$count', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: pw.Text(AdminReportService.formatPercentage(pct).replaceAll('%', ''), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: barWidth > 0
                    ? pw.Container(
                        width: barWidth,
                        height: 6,
                        decoration: pw.BoxDecoration(
                          color: cfg.$3,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1.5)),
                        ),
                      )
                    : pw.Container(height: 6),
              ),
            ),
          ],
        ),
      );
    }

    // Baris Jumlah
    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: pw.Text('Jumlah', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: pw.Text('${reportData.totalScreenedPatients}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: pw.Text('100', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: pw.Container(),
          ),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2.6),
      },
      children: rows,
    );
  }

  static pw.Widget _buildRiskTable(ReportData reportData) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        _buildTableHeaderRow(['Tingkat risiko', 'Orang', '%']),
        _buildTableRow([
          'Rendah (Normal Weight)',
          '${reportData.riskCounts['Rendah'] ?? 0}',
          AdminReportService.formatPercentage(reportData.riskPercentages['Rendah'] ?? 0).replaceAll('%', ''),
        ], isRightAlign: true),
        _buildTableRow([
          'Sedang (Overweight)',
          '${reportData.riskCounts['Sedang'] ?? 0}',
          AdminReportService.formatPercentage(reportData.riskPercentages['Sedang'] ?? 0).replaceAll('%', ''),
        ], isRightAlign: true),
        _buildTableRow([
          'Tinggi (Obesity)',
          '${reportData.riskCounts['Tinggi'] ?? 0}',
          AdminReportService.formatPercentage(reportData.riskPercentages['Tinggi'] ?? 0).replaceAll('%', ''),
        ], isRightAlign: true),
        _buildTableRow([
          'Perlu perhatian gizi (Insufficient)',
          '${reportData.riskCounts['Perlu perhatian gizi'] ?? 0}',
          AdminReportService.formatPercentage(reportData.riskPercentages['Perlu perhatian gizi'] ?? 0).replaceAll('%', ''),
        ], isRightAlign: true),
      ],
    );
  }

  static pw.Widget _buildGenderStackedBarRow({
    required String label,
    required int normalCount,
    required int overweightCount,
    required int obesityCount,
    required int insufficientCount,
  }) {
    final total = normalCount + overweightCount + obesityCount + insufficientCount;
    if (total == 0) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 85, child: pw.Text('$label (0)', style: const pw.TextStyle(fontSize: 8))),
            pw.Expanded(
              child: pw.Container(
                height: 8,
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Expanded(
            child: pw.ClipRRect(
              horizontalRadius: 1.5,
              verticalRadius: 1.5,
              child: pw.Container(
                height: 8,
                child: pw.Row(
                  children: [
                    if (normalCount > 0)
                      pw.Expanded(
                        flex: normalCount,
                        child: pw.Container(color: colorNormal),
                      ),
                    if (overweightCount > 0)
                      pw.Expanded(
                        flex: overweightCount,
                        child: pw.Container(color: colorOverweight1),
                      ),
                    if (obesityCount > 0)
                      pw.Expanded(
                        flex: obesityCount,
                        child: pw.Container(color: colorObesity1),
                      ),
                    if (insufficientCount > 0)
                      pw.Expanded(
                        flex: insufficientCount,
                        child: pw.Container(color: colorInsufficient),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricCard({required String title, required String value}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: secondaryBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: borderColor, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText)),
        ],
      ),
    );
  }

  static pw.Widget _buildRiskStackedBar({
    required int rendah,
    required int sedang,
    required int tinggi,
    required int perluGizi,
  }) {
    final total = rendah + sedang + tinggi + perluGizi;
    if (total == 0) {
      return pw.Container(
        height: 8,
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      );
    }

    return pw.ClipRRect(
      horizontalRadius: 2,
      verticalRadius: 2,
      child: pw.Container(
        height: 8,
        child: pw.Row(
          children: [
            if (rendah > 0)
              pw.Expanded(
                flex: rendah,
                child: pw.Container(color: colorNormal),
              ),
            if (sedang > 0)
              pw.Expanded(
                flex: sedang,
                child: pw.Container(color: colorOverweight1),
              ),
            if (tinggi > 0)
              pw.Expanded(
                flex: tinggi,
                child: pw.Container(color: colorObesity2),
              ),
            if (perluGizi > 0)
              pw.Expanded(
                flex: perluGizi,
                child: pw.Container(color: colorInsufficient),
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildNewUserGrowthChart(List<ScreeningTrendPoint> points, int totalNewUsers) {
    if (points.isEmpty) {
      return pw.Text(
        'Tidak ada data pertumbuhan pengguna baru pada periode ini.',
        style: pw.TextStyle(fontSize: 8, color: mutedText, fontStyle: pw.FontStyle.italic),
      );
    }

    int maxVal = 0;
    for (final p in points) {
      if (p.count > maxVal) maxVal = p.count;
    }
    if (maxVal == 0) maxVal = 1;

    final softGreen = PdfColor.fromHex('#86EFAC');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: points.map((p) {
            final barH = (p.count / maxVal) * 45.0;
            final isMax = p.count == maxVal && p.count > 0;
            return pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 44,
                  height: barH > 3 ? barH : 3,
                  decoration: pw.BoxDecoration(
                    color: isMax ? primaryColor : softGreen,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(p.label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                pw.Text('${p.count}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
              ],
            );
          }).toList(),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Jumlah per minggu = $totalNewUsers pengguna baru.',
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildTrendLineChart(List<ScreeningTrendPoint> points, int totalScreenings) {
    if (points.isEmpty) {
      return pw.Container(
        height: 60,
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Tidak ada data tren skrining pada periode ini.',
          style: pw.TextStyle(fontSize: 8, color: mutedText, fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    int maxVal = 0;
    for (final p in points) {
      if (p.count > maxVal) maxVal = p.count;
    }
    if (maxVal == 0) maxVal = 4;
    if (maxVal % 2 != 0) maxVal += 1;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Y Axis labels
            pw.Container(
              width: 18,
              height: 70,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('$maxVal', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  pw.Text('${maxVal ~/ 2}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  pw.Text('0', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.SizedBox(width: 6),
            // CustomPaint untuk grid, area, garis, dan titik bulat
            pw.Expanded(
              child: pw.CustomPaint(
                size: const PdfPoint(400, 70),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  const padBottom = 6.0;
                  const padTop = 6.0;
                  final plotHeight = size.y - padBottom - padTop;
                  final n = points.length;
                  final stepX = n > 1 ? size.x / (n - 1) : size.x;

                  // 1. Grid lines
                  canvas.setStrokeColor(PdfColors.grey200);
                  canvas.setLineWidth(0.5);
                  canvas.drawLine(0, padBottom, size.x, padBottom);
                  canvas.drawLine(0, padBottom + plotHeight / 2, size.x, padBottom + plotHeight / 2);
                  canvas.drawLine(0, padBottom + plotHeight, size.x, padBottom + plotHeight);
                  canvas.strokePath();

                  final coords = <PdfPoint>[];
                  for (int i = 0; i < n; i++) {
                    final x = n > 1 ? i * stepX : size.x / 2;
                    final y = padBottom + (points[i].count / maxVal) * plotHeight;
                    coords.add(PdfPoint(x, y));
                  }

                  // 2. Area hijau transparan di bawah garis
                  canvas.setFillColor(secondaryBg);
                  canvas.moveTo(coords[0].x, padBottom);
                  for (int i = 0; i < n; i++) {
                    canvas.lineTo(coords[i].x, coords[i].y);
                  }
                  canvas.lineTo(coords[n - 1].x, padBottom);
                  canvas.closePath();
                  canvas.fillPath();

                  // 3. Garis hijau tema
                  canvas.setStrokeColor(primaryColor);
                  canvas.setLineWidth(1.6);
                  canvas.moveTo(coords[0].x, coords[0].y);
                  for (int i = 1; i < n; i++) {
                    canvas.lineTo(coords[i].x, coords[i].y);
                  }
                  canvas.strokePath();

                  // 4. Titik bulat pada tiap data
                  for (int i = 0; i < n; i++) {
                    canvas.setFillColor(primaryColor);
                    canvas.drawEllipse(coords[i].x, coords[i].y, 2.5, 2.5);
                    canvas.fillPath();
                    canvas.setFillColor(PdfColors.white);
                    canvas.drawEllipse(coords[i].x, coords[i].y, 1.0, 1.0);
                    canvas.fillPath();
                  }
                },
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        // Sumbu X
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 24),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: points.map((p) {
              return pw.Text(p.label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700));
            }).toList(),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Jumlah titik ${points.map((p) => p.count).join('+')} = $totalScreenings = total skrining.',
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildPageFooter(String title, String pageText) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(pageText, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static String _formatPeriodUppercase(DateTime start, DateTime end) {
    const monthsUpper = [
      'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
    final mStart = monthsUpper[start.month - 1];
    final mEnd = monthsUpper[end.month - 1];
    if (start.year == end.year) {
      return '${start.day} $mStart - ${end.day} $mEnd ${end.year}';
    }
    return '${start.day} $mStart ${start.year} - ${end.day} $mEnd ${end.year}';
  }

  static String _formatIndonesianDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
