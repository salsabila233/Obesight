import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Scaffold with a sticky (pinned) green header and a curved content sheet.
///
/// Features:
/// - Sticky (pinned) green header bar (ObeSight brand green: 0xFF36785A or custom).
/// - Curved sheet container with top-left and top-right radius of 28px.
/// - Overlap between curved sheet and header (default 24px, range 20-28px).
/// - Support for optional hero image header (collapsing SliverAppBar with parallax)
///   for detail screens (e.g., HealthArticleDetailScreen).
/// - Responds to Dark Mode and notch / safe area.
class CurvedHeaderScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Color? headerColor;
  final Color? sheetColor;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final TextStyle? titleStyle;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? contentPadding;

  // Image Header Options (for detail screens)
  final String? imageUrl;
  final String? imageAsset;
  final double? expandedHeight;
  final IconData? imagePlaceholderIcon;
  final Color? imagePlaceholderColor;
  final Widget? flexibleSpaceContent;
  final ScrollController? scrollController;

  // Overlap between the curved sheet and header (default: 24px)
  final double overlap;

  const CurvedHeaderScaffold({
    super.key,
    required this.title,
    required this.body,
    this.headerColor,
    this.sheetColor,
    this.onBack,
    this.leading,
    this.actions,
    this.centerTitle,
    this.titleStyle,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.contentPadding,
    this.imageUrl,
    this.imageAsset,
    this.expandedHeight,
    this.imagePlaceholderIcon,
    this.imagePlaceholderColor,
    this.flexibleSpaceContent,
    this.scrollController,
    this.overlap = 24.0,
  });

  @override
  State<CurvedHeaderScaffold> createState() => _CurvedHeaderScaffoldState();
}

class _CurvedHeaderScaffoldState extends State<CurvedHeaderScaffold> {
  late ScrollController _scrollController;
  bool _internalController = false;
  bool _isCollapsed = false;

  bool get _hasImageHeader =>
      (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) ||
      (widget.imageAsset != null && widget.imageAsset!.trim().isNotEmpty) ||
      widget.expandedHeight != null;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _internalController = true;
    }

    if (_hasImageHeader) {
      _scrollController.addListener(_handleScroll);
    }
  }

  @override
  void didUpdateWidget(covariant CurvedHeaderScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      if (_internalController) {
        _scrollController.removeListener(_handleScroll);
        _scrollController.dispose();
      }
      if (widget.scrollController != null) {
        _scrollController = widget.scrollController!;
        _internalController = false;
      } else {
        _scrollController = ScrollController();
        _internalController = true;
      }
      if (_hasImageHeader) {
        _scrollController.addListener(_handleScroll);
      }
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final expanded = widget.expandedHeight ?? 250.0;
    final triggerOffset = expanded - kToolbarHeight - widget.overlap - 10;
    final isCollapsed = _scrollController.offset > triggerOffset;
    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    if (_hasImageHeader) {
      _scrollController.removeListener(_handleScroll);
    }
    if (_internalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Widget _buildPlaceholder(Color fallbackColor) {
    return Container(
      color: widget.imagePlaceholderColor ?? fallbackColor,
      child: Center(
        child: Icon(
          widget.imagePlaceholderIcon ?? Icons.article_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveHeaderColor = widget.headerColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFF36785A));
    final effectiveSheetColor = widget.sheetColor ??
        (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9));

    if (_hasImageHeader) {
      return _buildImageHeaderScaffold(
        context: context,
        isDark: isDark,
        effectiveHeaderColor: effectiveHeaderColor,
        effectiveSheetColor: effectiveSheetColor,
      );
    }

    return _buildStandardScaffold(
      context: context,
      isDark: isDark,
      effectiveHeaderColor: effectiveHeaderColor,
      effectiveSheetColor: effectiveSheetColor,
    );
  }

  /// Scaffold dengan header foto besar yang collapsible ke AppBar hijau solid (pinned).
  Widget _buildImageHeaderScaffold({
    required BuildContext context,
    required bool isDark,
    required Color effectiveHeaderColor,
    required Color effectiveSheetColor,
  }) {
    final hasRemoteImage = widget.imageUrl != null &&
        widget.imageUrl!.trim().startsWith('http');
    final hasLocalImage = widget.imageUrl != null &&
        !widget.imageUrl!.trim().startsWith('http') &&
        widget.imageUrl!.trim().isNotEmpty;
    final hasAssetImage =
        widget.imageAsset != null && widget.imageAsset!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: effectiveHeaderColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: widget.expandedHeight ?? 250.0,
            pinned: true,
            elevation: _isCollapsed ? 2 : 0,
            backgroundColor: effectiveHeaderColor,
            leading: widget.leading ??
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _isCollapsed
                          ? Colors.transparent
                          : Colors.black.withValues(alpha: 0.38),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                ),
            title: AnimatedOpacity(
              opacity: _isCollapsed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.titleStyle ??
                    GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
            centerTitle: widget.centerTitle ?? false,
            actions: widget.actions,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasRemoteImage)
                    Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(effectiveHeaderColor),
                    )
                  else if (hasLocalImage)
                    Image.file(
                      File(widget.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(effectiveHeaderColor),
                    )
                  else if (hasAssetImage)
                    Image.asset(
                      widget.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(effectiveHeaderColor),
                    )
                  else
                    _buildPlaceholder(effectiveHeaderColor),

                  // Gradient Overlay untuk keterbacaan teks dan tombol kembali
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  if (widget.flexibleSpaceContent != null)
                    widget.flexibleSpaceContent!,
                ],
              ),
            ),
          ),

          // Area konten melengkung (sheet) yang menumpuk di atas bagian bawah foto
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -widget.overlap, 0),
              decoration: BoxDecoration(
                color: effectiveSheetColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: widget.contentPadding != null
                    ? Padding(
                        padding: widget.contentPadding!,
                        child: widget.body,
                      )
                    : widget.body,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  /// Scaffold dengan header hijau solid pinned dan konten melengkung sticky di atas.
  Widget _buildStandardScaffold({
    required BuildContext context,
    required bool isDark,
    required Color effectiveHeaderColor,
    required Color effectiveSheetColor,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerHeight = topPadding + kToolbarHeight;
    final overlap = widget.overlap;

    return Scaffold(
      backgroundColor: effectiveHeaderColor,
      body: Stack(
        children: [
          // 1. Header Hijau Pinned di Atas (termasuk area overlap)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight + overlap,
            child: Container(
              color: effectiveHeaderColor,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      widget.leading ??
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                            onPressed:
                                widget.onBack ?? () => Navigator.of(context).pop(),
                          ),
                      if (widget.centerTitle == true) const Spacer(),
                      if (widget.centerTitle != true) const SizedBox(width: 4),
                      Expanded(
                        flex: widget.centerTitle == true ? 0 : 1,
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: widget.titleStyle ??
                              GoogleFonts.poppins(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                        ),
                      ),
                      if (widget.centerTitle == true) const Spacer(),
                      if (widget.actions != null) ...widget.actions!,
                      if (widget.centerTitle == true && widget.actions == null)
                        const SizedBox(width: 48), // Menyeimbangkan tombol leading
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Area Konten Lembaran Melengkung (Radius 28) yang menumpuk di atas header hijau
          Positioned(
            top: headerHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: effectiveSheetColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: widget.contentPadding != null
                    ? Padding(
                        padding: widget.contentPadding!,
                        child: widget.body,
                      )
                    : widget.body,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
