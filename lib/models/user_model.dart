import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final UserRole role;
  final String? avatarUrl;
  final String? photoPath;
  final String? title;
  final String? dob;
  final String? gender;
  final String? phone;
  final String? address;
  final String? provinsi;
  final String? provinsiId;
  final String? kabupatenKota;
  final String? kabupatenKotaId;
  final String? kecamatan;
  final String? kecamatanId;
  final bool isBiodataComplete;
  final double bmiScore;
  final String bmiCategory;
  final String obesityRisk;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? joined;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.avatarUrl,
    this.photoPath,
    this.title,
    this.dob,
    this.gender,
    this.phone,
    this.address,
    this.provinsi,
    this.provinsiId,
    this.kabupatenKota,
    this.kabupatenKotaId,
    this.kecamatan,
    this.kecamatanId,
    this.isBiodataComplete = false,
    this.bmiScore = 22.8,
    this.bmiCategory = 'Normal',
    this.obesityRisk = 'Rendah',
    this.createdAt,
    this.updatedAt,
    this.joined,
  });

  bool get isAdmin => role == UserRole.admin;

  String get roleDisplayName => isAdmin ? 'Administrator' : 'Pengguna Biasa';

  String? get alamat => addressDisplay != 'Alamat belum diisi' ? addressDisplay : null;

  bool get hasStructuredAddress =>
      (provinsi != null && provinsi!.trim().isNotEmpty) &&
      (kabupatenKota != null && kabupatenKota!.trim().isNotEmpty) &&
      (kecamatan != null && kecamatan!.trim().isNotEmpty);

  String get formattedAddress {
    if (hasStructuredAddress) {
      return 'Kec. ${kecamatan!.trim()}, ${kabupatenKota!.trim()}, ${provinsi!.trim()}';
    }
    if (address != null && address!.trim().isNotEmpty) {
      return address!.trim();
    }
    return '';
  }

  String get addressDisplay {
    if (hasStructuredAddress) {
      return 'Kec. ${kecamatan!.trim()}, ${kabupatenKota!.trim()}, ${provinsi!.trim()}';
    }
    if (address != null && address!.trim().isNotEmpty) {
      return address!.trim();
    }
    return 'Alamat belum diisi';
  }

  /// Baris terstruktur alamat untuk Halaman Profil & Detail Admin
  List<Map<String, String>> get addressRows {
    if (hasStructuredAddress) {
      return [
        {'label': 'Provinsi', 'value': provinsi!.trim()},
        {'label': 'Kabupaten/Kota', 'value': kabupatenKota!.trim()},
        {'label': 'Kecamatan', 'value': kecamatan!.trim()},
      ];
    }
    if (address != null && address!.trim().isNotEmpty) {
      return [
        {'label': 'Alamat', 'value': address!.trim()},
      ];
    }
    return [
      {'label': 'Alamat', 'value': 'Alamat belum diisi'},
    ];
  }

  /// True jika status [isBiodataComplete] telah aktif atau ketiga syarat gating (Tanggal Lahir, Jenis Kelamin, Nomor Telepon) telah terisi
  bool get hasCompletedRequiredProfile {
    if (isBiodataComplete) return true;
    final validDob = dob != null && dob!.trim().isNotEmpty;
    final validGender = gender != null && gender!.trim().isNotEmpty;
    final validPhone = phone != null && phone!.trim().isNotEmpty;
    return validDob && validGender && validPhone;
  }

  /// Format tanggal bergabung yang rapi
  String get joinedFormatted {
    if (joined != null && joined!.trim().isNotEmpty) {
      return joined!.trim();
    }
    if (createdAt != null) {
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${createdAt!.day} ${months[createdAt!.month - 1]} ${createdAt!.year}';
    }
    return 'Belum tersedia';
  }

  /// Perkiraan usia dari tanggal lahir jika tersedia
  int? get age {
    if (dob == null || dob!.trim().isEmpty) return null;
    final cleanDob = dob!.trim();

    // 1. Ekstrak 4 digit tahun (contoh "12 Juli 2003" atau "2003-07-12")
    final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(cleanDob);
    if (match != null) {
      final y = int.tryParse(match.group(1)!);
      if (y != null && y <= DateTime.now().year) {
        return DateTime.now().year - y;
      }
    }

    final parsed = DateTime.tryParse(cleanDob);
    if (parsed != null) {
      var calculatedAge = DateTime.now().year - parsed.year;
      if (DateTime.now().month < parsed.month ||
          (DateTime.now().month == parsed.month &&
              DateTime.now().day < parsed.day)) {
        calculatedAge--;
      }
      return calculatedAge;
    }
    return null;
  }

  /// Gabungan jenis kelamin dan usia dengan dot (contoh: "Perempuan • 23 Tahun")
  String get genderAndAgeDotFormatted {
    final hasGender = gender != null && gender!.trim().isNotEmpty;
    final userAge = age;

    if (hasGender && userAge != null) {
      return '${gender!.trim()} • $userAge Tahun';
    } else if (hasGender) {
      return gender!.trim();
    } else if (userAge != null) {
      return '$userAge Tahun';
    }
    return '--';
  }

  /// Gabungan jenis kelamin dan usia (contoh: "Perempuan, 21 tahun" atau "Laki-laki")
  String get genderAndAgeFormatted {
    final hasGender = gender != null && gender!.trim().isNotEmpty;
    final userAge = age;

    if (hasGender && userAge != null) {
      return '${gender!.trim()}, $userAge tahun';
    } else if (hasGender) {
      return gender!.trim();
    } else if (userAge != null) {
      return '$userAge tahun';
    }
    return '--';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parsedCreatedAt;
    final createdVal = map['createdAt'] ??
        map['created_at'] ??
        map['created'] ??
        map['tanggalDaftar'];
    if (createdVal is Timestamp) {
      parsedCreatedAt = createdVal.toDate();
    } else if (createdVal is String) {
      parsedCreatedAt = DateTime.tryParse(createdVal);
    } else if (createdVal is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdVal);
    }

    DateTime? parsedUpdatedAt;
    final updatedVal =
        map['updatedAt'] ?? map['updated_at'] ?? map['updated'];
    if (updatedVal is Timestamp) {
      parsedUpdatedAt = updatedVal.toDate();
    } else if (updatedVal is String) {
      parsedUpdatedAt = DateTime.tryParse(updatedVal);
    } else if (updatedVal is int) {
      parsedUpdatedAt = DateTime.fromMillisecondsSinceEpoch(updatedVal);
    }

    final rawName = (map['name'] ??
            map['displayName'] ??
            map['nama'] ??
            map['fullName'])
        ?.toString()
        .trim();
    final rawEmail = (map['email'] ??
            map['userEmail'] ??
            map['surel'])
        ?.toString()
        .trim() ??
        '';
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (rawEmail.isNotEmpty
            ? rawEmail.split('@').first
            : 'Pengguna ObeSight');

    final rawUsername = (map['username'] ?? map['userName'])
        ?.toString()
        .trim();
    final username = (rawUsername != null && rawUsername.isNotEmpty)
        ? rawUsername
        : (rawEmail.isNotEmpty ? rawEmail.split('@').first : 'user');

    final rawRole = (map['role'] ?? map['userRole'])
        ?.toString()
        .trim()
        .toLowerCase();
    final bool isAdminRole = rawRole == 'admin' ||
        rawRole == 'administrator' ||
        map['isAdmin'] == true ||
        map['is_admin'] == true;
    final userRole = isAdminRole ? UserRole.admin : UserRole.user;

    final avatar = (map['photoUrl'] ??
            map['avatarUrl'] ??
            map['avatar'] ??
            map['photoURL'] ??
            map['profileImage'])
        ?.toString()
        .trim();
    final photo = (map['photoPath'] ?? map['photo_path'])?.toString().trim();
    final title = (map['title'] ?? map['gelar'])?.toString().trim();
    final dob = (map['dob'] ??
            map['birthDate'] ??
            map['tanggalLahir'])
        ?.toString()
        .trim();
    final gender = (map['gender'] ??
            map['jenisKelamin'] ??
            map['sex'])
        ?.toString()
        .trim();
    final phone = (map['phone'] ??
            map['phoneNumber'] ??
            map['noTelepon'] ??
            map['telepon'])
        ?.toString()
        .trim();
    final rawAddress = (map['alamat'] ??
            map['address'] ??
            map['userAddress'] ??
            map['lokasi'])
        ?.toString()
        .trim();
    final provinsi = (map['provinsi'] ?? map['province'])?.toString().trim();
    final provinsiId = (map['provinsiId'] ?? map['provinceId'])?.toString().trim();
    final kabupatenKota = (map['kabupatenKota'] ??
            map['kabupaten_kota'] ??
            map['kabupaten'] ??
            map['kota'] ??
            map['regency'])
        ?.toString()
        .trim();
    final kabupatenKotaId = (map['kabupatenKotaId'] ?? map['regencyId'])?.toString().trim();
    final kecamatan = (map['kecamatan'] ?? map['district'])?.toString().trim();
    final kecamatanId = (map['kecamatanId'] ?? map['districtId'])?.toString().trim();

    String? resolvedAddress = (rawAddress != null && rawAddress.isNotEmpty) ? rawAddress : null;
    if (resolvedAddress == null &&
        provinsi != null &&
        provinsi.isNotEmpty &&
        kabupatenKota != null &&
        kabupatenKota.isNotEmpty &&
        kecamatan != null &&
        kecamatan.isNotEmpty) {
      resolvedAddress = 'Kec. $kecamatan, $kabupatenKota, $provinsi';
    }

    final bool isBioComplete = (map['isBiodataComplete'] == true) ||
        (map['isBiodataComplete']?.toString().toLowerCase() == 'true') ||
        (map['isBiodataComplete'] == 1);

    double bmiVal = 22.8;
    final rawBmi = map['bmiScore'] ?? map['bmi'] ?? map['scoreBmi'];
    if (rawBmi is num) {
      bmiVal = rawBmi.toDouble();
    } else if (rawBmi is String) {
      bmiVal = double.tryParse(rawBmi) ?? 22.8;
    }

    final bmiCat = (map['bmiCategory'] ?? map['kategoriBmi'])
            ?.toString()
            .trim() ??
        'Normal';
    final obsRisk = (map['obesityRisk'] ??
            map['risikoObesitas'] ??
            map['risk'])
        ?.toString()
        .trim() ??
        'Rendah';
    final joined = (map['joined'] ?? map['bergabung'])?.toString().trim();

    return UserModel(
      id: id,
      name: name,
      email: rawEmail,
      username: username,
      role: userRole,
      avatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
      photoPath: (photo != null && photo.isNotEmpty) ? photo : null,
      title: (title != null && title.isNotEmpty) ? title : null,
      dob: (dob != null && dob.isNotEmpty) ? dob : null,
      gender: (gender != null && gender.isNotEmpty) ? gender : null,
      phone: (phone != null && phone.isNotEmpty) ? phone : null,
      address: resolvedAddress,
      provinsi: (provinsi != null && provinsi.isNotEmpty) ? provinsi : null,
      provinsiId: (provinsiId != null && provinsiId.isNotEmpty) ? provinsiId : null,
      kabupatenKota: (kabupatenKota != null && kabupatenKota.isNotEmpty) ? kabupatenKota : null,
      kabupatenKotaId: (kabupatenKotaId != null && kabupatenKotaId.isNotEmpty) ? kabupatenKotaId : null,
      kecamatan: (kecamatan != null && kecamatan.isNotEmpty) ? kecamatan : null,
      kecamatanId: (kecamatanId != null && kecamatanId.isNotEmpty) ? kecamatanId : null,
      isBiodataComplete: isBioComplete,
      bmiScore: bmiVal,
      bmiCategory: bmiCat,
      obesityRisk: obsRisk,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      joined: (joined != null && joined.isNotEmpty) ? joined : null,
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveAddress = (address != null && address!.isNotEmpty)
        ? address!
        : (hasStructuredAddress ? 'Kec. $kecamatan, $kabupatenKota, $provinsi' : '');

    return {
      'uid': id,
      'name': name,
      'email': email,
      'username': username,
      'role': isAdmin ? 'admin' : 'user',
      'photoUrl': avatarUrl ?? '',
      'photoPath': photoPath ?? '',
      'title': title ?? '',
      'dob': dob ?? '',
      'gender': gender ?? '',
      'phone': phone ?? '',
      'alamat': effectiveAddress,
      'address': effectiveAddress,
      'provinsi': provinsi ?? '',
      'provinsiId': provinsiId ?? '',
      'kabupatenKota': kabupatenKota ?? '',
      'kabupatenKotaId': kabupatenKotaId ?? '',
      'kecamatan': kecamatan ?? '',
      'kecamatanId': kecamatanId ?? '',
      'isBiodataComplete': isBiodataComplete,
      'bmiScore': bmiScore,
      'bmiCategory': bmiCategory,
      'obesityRisk': obesityRisk,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (joined != null) 'joined': joined,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    UserRole? role,
    String? avatarUrl,
    String? photoPath,
    String? title,
    String? dob,
    String? gender,
    String? phone,
    String? address,
    String? provinsi,
    String? provinsiId,
    String? kabupatenKota,
    String? kabupatenKotaId,
    String? kecamatan,
    String? kecamatanId,
    bool? isBiodataComplete,
    double? bmiScore,
    String? bmiCategory,
    String? obesityRisk,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? joined,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photoPath: photoPath ?? this.photoPath,
      title: title ?? this.title,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      provinsi: provinsi ?? this.provinsi,
      provinsiId: provinsiId ?? this.provinsiId,
      kabupatenKota: kabupatenKota ?? this.kabupatenKota,
      kabupatenKotaId: kabupatenKotaId ?? this.kabupatenKotaId,
      kecamatan: kecamatan ?? this.kecamatan,
      kecamatanId: kecamatanId ?? this.kecamatanId,
      isBiodataComplete: isBiodataComplete ?? this.isBiodataComplete,
      bmiScore: bmiScore ?? this.bmiScore,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      obesityRisk: obesityRisk ?? this.obesityRisk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      joined: joined ?? this.joined,
    );
  }
}
