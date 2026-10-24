import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';
import '../../widgets/article_thumbnail_image.dart';
import '../../widgets/formatted_article_content.dart';

class AdminAddArticleScreen extends StatefulWidget {
  final ArticleModel? initialArticle;

  const AdminAddArticleScreen({
    super.key,
    this.initialArticle,
  });

  @override
  State<AdminAddArticleScreen> createState() => _AdminAddArticleScreenState();
}

class RichArticleTextController extends TextEditingController {
  bool isDark;

  RichArticleTextController({this.isDark = false, super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = style ??
        GoogleFonts.poppins(
          fontSize: 13.5,
          height: 1.6,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        );

    // Menggunakan buildHighlightedEditorSpans yang mempertahankan 100% karakter asli
    // agar toPlainText() == text tetap terpenuhi dan tidak memicu crash di layout/cursor.
    return TextSpan(
      children: buildHighlightedEditorSpans(text, effectiveStyle, isDark: isDark),
    );
  }
}

class _AdminAddArticleScreenState extends State<AdminAddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _snippetController = TextEditingController();
  late final RichArticleTextController _contentController;
  final _contentFocusNode = FocusNode();
  TextSelection _lastContentSelection = const TextSelection.collapsed(offset: 0);
  final List<TextEditingController> _takeawayControllers = [];

  final _articleService = ArticleService();
  final _imagePicker = ImagePicker();

  String? _pickedImagePath;
  String? _selectedAssetPath;
  String _selectedCategory = 'Edukasi Kesehatan';
  bool _isPublished = true;
  bool _isLoading = false;
  bool _isPreviewMode = false;

  final List<String> _categories = [
    'Edukasi Kesehatan',
    'Pola Makan',
    'Nutrisi & Gizi',
    'Aktivitas Fisik',
    'Gaya Hidup',
  ];

  @override
  void initState() {
    super.initState();
    _contentController = RichArticleTextController(
      text: widget.initialArticle?.content ?? '',
    );
    _contentController.addListener(_onContentSelectionChanged);

    if (widget.initialArticle != null) {
      final a = widget.initialArticle!;
      _titleController.text = a.title;
      _snippetController.text = a.snippet;
      _isPublished = a.isPublished;
      _selectedCategory = _categories.contains(a.category) ? a.category : 'Edukasi Kesehatan';
      if (a.imageUrl != null && a.imageUrl!.isNotEmpty) {
        _pickedImagePath = a.imageUrl;
      } else {
        _selectedAssetPath = a.imageAsset;
      }
      if (a.takeaways.isNotEmpty) {
        for (final t in a.takeaways) {
          _takeawayControllers.add(TextEditingController(text: t));
        }
      } else {
        _takeawayControllers.add(TextEditingController());
      }
    } else {
      _selectedAssetPath = 'assets/articles/article_5_pola_makan.jpg';
      // 2 kolom default poin penting
      _takeawayControllers.add(TextEditingController(
        text: 'Makan dengan jadwal teratur mencegah lonjakan rasa lapar mendadak.',
      ));
      _takeawayControllers.add(TextEditingController(
        text: 'Kendalikan porsi makan dengan piring gizi seimbang.',
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _snippetController.dispose();
    _contentController.removeListener(_onContentSelectionChanged);
    _contentController.dispose();
    _contentFocusNode.dispose();
    for (final c in _takeawayControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onContentSelectionChanged() {
    if (_contentController.selection.isValid && _contentController.selection.start >= 0) {
      _lastContentSelection = _contentController.selection;
    }
  }

  // --- Dynamic Takeaway Items Handler ---

  void _addTakeawayField([String initialText = '']) {
    setState(() {
      _takeawayControllers.add(TextEditingController(text: initialText));
    });
  }

  void _removeTakeawayField(int index) {
    if (_takeawayControllers.length <= 1) {
      _takeawayControllers[0].clear();
      setState(() {});
      return;
    }
    setState(() {
      final removed = _takeawayControllers.removeAt(index);
      removed.dispose();
    });
  }

  // --- Formatting Helpers for Content Toolbar ---

  void _applyFormatting(String prefix, String suffix, {String placeholder = 'teks'}) {
    final currentSelection = _contentController.selection;
    final selection = currentSelection.isValid ? currentSelection : _lastContentSelection;
    final text = _contentController.text;

    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      final newText = '$text$prefix$placeholder$suffix';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: text.length + prefix.length,
          extentOffset: text.length + prefix.length + placeholder.length,
        ),
      );
      _contentFocusNode.requestFocus();
      setState(() {});
      return;
    }

    if (selection.isCollapsed) {
      final pos = selection.start.clamp(0, text.length);
      final newText = text.replaceRange(pos, pos, '$prefix$placeholder$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: pos + prefix.length,
          extentOffset: pos + prefix.length + placeholder.length,
        ),
      );
    } else {
      final start = selection.start.clamp(0, text.length);
      final end = selection.end.clamp(0, text.length);
      final selectedText = text.substring(start, end);

      // Fitur pintar: Toggle off jika teks yang diblok sudah memiliki format ini
      if (selectedText.startsWith(prefix) &&
          selectedText.endsWith(suffix) &&
          selectedText.length >= prefix.length + suffix.length) {
        final unwrapped = selectedText.substring(prefix.length, selectedText.length - suffix.length);
        final newText = text.replaceRange(start, end, unwrapped);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + unwrapped.length,
          ),
        );
      } else {
        final formatted = '$prefix$selectedText$suffix';
        final newText = text.replaceRange(start, end, formatted);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start + prefix.length,
            extentOffset: start + prefix.length + selectedText.length,
          ),
        );
      }
    }

    _lastContentSelection = _contentController.selection;
    _contentFocusNode.requestFocus();
    setState(() {});
  }

  void _insertLinePrefix(String linePrefix) {
    final currentSelection = _contentController.selection;
    final selection = currentSelection.isValid ? currentSelection : _lastContentSelection;
    final text = _contentController.text;
    final insertPos = (selection.isValid && selection.start >= 0)
        ? selection.start.clamp(0, text.length)
        : text.length;

    final needNewline = insertPos > 0 && !text.substring(0, insertPos).endsWith('\n');
    final insertion = needNewline ? '\n$linePrefix ' : '$linePrefix ';

    final newText = text.replaceRange(insertPos, insertPos, insertion);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + insertion.length),
    );

    _lastContentSelection = _contentController.selection;
    _contentFocusNode.requestFocus();
    setState(() {});
  }

  void _insertParagraphBreak() {
    final currentSelection = _contentController.selection;
    final selection = currentSelection.isValid ? currentSelection : _lastContentSelection;
    final text = _contentController.text;
    final insertPos = (selection.isValid && selection.start >= 0)
        ? selection.start.clamp(0, text.length)
        : text.length;

    String insertion = '\n\n';
    if (insertPos == 0) {
      insertion = '';
    } else if (text.substring(0, insertPos).endsWith('\n\n')) {
      insertion = '';
    } else if (text.substring(0, insertPos).endsWith('\n')) {
      insertion = '\n';
    }

    final newText = text.replaceRange(insertPos, insertPos, insertion);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + insertion.length),
    );

    _lastContentSelection = _contentController.selection;
    _contentFocusNode.requestFocus();
    setState(() {});
  }

  // --- Image Picker (Hanya Kamera dan Galeri Saja) ---

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _pickedImagePath = base64String;
          _selectedAssetPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Pilih Sumber Gambar Sampul',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2E7D5A)),
                ),
                title: Text('Kamera', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Ambil foto baru langsung dari kamera', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2E7D5A)),
                ),
                title: Text('Galeri Foto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Pilih foto dari galeri HP atau komputer', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Save / Update Article Action ---

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final snippet = _snippetController.text.trim();
    final takeaways = _takeawayControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Judul artikel wajib diisi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konten artikel wajib diisi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      ArticleModel savedArticle;
      if (widget.initialArticle != null) {
        final updated = await _articleService.updateArticle(
          id: widget.initialArticle!.id,
          title: title,
          snippet: snippet.isNotEmpty ? snippet : null,
          content: content,
          takeaways: takeaways,
          isPublished: _isPublished,
          imageUrl: _pickedImagePath,
          imageAsset: _selectedAssetPath,
          category: _selectedCategory,
        );
        savedArticle = updated ?? widget.initialArticle!;
      } else {
        savedArticle = await _articleService.createArticle(
          title: title,
          snippet: snippet.isNotEmpty ? snippet : null,
          content: content,
          takeaways: takeaways,
          isPublished: _isPublished,
          imageUrl: _pickedImagePath,
          imageAsset: _selectedAssetPath ?? 'assets/articles/article_5_pola_makan.jpg',
          category: _selectedCategory,
        );
      }

      if (!mounted) return;

      final message = _isPublished
          ? 'Artikel berhasil disimpan dan langsung dipublikasikan ke pengguna!'
          : 'Artikel berhasil disimpan sebagai draf.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D5A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Kembalikan status ke AdminHomeScreen agar langsung fokus ke tab yang tepat
      Navigator.of(context).pop<Map<String, dynamic>>({
        'success': true,
        'isPublished': _isPublished,
        'article': savedArticle,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _contentController.isDark = isDark;
    const headerColor = Color(0xFF388E6B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isEdit = widget.initialArticle != null;

    return Scaffold(
      backgroundColor: headerColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Edit Artikel' : 'Tambah Artikel',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KATEGORI EDUKASI (PILIHAN CHIPS)
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: Color(0xFF388E6B)),
                      const SizedBox(width: 6),
                      Text(
                        'Kategori Edukasi *',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: Pilih salah satu topik kategori di bawah ini.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF388E6B),
                            backgroundColor: cardBg,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF388E6B)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. JUDUL SECTION
                  Row(
                    children: [
                      const Icon(Icons.title_rounded, size: 16, color: Color(0xFF388E6B)),
                      const SizedBox(width: 6),
                      Text(
                        'Judul Artikel *',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: Teks judul artikel (contoh: 5 Pola Makan Penyebab Obesitas)',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: 5 Pola Makan Penyebab Obesitas',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. RINGKASAN SINGKAT (LEAD SNIPPET)
                  Row(
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF388E6B)),
                      const SizedBox(width: 6),
                      Text(
                        'Ringkasan Singkat (Lead Snippet)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: 1–2 kalimat pengantar. Teks ini tampil di kartu daftar artikel dan kotak sorotan hijau di awal artikel.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: TextField(
                      controller: _snippetController,
                      minLines: 2,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Kenali kebiasaan makan yang tanpa disadari meningkatkan risiko berat badan berlebih...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: const Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. GAMBAR SAMPUL SECTION (HANYA KAMERA DAN GALERI)
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 16, color: Color(0xFF388E6B)),
                      const SizedBox(width: 6),
                      Text(
                        'Gambar Sampul',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: JPG, JPEG, PNG (Maks. 5 MB). Diambil langsung dari Kamera atau Galeri perangkat.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: double.infinity,
                      height: 165,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: (_pickedImagePath != null || _selectedAssetPath != null)
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ArticleThumbnailImage(
                                  imageUrl: _pickedImagePath,
                                  imageAsset: _selectedAssetPath,
                                  borderRadius: BorderRadius.circular(11),
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(11),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.65),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 14,
                                  right: 14,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            _pickedImagePath != null ? 'Foto Kamera / Galeri' : 'Foto Sampul',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Ganti foto',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF2E7D5A),
                                              ),
                                            ),
                                          ),
                                          if (_pickedImagePath != null) ...[
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _pickedImagePath = null;
                                                  _selectedAssetPath = 'assets/articles/article_5_pola_makan.jpg';
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 38,
                                  color: Color(0xFF388E6B),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pilih foto dari Kamera atau Galeri',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format: JPG, JPEG, PNG (Maks. 5 MB)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. KONTEN SECTION DENGAN TOOLBAR, TOGGLE PRATINJAU & TIPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.article_outlined, size: 16, color: Color(0xFF388E6B)),
                          const SizedBox(width: 6),
                          Text(
                            'Konten Lengkap Artikel *',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      // Toggle Tulis vs Pratinjau
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isPreviewMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !_isPreviewMode ? const Color(0xFF388E6B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      size: 14,
                                      color: !_isPreviewMode ? Colors.white : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tulis',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: !_isPreviewMode ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isPreviewMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isPreviewMode ? const Color(0xFF388E6B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 14,
                                      color: _isPreviewMode ? Colors.white : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pratinjau',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _isPreviewMode ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPreviewMode
                        ? 'Mode Pratinjau: Tampilan persis seperti yang akan dibaca pengguna.'
                        : 'Format: Gunakan tombol B (tebal), I (miring), U (garis bawah), bullet, dan nomor.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mode Pratinjau atau Mode Tulis
                  if (_isPreviewMode)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 220),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF388E6B),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5EF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D5A)),
                                const SizedBox(width: 6),
                                Text(
                                  'Format Aktif: Bold, Italic, Underline, Bullet, & Nomor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D5A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FormattedArticleContent(
                            content: _contentController.text,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Toolbar Formatting
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildToolbarIconButton(
                                    label: '+ Paragraf',
                                    tooltip: 'Buat paragraf baru dengan jarak rapi',
                                    isDark: isDark,
                                    onTap: _insertParagraphBreak,
                                  ),
                                  const SizedBox(
                                    height: 18,
                                    child: VerticalDivider(color: Color(0xFFCBD5E1), width: 10),
                                  ),
                                  _buildToolbarIconButton(
                                    label: 'B',
                                    isBold: true,
                                    tooltip: 'Tebalkan teks terpilih (Bold)',
                                    isDark: isDark,
                                    onTap: () => _applyFormatting('**', '**', placeholder: 'teks tebal'),
                                  ),
                                  _buildToolbarIconButton(
                                    label: 'I',
                                    isItalic: true,
                                    tooltip: 'Miringkan teks terpilih (Italic)',
                                    isDark: isDark,
                                    onTap: () => _applyFormatting('*', '*', placeholder: 'teks miring'),
                                  ),
                                  _buildToolbarIconButton(
                                    label: 'U',
                                    isUnderline: true,
                                    tooltip: 'Garis bawahi teks terpilih (Underline)',
                                    isDark: isDark,
                                    onTap: () => _applyFormatting('<u>', '</u>', placeholder: 'teks bergaris bawah'),
                                  ),
                                  const SizedBox(
                                    height: 18,
                                    child: VerticalDivider(color: Color(0xFFCBD5E1), width: 10),
                                  ),
                                  _buildToolbarIcon(
                                    icon: Icons.format_list_bulleted_rounded,
                                    tooltip: 'Daftar berpoin (Bullet)',
                                    isDark: isDark,
                                    onTap: () => _insertLinePrefix('•'),
                                  ),
                                  _buildToolbarIcon(
                                    icon: Icons.format_list_numbered_rounded,
                                    tooltip: 'Daftar penomoran',
                                    isDark: isDark,
                                    onTap: () => _insertLinePrefix('1.'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Text Field Konten Multiline
                          TextField(
                            controller: _contentController,
                            focusNode: _contentFocusNode,
                            minLines: 8,
                            maxLines: 15,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              height: 1.6,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tulis isi konten edukasi kesehatan secara lengkap di sini...\n\nTekan tombol B, I, U di atas atau blok kata lalu klik format yang diinginkan.',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Tips format paragraf
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tips: Pisahkan setiap paragraf dengan Enter 2x agar teks di layar pengguna tersusun rapi.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. POIN PENTING UNTUK DIINGAT (KEY TAKEAWAYS)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4FAF7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFC8EBD9),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF388E6B).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_outlined, color: Color(0xFF388E6B), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Poin Penting untuk Diingat',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1B4332),
                                    ),
                                  ),
                                  Text(
                                    'Format: 1 poin kesimpulan per baris. Tampil di kotak hijau bercentang pada akhir artikel pengguna.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // List of dynamic takeaway inputs
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _takeawayControllers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final controller = _takeawayControllers[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF388E6B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: controller,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Poin penting ${index + 1}...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () => _removeTakeawayField(index),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 20,
                                  ),
                                  tooltip: 'Hapus poin ini',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Button tambah poin
                        OutlinedButton.icon(
                          onPressed: () => _addTakeawayField(),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: Text(
                            'Tambah Poin Penting',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D5A),
                            side: const BorderSide(color: Color(0xFF388E6B)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 7. STATUS PUBLIKASI SECTION
                  Row(
                    children: [
                      const Icon(Icons.publish_rounded, size: 16, color: Color(0xFF388E6B)),
                      const SizedBox(width: 6),
                      Text(
                        'Status Publikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih status apakah artikel langsung dapat dibaca pengguna atau disimpan sebagai draf.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Opsi 1: Publikasikan
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPublished = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isPublished
                                    ? const Color(0xFF388E6B)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB)),
                                width: _isPublished ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isPublished ? const Color(0xFF388E6B) : const Color(0xFF94A3B8),
                                      width: 2,
                                    ),
                                  ),
                                  child: _isPublished
                                      ? Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF388E6B),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Publikasikan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Artikel langsung tampil untuk semua pengguna',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                          height: 1.3,
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
                      const SizedBox(width: 12),

                      // Opsi 2: Simpan sebagai draf
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPublished = false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isPublished
                                    ? const Color(0xFF388E6B)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB)),
                                width: !_isPublished ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: !_isPublished ? const Color(0xFF388E6B) : const Color(0xFF94A3B8),
                                      width: 2,
                                    ),
                                  ),
                                  child: !_isPublished
                                      ? Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF388E6B),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Simpan sebagai draf',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Disimpan sebagai draf dan hanya dilihat admin',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                          height: 1.3,
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
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 8. TOMBOL AKSI: BATAL & SIMPAN ARTIKEL
                  Row(
                    children: [
                      // Tombol Batal
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF388E6B), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF388E6B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Tombol Simpan Artikel
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E6B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Perbarui artikel' : 'Simpan artikel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton({
    required String label,
    required VoidCallback onTap,
    String? tooltip,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isDark = false,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIcon({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool isDark = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
