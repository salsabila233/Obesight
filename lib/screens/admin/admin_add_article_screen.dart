import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/article_model.dart';
import '../../services/article_service.dart';
import '../../widgets/article_thumbnail_image.dart';

class AdminAddArticleScreen extends StatefulWidget {
  final ArticleModel? initialArticle;

  const AdminAddArticleScreen({
    super.key,
    this.initialArticle,
  });

  @override
  State<AdminAddArticleScreen> createState() => _AdminAddArticleScreenState();
}

class _AdminAddArticleScreenState extends State<AdminAddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final _articleService = ArticleService();
  final _imagePicker = ImagePicker();

  String? _pickedImagePath;
  String? _selectedAssetPath;
  String _selectedCategory = 'Edukasi Kesehatan';
  bool _isPublished = true;
  bool _isLoading = false;

  final List<String> _sampleAssets = [
    'assets/articles/article_5_pola_makan.jpg',
    'assets/articles/article_kualitas_tidur.jpg',
    'assets/articles/article_porsi_piring_gizi_seimbang.jpg',
    'assets/articles/article_aktivitas_fisik_ringan.jpg',
    'assets/articles/article_kenali_pola_hidup_sehat.jpg',
    'assets/articles/article_obesitas_komplikasi.jpg',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialArticle != null) {
      final a = widget.initialArticle!;
      _titleController.text = a.title;
      _contentController.text = a.content;
      _isPublished = a.isPublished;
      _selectedCategory = a.category;
      if (a.imageUrl != null && a.imageUrl!.isNotEmpty) {
        _pickedImagePath = a.imageUrl;
      } else {
        _selectedAssetPath = a.imageAsset;
      }
    } else {
      _selectedAssetPath = 'assets/articles/article_5_pola_makan.jpg';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // --- Formatting Helpers for Content Toolbar ---

  void _insertFormatting(String prefix, String suffix, {String placeholder = 'teks'}) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final insertPos = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(insertPos, insertPos, '$prefix$placeholder$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: insertPos + prefix.length,
          extentOffset: insertPos + prefix.length + placeholder.length,
        ),
      );
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.start + prefix.length + selectedText.length,
        ),
      );
    }
  }

  void _insertLinePrefix(String linePrefix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final insertPos = selection.isValid ? selection.start : text.length;
    final needNewline = insertPos > 0 && !text.endsWith('\n');
    final insertion = needNewline ? '\n$linePrefix ' : '$linePrefix ';

    final newText = text.replaceRange(insertPos, insertPos, insertion);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + insertion.length),
    );
  }

  // --- Image Picker Options ---

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (xFile != null) {
        setState(() {
          _pickedImagePath = xFile.path;
          _selectedAssetPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
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
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2E7D5A)),
                ),
                title: Text('Galeri Foto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Pilih dari file galeri perangkat', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
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
                  child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF2E7D5A)),
                ),
                title: Text('Pilih Ilustrasi Sampel ObeSight', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Gunakan aset grafis medis ObeSight', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSampleAssetsPicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSampleAssetsPicker() {
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
                'Pilih Ilustrasi Sampel',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: _sampleAssets.length,
                itemBuilder: (context, index) {
                  final asset = _sampleAssets[index];
                  final isSelected = _selectedAssetPath == asset && _pickedImagePath == null;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAssetPath = asset;
                        _pickedImagePath = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2E7D5A) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(asset, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Save Article Action ---

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

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
      await _articleService.createArticle(
        title: title,
        content: content,
        isPublished: _isPublished,
        imageUrl: _pickedImagePath,
        imageAsset: _selectedAssetPath ?? 'assets/articles/article_5_pola_makan.jpg',
        category: _selectedCategory,
      );

      if (!mounted) return;

      final message = _isPublished
          ? 'Artikel berhasil dipublikasikan dan dapat dilihat oleh pengguna'
          : 'Artikel berhasil disimpan sebagai draf';

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

      Navigator.of(context).pop(true);
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
    const headerColor = Color(0xFF388E6B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

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
          'Tambah Artikel',
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
                  // 1. JUDUL SECTION
                  Text(
                    'Judul',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan judul artikel',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. GAMBAR SAMPUL SECTION
                  Text(
                    'Gambar sampul',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: double.infinity,
                      height: 155,
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
                                        Colors.black.withValues(alpha: 0.6),
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
                                            'Gambar terpilih',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Ubah gambar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2E7D5A),
                                          ),
                                        ),
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
                                  Icons.camera_alt_outlined,
                                  size: 38,
                                  color: Color(0xFF388E6B),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pilih gambar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format : JPG, PNG, Max 2 MB',
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

                  // 3. KONTEN SECTION DENGAN TOOLBAR
                  Text(
                    'Konten',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                TextButton(
                                  onPressed: () => _insertLinePrefix('\n'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Paragraf',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 18,
                                  child: VerticalDivider(color: Color(0xFFCBD5E1), width: 14),
                                ),
                                _buildToolbarIconButton(
                                  label: 'B',
                                  isBold: true,
                                  onTap: () => _insertFormatting('**', '**'),
                                ),
                                _buildToolbarIconButton(
                                  label: 'I',
                                  isItalic: true,
                                  onTap: () => _insertFormatting('*', '*'),
                                ),
                                _buildToolbarIconButton(
                                  label: 'U',
                                  isUnderline: true,
                                  onTap: () => _insertFormatting('<u>', '</u>'),
                                ),
                                const SizedBox(
                                  height: 18,
                                  child: VerticalDivider(color: Color(0xFFCBD5E1), width: 14),
                                ),
                                _buildToolbarIcon(
                                  icon: Icons.format_list_bulleted_rounded,
                                  onTap: () => _insertLinePrefix('•'),
                                ),
                                _buildToolbarIcon(
                                  icon: Icons.format_list_numbered_rounded,
                                  onTap: () => _insertLinePrefix('1.'),
                                ),
                                _buildToolbarIcon(
                                  icon: Icons.format_align_left_rounded,
                                  onTap: () {},
                                ),
                                _buildToolbarIcon(
                                  icon: Icons.format_align_center_rounded,
                                  onTap: () {},
                                ),
                                _buildToolbarIcon(
                                  icon: Icons.format_align_right_rounded,
                                  onTap: () {},
                                ),
                                _buildToolbarIcon(
                                  icon: Icons.format_align_justify_rounded,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Text Field Konten Multiline
                        TextField(
                          controller: _contentController,
                          minLines: 8,
                          maxLines: 14,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            height: 1.6,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tulis isi konten edukasi kesehatan secara lengkap di sini...',
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
                  const SizedBox(height: 20),

                  // 4. STATUS PUBLIKASI SECTION
                  Text(
                    'Status',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                        'Artikel akan langsung ditampilkan di aplikasi',
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
                                        'Artikel disimpan sebagai draf dan belum tampil',
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

                  // 5. TOMBOL AKSI: BATAL & SIMPAN ARTIKEL
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
                                  'Simpan artikel',
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
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }
}
