import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../services/admin_user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_capsule_bottom_nav.dart';
import '../home/admin_home_screen.dart';
import 'admin_user_screening_detail_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onTabSelected;

  const AdminUserListScreen({
    super.key,
    this.isEmbedded = false,
    this.onBackToHome,
    this.onTabSelected,
  });

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final _adminUserService = AdminUserService.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleNavTap(int index) {
    if (index == 1) return; // Sudah di tab Pengguna
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
      return;
    }
    if (index == 0 && widget.onBackToHome != null) {
      widget.onBackToHome!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(index);
    } else {
      final currentUser = AuthService().currentUser ??
          const UserModel(
            id: 'admin',
            name: 'Admin',
            email: 'admin@obesight.com',
            username: 'admin',
            role: UserRole.admin,
          );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AdminHomeScreen(
            user: currentUser,
            initialIndex: index,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const sageGreen = Color(
      0xFF529471,
    ); // Warna hijau sage sesuai desain Obesight

    final bodyContent = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // 1. Search Bar "Cari" di pojok kanan atas (Persis Screenshot Referensi)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 175,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF64748B),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Daftar Pengguna dari Stream Firestore Realtime
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _adminUserService.streamUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(sageGreen),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Gagal memuat data pengguna dari Firestore.',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pastikan koneksi internet aktif dan hak akses admin valid.',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: Text(
                                'Muat Ulang',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: sageGreen,
                                side: const BorderSide(color: sageGreen),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allUsers = snapshot.data ?? [];
                  final query = _searchQuery.trim().toLowerCase();

                  final filteredUsers = allUsers.where((u) {
                    if (query.isEmpty) return true;
                    final nameMatch = u.name.toLowerCase().contains(query);
                    final emailMatch = u.email.toLowerCase().contains(query);
                    final phoneMatch =
                        u.phone != null && u.phone!.contains(query);
                    final usernameMatch =
                        u.username.toLowerCase().contains(query);
                    final roleMatch =
                        u.roleDisplayName.toLowerCase().contains(query) ||
                            (u.isAdmin ? 'admin' : 'pengguna').contains(query);
                    return nameMatch ||
                        emailMatch ||
                        phoneMatch ||
                        usernameMatch ||
                        roleMatch;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              query.isEmpty
                                  ? 'Belum ada pengguna terdaftar'
                                  : 'Pengguna "$query" tidak ditemukan',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      110,
                    ),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _AdminUserCardItem(
                        user: user,
                        onTap: () async {
                          final targetTab =
                              await Navigator.of(context).push<int>(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminUserScreeningDetailScreen(
                                    userId: user.id,
                                    initialUser: user,
                                  ),
                            ),
                          );
                          if (targetTab != null && mounted) {
                            _handleNavTap(targetTab);
                          }
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
    );

    if (widget.isEmbedded) {
      return Container(color: sageGreen, child: bodyContent);
    }

    return Scaffold(
      backgroundColor: sageGreen,
      extendBody: true,
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
          onPressed: _handleBack,
        ),
        title: Text(
          'Pengguna',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: bodyContent,
      bottomNavigationBar: AdminCapsuleBottomNav(
        currentIndex: 1,
        onTap: _handleNavTap,
      ),
    );
  }
}

// =============================================================================
// KARTU PENGGUNA (Identik dengan Desain Screenshot Obesight)
// =============================================================================
class _AdminUserCardItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _AdminUserCardItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserScreeningSummary>(
      future: AdminUserService.instance.getUserScreeningSummary(user.id),
      builder: (context, snapshot) {
        final summary = snapshot.data ?? const UserScreeningSummary();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. BAGIAN KIRI: Foto Profil Pengguna
                    _buildAvatar(user),

                    const SizedBox(width: 12),

                    // 2. BAGIAN TENGAH: Nama, Email, Nomor Telepon, Gender • Usia
                    Expanded(
                      flex: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (user.isAdmin) ...[
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5EE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF529471),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF267352),
                                    ),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name
                                      : 'Pengguna ObeSight',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            user.email.isNotEmpty
                                ? user.email
                                : 'Email belum diisi',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (user.phone != null &&
                                    user.phone!.trim().isNotEmpty)
                                ? user.phone!.trim()
                                : '-',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            user.genderAndAgeDotFormatted != '--'
                                ? user.genderAndAgeDotFormatted
                                : (user.isAdmin ? 'Administrator' : '-'),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Garis Pembatas Vertikal
                    Container(
                      width: 1,
                      height: 64,
                      color: const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),

                    // 3. BAGIAN KANAN: Bergabung, Total Skrining, Skrining Terakhir
                    Expanded(
                      flex: 9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRightMetricItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Bergabung',
                            value: user.joinedFormatted != 'Belum tersedia'
                                ? user.joinedFormatted
                                : '-',
                          ),
                          const SizedBox(height: 5),
                          _buildRightMetricItem(
                            icon: Icons.stacked_line_chart_rounded,
                            label: 'Total Skrining',
                            value: summary.totalScreenings > 0
                                ? summary.formattedTotal
                                : '0 kali',
                          ),
                          const SizedBox(height: 5),
                          _buildRightMetricItem(
                            icon: Icons.access_time_rounded,
                            label: 'Skrining Terakhir',
                            value: summary.lastScreeningDate != null
                                ? summary.formattedLastDateShort
                                : '-',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    // 4. Chevron Navigation Arrow
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Color(0xFF0F172A),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 11, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: const Color(0xFF94A3B8),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(UserModel user) {
    final photo = user.avatarUrl ?? user.photoPath;

    if (photo != null &&
        (photo.startsWith('http://') || photo.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          photo,
          width: 58,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderAvatar(user),
        ),
      );
    } else if (photo != null && photo.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          photo,
          width: 58,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderAvatar(user),
        ),
      );
    }

    return _buildPlaceholderAvatar(user);
  }

  Widget _buildPlaceholderAvatar(UserModel user) {
    return Container(
      width: 58,
      height: 68,
      decoration: BoxDecoration(
        color: user.isAdmin
            ? const Color(0xFFE8F5EE)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isAdmin
              ? const Color(0xFF529471).withValues(alpha: 0.3)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        user.isAdmin
            ? Icons.admin_panel_settings_rounded
            : Icons.person_rounded,
        size: 32,
        color: user.isAdmin
            ? const Color(0xFF267352)
            : const Color(0xFF64748B),
      ),
    );
  }
}
