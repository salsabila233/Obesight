import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fungsi parser untuk memformat teks tampilan akhir (Pratinjau & Detail Artikel):
/// - **teks tebal**, <b>teks</b>, <strong>teks</strong> -> Bold
/// - *teks miring*, _teks_, <i>teks</i>, <em>teks</em> -> Italic
/// - <u>teks bergaris bawah</u>, <ins>teks</ins> -> Underline
/// Mendukung format bersarang (nested) seperti **<u>teks tebal bergaris</u>**
List<InlineSpan> parseFormattedSpans(String text, TextStyle baseStyle) {
  if (text.isEmpty) return [TextSpan(text: '', style: baseStyle)];

  final spans = <InlineSpan>[];
  final regex = RegExp(
    r'(\*\*(?:[^*]+)\*\*|<b>(?:.+?)<\/b>|<strong>(?:.+?)<\/strong>|'
    r'\*(?:[^*]+)\*|_(?:[^_]+)_|<i>(?:.+?)<\/i>|<em>(?:.+?)<\/em>|'
    r'<u>(?:[\s\S]*?)<\/u>|<ins>(?:[\s\S]*?)<\/ins>)',
    caseSensitive: false,
  );
  int lastIndex = 0;

  for (final match in regex.allMatches(text)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, match.start),
        style: baseStyle,
      ));
    }

    final raw = match.group(0)!;
    final lower = raw.toLowerCase();

    if (raw.startsWith('**') && raw.endsWith('**') && raw.length >= 4) {
      final inner = raw.substring(2, raw.length - 2);
      spans.add(TextSpan(
        children: parseFormattedSpans(
          inner,
          baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      ));
    } else if ((lower.startsWith('<b>') && lower.endsWith('</b>')) ||
        (lower.startsWith('<strong>') && lower.endsWith('</strong>'))) {
      final tagLen = lower.startsWith('<b>') ? 3 : 8;
      final closeLen = lower.startsWith('<b>') ? 4 : 9;
      final inner = raw.substring(tagLen, raw.length - closeLen);
      spans.add(TextSpan(
        children: parseFormattedSpans(
          inner,
          baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      ));
    } else if ((lower.startsWith('<u>') && lower.endsWith('</u>')) ||
        (lower.startsWith('<ins>') && lower.endsWith('</ins>'))) {
      final tagLen = lower.startsWith('<u>') ? 3 : 5;
      final closeLen = lower.startsWith('<u>') ? 4 : 6;
      final inner = raw.substring(tagLen, raw.length - closeLen);
      spans.add(TextSpan(
        children: parseFormattedSpans(
          inner,
          baseStyle.copyWith(decoration: TextDecoration.underline),
        ),
      ));
    } else if ((raw.startsWith('*') && raw.endsWith('*') && raw.length >= 2) ||
        (raw.startsWith('_') && raw.endsWith('_') && raw.length >= 2)) {
      final inner = raw.substring(1, raw.length - 1);
      spans.add(TextSpan(
        children: parseFormattedSpans(
          inner,
          baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      ));
    } else if ((lower.startsWith('<i>') && lower.endsWith('</i>')) ||
        (lower.startsWith('<em>') && lower.endsWith('</em>'))) {
      final tagLen = lower.startsWith('<i>') ? 3 : 4;
      final closeLen = lower.startsWith('<i>') ? 4 : 5;
      final inner = raw.substring(tagLen, raw.length - closeLen);
      spans.add(TextSpan(
        children: parseFormattedSpans(
          inner,
          baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      ));
    }

    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: baseStyle,
    ));
  }

  return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
}

/// Fungsi syntax highlighting khusus untuk `TextEditingController.buildTextSpan` di editor admin.
/// PENTING: Plain-text dari TextSpan yang dikembalikan dijamin 100% SAMA PERSIS
/// dengan `text` asli, sehingga Flutter tidak akan error `toPlainText() == text` dan kursor
/// tidak akan lompat / rusak.
List<InlineSpan> buildHighlightedEditorSpans(
  String text,
  TextStyle baseStyle, {
  bool isDark = false,
}) {
  if (text.isEmpty) return [TextSpan(text: '', style: baseStyle)];

  final syntaxStyle = baseStyle.copyWith(
    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    fontWeight: FontWeight.w400,
  );

  final spans = <InlineSpan>[];
  final pattern = RegExp(
    r'(\*\*(?:[^*]+)\*\*)|'
    r'(\*(?:[^*]+)\*|_(?:[^_]+)_)|'
    r'(<u>[\s\S]*?<\/u>|<ins>[\s\S]*?<\/ins>)|'
    r'(<b>[\s\S]*?<\/b>|<strong>[\s\S]*?<\/strong>)|'
    r'(<i>[\s\S]*?<\/i>|<em>[\s\S]*?<\/em>)|'
    r'(^|\n)([•\-]|\d+\.)(\s+)',
    multiLine: true,
    caseSensitive: false,
  );

  int lastIndex = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, match.start),
        style: baseStyle,
      ));
    }

    final boldMarkdown = match.group(1);
    final italicMarkdown = match.group(2);
    final underlineTag = match.group(3);
    final boldTag = match.group(4);
    final italicTag = match.group(5);

    if (boldMarkdown != null && boldMarkdown.length >= 4) {
      final inner = boldMarkdown.substring(2, boldMarkdown.length - 2);
      spans.add(TextSpan(text: '**', style: syntaxStyle));
      spans.add(TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
        ),
      ));
      spans.add(TextSpan(text: '**', style: syntaxStyle));
    } else if (italicMarkdown != null && italicMarkdown.length >= 2) {
      final marker = italicMarkdown[0];
      final inner = italicMarkdown.substring(1, italicMarkdown.length - 1);
      spans.add(TextSpan(text: marker, style: syntaxStyle));
      spans.add(TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
        ),
      ));
      spans.add(TextSpan(text: marker, style: syntaxStyle));
    } else if (underlineTag != null) {
      final isU = underlineTag.toLowerCase().startsWith('<u>');
      final openTag = isU ? underlineTag.substring(0, 3) : underlineTag.substring(0, 5);
      final closeTag = isU
          ? underlineTag.substring(underlineTag.length - 4)
          : underlineTag.substring(underlineTag.length - 6);
      final inner = underlineTag.substring(openTag.length, underlineTag.length - closeTag.length);
      spans.add(TextSpan(text: openTag, style: syntaxStyle));
      spans.add(TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: isDark ? const Color(0xFFFACC15) : const Color(0xFFD97706),
          color: isDark ? const Color(0xFFFEF08A) : const Color(0xFFB45309),
        ),
      ));
      spans.add(TextSpan(text: closeTag, style: syntaxStyle));
    } else if (boldTag != null) {
      final isB = boldTag.toLowerCase().startsWith('<b>');
      final openTag = isB ? boldTag.substring(0, 3) : boldTag.substring(0, 8);
      final closeTag = isB
          ? boldTag.substring(boldTag.length - 4)
          : boldTag.substring(boldTag.length - 9);
      final inner = boldTag.substring(openTag.length, boldTag.length - closeTag.length);
      spans.add(TextSpan(text: openTag, style: syntaxStyle));
      spans.add(TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
        ),
      ));
      spans.add(TextSpan(text: closeTag, style: syntaxStyle));
    } else if (italicTag != null) {
      final isI = italicTag.toLowerCase().startsWith('<i>');
      final openTag = isI ? italicTag.substring(0, 3) : italicTag.substring(0, 4);
      final closeTag = isI
          ? italicTag.substring(italicTag.length - 4)
          : italicTag.substring(italicTag.length - 5);
      final inner = italicTag.substring(openTag.length, italicTag.length - closeTag.length);
      spans.add(TextSpan(text: openTag, style: syntaxStyle));
      spans.add(TextSpan(
        text: inner,
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
        ),
      ));
      spans.add(TextSpan(text: closeTag, style: syntaxStyle));
    } else {
      final newline = match.group(6) ?? '';
      final symbol = match.group(7) ?? '';
      final space = match.group(8) ?? '';
      if (newline.isNotEmpty) {
        spans.add(TextSpan(text: newline, style: baseStyle));
      }
      spans.add(TextSpan(
        text: symbol,
        style: baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF388E6B),
        ),
      ));
      spans.add(TextSpan(text: space, style: baseStyle));
    }

    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: baseStyle,
    ));
  }

  return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
}

/// Widget untuk merender konten artikel dengan dukungan:
/// 1. Pemisahan paragraf yang rapi (\n\n)
/// 2. Format teks kaya: Bold (**teks**), Italic (*teks*), Underline (<u>teks</u>)
/// 3. Daftar penomoran rapi (1. , 2. ) dengan badge angka hijau
/// 4. Daftar poin bulat (• atau - ) dengan lingkaran bullet hijau
class FormattedArticleContent extends StatelessWidget {
  final String content;
  final bool isDark;
  final double fontSize;
  final double lineHeight;

  const FormattedArticleContent({
    super.key,
    required this.content,
    this.isDark = false,
    this.fontSize = 14,
    this.lineHeight = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: fontSize,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
      height: lineHeight,
    );

    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      return Text(
        'Belum ada konten artikel.',
        style: baseStyle.copyWith(color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
      );
    }

    // Pisahkan konten menjadi beberapa blok paragraf
    final paragraphs = cleanContent.split('\n\n');
    final widgets = <Widget>[];

    for (final paragraph in paragraphs) {
      final trimmedPara = paragraph.trim();
      if (trimmedPara.isEmpty) continue;

      // Cek apakah blok ini berisi daftar baris (poin atau nomor)
      final lines = trimmedPara.split('\n');
      final hasListItems = lines.length > 1 && lines.any((l) => _isListItem(l));

      if (hasListItems) {
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty) continue;
          widgets.add(_buildLineWidget(trimmedLine, baseStyle));
        }
        widgets.add(const SizedBox(height: 12));
      } else if (_isListItem(trimmedPara)) {
        widgets.add(_buildLineWidget(trimmedPara, baseStyle));
        widgets.add(const SizedBox(height: 8));
      } else {
        // Paragraf biasa
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(
              TextSpan(children: parseFormattedSpans(trimmedPara, baseStyle)),
              style: baseStyle,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isListItem(String line) {
    final l = line.trim();
    return l.startsWith('•') ||
        l.startsWith('- ') ||
        RegExp(r'^\d+\.\s*').hasMatch(l);
  }

  Widget _buildLineWidget(String line, TextStyle baseStyle) {
    final l = line.trim();

    // 1. Daftar Bernomor: e.g. "1. Banyak mengkonsumsi..."
    final numberMatch = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(l);
    if (numberMatch != null) {
      final numStr = numberMatch.group(1)!;
      final restText = numberMatch.group(2)!;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF388E6B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  numStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D5A),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: parseFormattedSpans(restText, baseStyle)),
                style: baseStyle,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Daftar Berpoin: e.g. "• Kurang makan sayur..." atau "- Kurang makan..."
    if (l.startsWith('•') || l.startsWith('- ')) {
      final restText = l.startsWith('•') ? l.substring(1).trim() : l.substring(2).trim();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, right: 10, left: 6),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF388E6B),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: parseFormattedSpans(restText, baseStyle)),
                style: baseStyle,
              ),
            ),
          ],
        ),
      );
    }

    // Baris biasa di dalam blok multiline
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(children: parseFormattedSpans(l, baseStyle)),
        style: baseStyle,
      ),
    );
  }
}
