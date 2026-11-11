import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/article_model.dart';
import '../../models/user_model.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../../services/physical_activity_service.dart';
import '../../services/sleep_tracking_service.dart';

enum ActivityFilter {
  all('Semua'),
  users('Pengguna'),
  articles('Artikel');

  final String label;
  const ActivityFilter(this.label);
}

enum ActivityItemType {
  sleepSession,
  physicalActivity,
  nutritionMeal,
  newUser,
  userProfileUpdated,
  articlePublished,
  articleCreated,
  articleUpdated,
}

class ActivityItemData {
  final String id;
  final ActivityItemType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String categoryTag;
  final ActivityFilter filterCategory;

  const ActivityItemData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.categoryTag,
    required this.filterCategory,
  });
}

/// Halaman Riwayat Aktivitas Lengkap
/// Menyajikan tab filter (Semua, Pengguna, Artikel) dengan garis indikator aktif
/// dan kolom pencarian "Cari" yang persis menyerupai desain halaman Artikel
class AdminActivityListScreen extends StatefulWidget {
  const AdminActivityListScreen({super.key});

  @override
  State<AdminActivityListScreen> createState() => _AdminActivityListScreenState();
}

class _AdminActivityListScreenState extends State<AdminActivityListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final ArticleService _articleService = ArticleService();

  ActivityFilter _selectedFilter = ActivityFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const sageGreen = Color(0xFF529471);
    final pageBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF9);
    final headerBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: sageGreen,
      appBar: AppBar(
        backgroundColor: sageGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Aktivitas',
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
          color: pageBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              // Header Putih Melengkung dengan Tab Bar & Search Bar (Persis Halaman Artikel)
              Container(
                color: headerBgColor,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // 1. Tab Bar 3 Kategori dengan Garis Indikator Aktif: Semua | Pengguna | Artikel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFilterTab(ActivityFilter.all, isDark),
                        _buildFilterTab(ActivityFilter.users, isDark),
                        _buildFilterTab(ActivityFilter.articles, isDark),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 2. Kolom Pencarian "Cari" Kotak Rounded dengan Ikon Kaca Pembesar di Kiri
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),

              // 3. Activity Stream Builder & Card List
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: _authService.getAllUsersStream(),
                  builder: (context, userSnap) {
                    return StreamBuilder<List<ArticleModel>>(
                      stream: _articleService.getAllArticlesStream(),
                      builder: (context, artSnap) {
                        if (userSnap.connectionState == ConnectionState.waiting &&
                            !userSnap.hasData &&
                            !artSnap.hasData) {
                          return const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF267352),
                              ),
                            ),
                          );
                        }

                        final users = userSnap.data ?? [];
                        final articles = artSnap.data ?? [];

                        final allActivities = _aggregateAllActivities(
                          users: users,
                          articles: articles,
                        );

                        // Saring berdasarkan 3 Kategori Tab: Semua | Pengguna | Artikel
                        final categoryFiltered = allActivities.where((item) {
                          if (_selectedFilter == ActivityFilter.users) {
                            return item.filterCategory == ActivityFilter.users;
                          } else if (_selectedFilter == ActivityFilter.articles) {
                            return item.filterCategory == ActivityFilter.articles;
                          }
                          return true; // 'Semua' menampilkan seluruh riwayat aktivitas
                        }).toList();

                        // Saring berdasarkan Kata Kunci Pencarian (Nama, Judul, Kategori, atau Tanggal)
                        final filteredList = categoryFiltered.where((item) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase();
                          final exactDate = _formatExactTime(item.timestamp).toLowerCase();
                          final relDate = _formatRelativeTime(item.timestamp).toLowerCase();
                          return item.title.toLowerCase().contains(q) ||
                              item.subtitle.toLowerCase().contains(q) ||
                              item.categoryTag.toLowerCase().contains(q) ||
                              exactDate.contains(q) ||
                              relDate.contains(q);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return _buildEmptyState(isDark);
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildActivityCard(item, isDark);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun Tab Filter persis seperti pada halaman Artikel (dengan garis indikator aktif di bawah teks)
  Widget _buildFilterTab(ActivityFilter filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    final activeColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Text(
            filter.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  List<ActivityItemData> _aggregateAllActivities({
    required List<UserModel> users,
    required List<ArticleModel> articles,
  }) {
    final List<ActivityItemData> items = [];
    final now = DateTime.now();

    // 1. Aktivitas Tidur (Sleep Records dari SleepTrackingService)
    final sleepRecords = SleepTrackingService.instance.allRecords;
    for (final r in sleepRecords) {
      items.add(
        ActivityItemData(
          id: 'sleep_${r.id}',
          type: ActivityItemType.sleepSession,
          title: r.source == 'automatic'
              ? 'Perekaman Tidur Otomatis'
              : 'Pencatatan Waktu Tidur',
          subtitle:
              '${r.durationFormatted} (${r.startTimeFormatted} - ${r.endTimeFormatted}) • ${r.standardHalodocCategory}',
          timestamp: r.endTime,
          icon: Icons.nightlight_round,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          categoryTag: 'TIDUR',
          filterCategory: ActivityFilter.all,
        ),
      );
    }

    // Default seeded sleep records jika database masih kosong
    if (sleepRecords.isEmpty) {
      items.add(
        ActivityItemData(
          id: 'sleep_seed_auto_today',
          type: ActivityItemType.sleepSession,
          title: 'Perekaman Tidur Otomatis',
          subtitle: '7 jam 45 menit (23:00 - 06:45) • Tidur Cukup (Ideal)',
          timestamp: DateTime(now.year, now.month, now.day, 6, 45),
          icon: Icons.nightlight_round,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          categoryTag: 'TIDUR',
          filterCategory: ActivityFilter.all,
        ),
      );
      items.add(
        ActivityItemData(
          id: 'sleep_seed_manual_yesterday',
          type: ActivityItemType.sleepSession,
          title: 'Pencatatan Waktu Tidur',
          subtitle: '6 jam 15 menit (00:00 - 06:15) • Tidur Kurang',
          timestamp: DateTime(now.year, now.month, now.day - 1, 6, 15),
          icon: Icons.bedtime_rounded,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF7C3AED),
          categoryTag: 'TIDUR',
          filterCategory: ActivityFilter.all,
        ),
      );
    }

    // 2. Aktivitas Fisik (Physical Activity Service)
    final completedByDate =
        PhysicalActivityService.instance.completedActivitiesByDate;
    if (completedByDate.isNotEmpty) {
      completedByDate.forEach((dateKey, actSet) {
        final parsedDate = DateTime.tryParse(dateKey) ?? now;
        for (final actId in actSet) {
          final cleanName = actId.replaceAll('_', ' ').toUpperCase();
          items.add(
            ActivityItemData(
              id: 'phys_${dateKey}_$actId',
              type: ActivityItemType.physicalActivity,
              title: 'Aktivitas Fisik Selesai',
              subtitle: 'Sesi $cleanName telah diselesaikan dan dicatat',
              timestamp: parsedDate,
              icon: Icons.directions_run_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              categoryTag: 'AKTIVITAS FISIK',
              filterCategory: ActivityFilter.all,
            ),
          );
        }
      });
    } else {
      items.add(
        ActivityItemData(
          id: 'phys_seed_1',
          type: ActivityItemType.physicalActivity,
          title: 'Sesi Latihan Aerobik Selesai',
          subtitle: 'Jalan Santai 30 Menit • Target aerobik harian tercapai',
          timestamp: DateTime(now.year, now.month, now.day, 7, 30),
          icon: Icons.directions_run_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          categoryTag: 'AKTIVITAS FISIK',
          filterCategory: ActivityFilter.all,
        ),
      );
    }

    // 3. Pola Makan & Nutrisi
    items.add(
      ActivityItemData(
        id: 'nutri_seed_1',
        type: ActivityItemType.nutritionMeal,
        title: 'Pencatatan Menu Sarapan Sehat',
        subtitle: 'Oatmeal buah dan telur rebus dicatat • Gizi seimbang',
        timestamp: DateTime(now.year, now.month, now.day, 8, 10),
        icon: Icons.restaurant_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        categoryTag: 'POLA MAKAN',
        filterCategory: ActivityFilter.all,
      ),
    );

    // 4. Pengguna: Pendaftaran & Update Profil (Filter: ActivityFilter.users)
    for (final u in users) {
      final name = u.name.isNotEmpty ? u.name : 'Pengguna';
      final emailStr = u.email.isNotEmpty ? ' (${u.email})' : '';
      if (u.createdAt != null) {
        items.add(
          ActivityItemData(
            id: 'user_reg_${u.id}',
            type: ActivityItemType.newUser,
            title: 'Pengguna baru terdaftar',
            subtitle: '$name$emailStr telah membuat akun',
            timestamp: u.createdAt!,
            icon: Icons.person_add_alt_1_rounded,
            iconBg: const Color(0xFFE8F5EE),
            iconColor: const Color(0xFF16A34A),
            categoryTag: 'PENGGUNA',
            filterCategory: ActivityFilter.users,
          ),
        );
      }
      if (u.updatedAt != null &&
          u.createdAt != null &&
          u.updatedAt!.isAfter(
            u.createdAt!.add(const Duration(minutes: 1)),
          )) {
        items.add(
          ActivityItemData(
            id: 'user_upd_${u.id}_${u.updatedAt!.millisecondsSinceEpoch}',
            type: ActivityItemType.userProfileUpdated,
            title: 'Data pengguna diperbarui',
            subtitle: '$name memperbarui data biodata & profil akun',
            timestamp: u.updatedAt!,
            icon: Icons.manage_accounts_rounded,
            iconBg: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0D9488),
            categoryTag: 'PENGGUNA',
            filterCategory: ActivityFilter.users,
          ),
        );
      }
    }

    // 5. Artikel & Konten (Filter: ActivityFilter.articles)
    for (final a in articles) {
      if (a.isPublished && a.publishedAt != null) {
        items.add(
          ActivityItemData(
            id: 'art_pub_${a.id}',
            type: ActivityItemType.articlePublished,
            title: 'Artikel baru dipublikasikan',
            subtitle: a.title,
            timestamp: a.publishedAt!,
            icon: Icons.article_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            categoryTag: 'ARTIKEL',
            filterCategory: ActivityFilter.articles,
          ),
        );
      } else if (!a.isPublished && a.publishedAt != null) {
        items.add(
          ActivityItemData(
            id: 'art_create_${a.id}',
            type: ActivityItemType.articleCreated,
            title: 'Artikel baru dibuat oleh admin',
            subtitle: a.title,
            timestamp: a.publishedAt!,
            icon: Icons.edit_note_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            categoryTag: 'ARTIKEL',
            filterCategory: ActivityFilter.articles,
          ),
        );
      }
      if (a.updatedAt != null &&
          a.publishedAt != null &&
          a.updatedAt!.isAfter(
            a.publishedAt!.add(const Duration(minutes: 1)),
          )) {
        items.add(
          ActivityItemData(
            id: 'art_upd_${a.id}_${a.updatedAt!.millisecondsSinceEpoch}',
            type: ActivityItemType.articleUpdated,
            title: 'Artikel diperbarui',
            subtitle: a.title,
            timestamp: a.updatedAt!,
            icon: Icons.drive_file_rename_outline_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            categoryTag: 'ARTIKEL',
            filterCategory: ActivityFilter.articles,
          ),
        );
      }
    }

    // Deduplikasi berdasarkan ID
    final uniqueMap = <String, ActivityItemData>{};
    for (final item in items) {
      uniqueMap[item.id] = item;
    }

    return uniqueMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Widget _buildActivityCard(ActivityItemData item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F1E36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.categoryTag,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${_formatExactTime(item.timestamp)} • ${_formatRelativeTime(item.timestamp)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String emptyMessage;
    if (_searchQuery.isNotEmpty) {
      emptyMessage = 'Tidak ada aktivitas yang cocok dengan kata kunci "$_searchQuery".';
    } else if (_selectedFilter == ActivityFilter.users) {
      emptyMessage = 'Belum ada riwayat aktivitas terkait pengguna.';
    } else if (_selectedFilter == ActivityFilter.articles) {
      emptyMessage = 'Belum ada riwayat aktivitas terkait artikel.';
    } else {
      emptyMessage = 'Riwayat aktivitas pengguna, artikel, dan sistem akan tercatat di sini.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 32,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada riwayat aktivitas',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F1E36),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatExactTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final minuteStr = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
    final hourStr = dt.hour < 10 ? '0${dt.hour}' : '${dt.hour}';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hourStr:$minuteStr';
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    }
  }
}
