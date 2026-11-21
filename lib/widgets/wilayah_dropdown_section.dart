import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/wilayah_service.dart';

class WilayahSelection {
  final RegionItem? provinsi;
  final RegionItem? kabupatenKota;
  final RegionItem? kecamatan;

  const WilayahSelection({
    this.provinsi,
    this.kabupatenKota,
    this.kecamatan,
  });

  bool get isComplete =>
      provinsi != null && kabupatenKota != null && kecamatan != null;

  String? get provinsiName => provinsi?.name;
  String? get provinsiId => provinsi?.id;
  String? get kabupatenKotaName => kabupatenKota?.name;
  String? get kabupatenKotaId => kabupatenKota?.id;
  String? get kecamatanName => kecamatan?.name;
  String? get kecamatanId => kecamatan?.id;

  String get formattedAddress {
    if (isComplete) {
      return 'Kec. ${kecamatan!.name}, ${kabupatenKota!.name}, ${provinsi!.name}';
    }
    return '';
  }
}

/// Widget formulir dropdown bertingkat: Provinsi -> Kabupaten/Kota -> Kecamatan
class WilayahDropdownSection extends StatefulWidget {
  final String? initialProvinsiId;
  final String? initialProvinsiName;
  final String? initialKabupatenKotaId;
  final String? initialKabupatenKotaName;
  final String? initialKecamatanId;
  final String? initialKecamatanName;
  final bool isDark;
  final bool isRequired;
  final ValueChanged<WilayahSelection> onChanged;

  const WilayahDropdownSection({
    super.key,
    this.initialProvinsiId,
    this.initialProvinsiName,
    this.initialKabupatenKotaId,
    this.initialKabupatenKotaName,
    this.initialKecamatanId,
    this.initialKecamatanName,
    required this.isDark,
    this.isRequired = true,
    required this.onChanged,
  });

  @override
  State<WilayahDropdownSection> createState() => WilayahDropdownSectionState();
}

class WilayahDropdownSectionState extends State<WilayahDropdownSection> {
  final _service = WilayahService.instance;

  List<RegionItem> _provinces = [];
  List<RegionItem> _regencies = [];
  List<RegionItem> _districts = [];

  RegionItem? _selectedProvince;
  RegionItem? _selectedRegency;
  RegionItem? _selectedDistrict;

  bool _isLoadingProvinces = true;
  bool _isLoadingRegencies = false;
  bool _isLoadingDistricts = false;

  @override
  void initState() {
    super.initState();
    if (_service.isLoaded) {
      _provinces = _service.provincesSync;
      _isLoadingProvinces = false;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_provinces.isEmpty) {
      setState(() => _isLoadingProvinces = true);
    }
    final provList = await _service.getProvinces();

    RegionItem? matchedProv;
    if (widget.initialProvinsiId != null && widget.initialProvinsiId!.isNotEmpty) {
      matchedProv = provList.cast<RegionItem?>().firstWhere(
            (p) => p?.id == widget.initialProvinsiId,
            orElse: () => null,
          );
    }
    if (matchedProv == null && widget.initialProvinsiName != null && widget.initialProvinsiName!.isNotEmpty) {
      final nameLower = widget.initialProvinsiName!.trim().toLowerCase();
      matchedProv = provList.cast<RegionItem?>().firstWhere(
            (p) => p?.name.toLowerCase() == nameLower || (p != null && p.name.toLowerCase().contains(nameLower)),
            orElse: () => null,
          );
    }

    List<RegionItem> regList = [];
    RegionItem? matchedReg;
    if (matchedProv != null) {
      regList = await _service.getRegencies(matchedProv.id);
      if (widget.initialKabupatenKotaId != null && widget.initialKabupatenKotaId!.isNotEmpty) {
        matchedReg = regList.cast<RegionItem?>().firstWhere(
              (r) => r?.id == widget.initialKabupatenKotaId,
              orElse: () => null,
            );
      }
      if (matchedReg == null && widget.initialKabupatenKotaName != null && widget.initialKabupatenKotaName!.isNotEmpty) {
        final regNameClean = widget.initialKabupatenKotaName!.trim().toLowerCase().replaceAll('kabupaten ', '').replaceAll('kota ', '').trim();
        matchedReg = regList.cast<RegionItem?>().firstWhere(
              (r) {
                if (r == null) return false;
                final rClean = r.name.toLowerCase().replaceAll('kabupaten ', '').replaceAll('kota ', '').trim();
                return rClean == regNameClean || r.name.toLowerCase().contains(regNameClean);
              },
              orElse: () => null,
            );
      }
    }

    List<RegionItem> distList = [];
    RegionItem? matchedDist;
    if (matchedReg != null) {
      distList = await _service.getDistricts(matchedReg.id);
      if (widget.initialKecamatanId != null && widget.initialKecamatanId!.isNotEmpty) {
        matchedDist = distList.cast<RegionItem?>().firstWhere(
              (d) => d?.id == widget.initialKecamatanId,
              orElse: () => null,
            );
      }
      if (matchedDist == null && widget.initialKecamatanName != null && widget.initialKecamatanName!.isNotEmpty) {
        final distNameClean = widget.initialKecamatanName!.trim().toLowerCase().replaceAll('kecamatan ', '').replaceAll('kec. ', '').trim();
        matchedDist = distList.cast<RegionItem?>().firstWhere(
              (d) {
                if (d == null) return false;
                final dClean = d.name.toLowerCase().replaceAll('kecamatan ', '').replaceAll('kec. ', '').trim();
                return dClean == distNameClean || d.name.toLowerCase().contains(distNameClean);
              },
              orElse: () => null,
            );
      }
    }

    if (mounted) {
      setState(() {
        _provinces = provList;
        _selectedProvince = matchedProv;
        _regencies = regList;
        _selectedRegency = matchedReg;
        _districts = distList;
        _selectedDistrict = matchedDist;
        _isLoadingProvinces = false;
      });

      _notifyChange();
    }
  }

  void _notifyChange() {
    widget.onChanged(WilayahSelection(
      provinsi: _selectedProvince,
      kabupatenKota: _selectedRegency,
      kecamatan: _selectedDistrict,
    ));
  }

  Future<void> _onProvinceChanged(RegionItem? newProv) async {
    if (newProv == _selectedProvince) return;

    setState(() {
      _selectedProvince = newProv;
      // KETENTUAN 2: Jika pengguna mengganti pilihan provinsi, pilihan kabupaten/kota dan kecamatan sebelumnya harus otomatis dikosongkan
      _selectedRegency = null;
      _selectedDistrict = null;
      _regencies = [];
      _districts = [];
      _isLoadingRegencies = newProv != null;
    });

    _notifyChange();

    if (newProv != null) {
      final regList = await _service.getRegencies(newProv.id);
      if (mounted && _selectedProvince == newProv) {
        setState(() {
          _regencies = regList;
          _isLoadingRegencies = false;
        });
      }
    }
  }

  Future<void> _onRegencyChanged(RegionItem? newReg) async {
    if (newReg == _selectedRegency) return;

    setState(() {
      _selectedRegency = newReg;
      // KETENTUAN 3: Jika pengguna mengganti pilihan kabupaten/kota, pilihan kecamatan sebelumnya harus otomatis dikosongkan
      _selectedDistrict = null;
      _districts = [];
      _isLoadingDistricts = newReg != null;
    });

    _notifyChange();

    if (newReg != null) {
      final distList = await _service.getDistricts(newReg.id);
      if (mounted && _selectedRegency == newReg) {
        setState(() {
          _districts = distList;
          _isLoadingDistricts = false;
        });
      }
    }
  }

  void _onDistrictChanged(RegionItem? newDist) {
    if (newDist == _selectedDistrict) return;

    setState(() {
      _selectedDistrict = newDist;
    });

    _notifyChange();
  }

  WilayahSelection get currentSelection => WilayahSelection(
        provinsi: _selectedProvince,
        kabupatenKota: _selectedRegency,
        kecamatan: _selectedDistrict,
      );

  @override
  Widget build(BuildContext context) {
    final textDark = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBorder = widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fieldBg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final disabledBg = widget.isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------------------------------------------------------------
        // 1. DROPDOWN PROVINSI
        // -------------------------------------------------------------
        Row(
          children: [
            Text(
              'Provinsi',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RegionItem>(
          key: const ValueKey('dropdown_provinsi'),
          // ignore: deprecated_member_use
          value: _selectedProvince,
          isExpanded: true,
          menuMaxHeight: 350,
          dropdownColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
          hint: Text(
            _isLoadingProvinces ? 'Memuat daftar provinsi...' : 'Pilih Provinsi',
            style: GoogleFonts.poppins(fontSize: 13, color: textMuted),
          ),
          icon: _isLoadingProvinces
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF246B4D)),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF246B4D)),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.map_outlined, color: textMuted, size: 20),
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF246B4D), width: 1.5)),
          ),
          items: _provinces.map((prov) {
            return DropdownMenuItem<RegionItem>(
              value: prov,
              child: Text(
                prov.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _isLoadingProvinces ? null : _onProvinceChanged,
          validator: widget.isRequired
              ? (val) => val == null ? 'Provinsi wajib dipilih' : null
              : null,
        ),

        const SizedBox(height: 16),

        // -------------------------------------------------------------
        // 2. DROPDOWN KABUPATEN / KOTA
        // -------------------------------------------------------------
        Row(
          children: [
            Text(
              'Kabupaten/Kota',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RegionItem>(
          key: const ValueKey('dropdown_kabupaten_kota'),
          // ignore: deprecated_member_use
          value: _selectedRegency,
          isExpanded: true,
          menuMaxHeight: 350,
          dropdownColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
          hint: Text(
            _isLoadingRegencies
                ? 'Memuat kabupaten/kota...'
                : (_selectedProvince == null
                    ? 'Pilih provinsi terlebih dahulu'
                    : 'Pilih Kabupaten/Kota'),
            style: GoogleFonts.poppins(fontSize: 13, color: textMuted),
          ),
          icon: _isLoadingRegencies
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF246B4D)),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _selectedProvince == null ? textMuted : const Color(0xFF246B4D),
                ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_city_rounded, color: textMuted, size: 20),
            filled: true,
            fillColor: _selectedProvince == null ? disabledBg : fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF246B4D), width: 1.5)),
          ),
          items: _regencies.map((reg) {
            return DropdownMenuItem<RegionItem>(
              value: reg,
              child: Text(
                reg.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (_selectedProvince == null || _isLoadingRegencies) ? null : _onRegencyChanged,
          validator: widget.isRequired
              ? (val) => val == null ? 'Kabupaten/Kota wajib dipilih' : null
              : null,
        ),

        const SizedBox(height: 16),

        // -------------------------------------------------------------
        // 3. DROPDOWN KECAMATAN
        // -------------------------------------------------------------
        Row(
          children: [
            Text(
              'Kecamatan',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RegionItem>(
          key: const ValueKey('dropdown_kecamatan'),
          // ignore: deprecated_member_use
          value: _selectedDistrict,
          isExpanded: true,
          menuMaxHeight: 350,
          dropdownColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          style: GoogleFonts.poppins(fontSize: 13.5, color: textDark),
          hint: Text(
            _isLoadingDistricts
                ? 'Memuat kecamatan...'
                : (_selectedRegency == null
                    ? 'Pilih kabupaten/kota terlebih dahulu'
                    : 'Pilih Kecamatan'),
            style: GoogleFonts.poppins(fontSize: 13, color: textMuted),
          ),
          icon: _isLoadingDistricts
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF246B4D)),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _selectedRegency == null ? textMuted : const Color(0xFF246B4D),
                ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.place_outlined, color: textMuted, size: 20),
            filled: true,
            fillColor: _selectedRegency == null ? disabledBg : fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF246B4D), width: 1.5)),
          ),
          items: _districts.map((dist) {
            return DropdownMenuItem<RegionItem>(
              value: dist,
              child: Text(
                dist.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (_selectedRegency == null || _isLoadingDistricts) ? null : _onDistrictChanged,
          validator: widget.isRequired
              ? (val) => val == null ? 'Kecamatan wajib dipilih' : null
              : null,
        ),
      ],
    );
  }
}
