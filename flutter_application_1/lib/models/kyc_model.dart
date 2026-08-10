import '../services/api_config.dart';

enum KycStatus {
  notSubmitted,
  pending,
  approved,
  rejected,
}

class KycModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String documentType; // national_id, passport, student_card
  final String idCardNumber;
  final String fullName;
  final String gender; // male, female, other
  final String dateOfBirth; // YYYY-MM-DD
  final String idCardImagePath;
  final String selfieImagePath;
  final bool isStudent;
  final String? schoolName;
  final KycStatus status;
  final String? rejectReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  KycModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.documentType = 'national_id',
    required this.idCardNumber,
    required this.fullName,
    this.gender = 'male',
    this.dateOfBirth = '',
    required this.idCardImagePath,
    required this.selfieImagePath,
    this.isStudent = false,
    this.schoolName,
    required this.status,
    this.rejectReason,
    required this.submittedAt,
    this.reviewedAt,
  });

  String get genderText {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'ชาย':
      case 'ຊາຍ':
        return 'ຊາຍ (Male)';
      case 'female':
      case 'หญิง':
      case 'ຍິງ':
        return 'ຍິງ (Female)';
      case 'other':
      case 'อื่นๆ':
      case 'ອື່ນໆ':
        return 'ອື່ນໆ (Other)';
      default:
        return gender.isNotEmpty ? gender : 'ບໍ່ລະບຸ (Unspecified)';
    }
  }

  String get statusText {
    switch (status) {
      case KycStatus.notSubmitted:
        return 'ຍັງບໍ່ທັນໄດ້ຢືນຢັນຕົວຕົນ';
      case KycStatus.pending:
        return 'ລໍຖ້າແອດມິນອະນຸມັດ';
      case KycStatus.approved:
        return 'ອະນຸມັດແລ້ວ (ຜ່ານ KYC)';
      case KycStatus.rejected:
        return 'ບໍ່ອະນຸມັດ (ຖືກປະຕິເສດ)';
    }
  }

  factory KycModel.empty() {
    return KycModel(
      id: '',
      userId: '',
      userName: '',
      userEmail: '',
      idCardNumber: '',
      fullName: '',
      gender: 'male',
      dateOfBirth: '',
      idCardImagePath: '',
      selfieImagePath: '',
      status: KycStatus.notSubmitted,
      submittedAt: DateTime.now(),
    );
  }

  factory KycModel.fromMap(Map<String, dynamic> map, {String? uploadsBaseUrl}) {
    final baseUrl = uploadsBaseUrl ?? ApiConfig.uploadsBaseUrl;
    KycStatus parsedStatus = KycStatus.pending;
    final st = map['status']?.toString().toLowerCase();
    if (st == 'approved') {
      parsedStatus = KycStatus.approved;
    } else if (st == 'rejected') {
      parsedStatus = KycStatus.rejected;
    } else if (st == 'not_submitted' || st == 'notsubmitted') {
      parsedStatus = KycStatus.notSubmitted;
    }

    String docImg = map['document_image_url'] ?? map['idCardImagePath'] ?? '';
    if (docImg.startsWith('/uploads/') || docImg.startsWith('uploads/')) {
      docImg = '$baseUrl/${docImg.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String selfieImg = map['selfie_image_url'] ?? map['selfieImagePath'] ?? '';
    if (selfieImg.startsWith('/uploads/') || selfieImg.startsWith('uploads/')) {
      selfieImg = '$baseUrl/${selfieImg.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    DateTime subAt = DateTime.now();
    if (map['created_at'] != null) {
      subAt = DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    } else if (map['submittedAt'] != null) {
      subAt = DateTime.tryParse(map['submittedAt'].toString()) ?? DateTime.now();
    }

    DateTime? revAt;
    if (map['updated_at'] != null) {
      revAt = DateTime.tryParse(map['updated_at'].toString());
    }

    String fn = '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim();
    if (fn.isEmpty) fn = map['full_name'] ?? map['fullName'] ?? map['user_name'] ?? map['userName'] ?? 'ບໍ່ລະບຸຊື່';

    return KycModel(
      id: (map['kyc_id'] ?? map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      userName: map['user_name'] ?? map['userName'] ?? fn,
      userEmail: map['email'] ?? map['userEmail'] ?? '',
      documentType: map['document_type'] ?? map['documentType'] ?? 'national_id',
      idCardNumber: map['document_number'] ?? map['idCardNumber'] ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? fn,
      gender: (map['gender'] ?? map['sex'] ?? 'male').toString(),
      dateOfBirth: (map['date_of_birth'] ?? map['dob'] ?? map['birth_date'] ?? '').toString(),
      idCardImagePath: docImg.isNotEmpty ? docImg : 'assets/sample_id_card.png',
      selfieImagePath: selfieImg.isNotEmpty ? selfieImg : 'assets/sample_selfie.png',
      isStudent: map['is_student'] == 1 || map['is_student'] == true || map['isStudent'] == true,
      schoolName: map['school_name'] ?? map['schoolName'],
      status: parsedStatus,
      rejectReason: map['rejection_reason'] ?? map['rejectReason'],
      submittedAt: subAt,
      reviewedAt: revAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kyc_id': id,
      'user_id': userId,
      'full_name': fullName,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'document_type': documentType,
      'document_number': idCardNumber,
      'document_image_url': idCardImagePath,
      'selfie_image_url': selfieImagePath,
      'is_student': isStudent,
      'school_name': schoolName,
      'status': status.name,
      'rejection_reason': rejectReason,
      'created_at': submittedAt.toIso8601String(),
    };
  }

  KycModel copyWith({
    String? fullName,
    String? gender,
    String? dateOfBirth,
    String? idCardNumber,
    String? documentType,
    String? idCardImagePath,
    String? selfieImagePath,
    bool? isStudent,
    String? schoolName,
    KycStatus? status,
    String? rejectReason,
    DateTime? reviewedAt,
  }) {
    return KycModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      documentType: documentType ?? this.documentType,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idCardImagePath: idCardImagePath ?? this.idCardImagePath,
      selfieImagePath: selfieImagePath ?? this.selfieImagePath,
      isStudent: isStudent ?? this.isStudent,
      schoolName: schoolName ?? this.schoolName,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

// # ເຮັດຫຍັງ: ລຶບ class Mock*Data ອອກຈາກໄຟລ໌ນີ້
// # ຍ້ອນຫຍັງ: ເປັນຂໍ້ມູນຕົວຢ່າງທີ່ hardcode ໄວ້ໃນແອັບ ໃຊ້ເປັນ fallback ຕອນ API ລົ້ມ
// #          ເຮັດໃຫ້ຜູ້ໃຊ້ເຫັນເນື້ອຫາປອມ ແລະ ປິດບັງບັນຫາຂອງ backend
// # ແກ້ຈາກສ່ວນໃດ: class Mock*Data ທ້າຍໄຟລ໌ ພ້ອມກັບຜູ້ເອີ້ນໃນ api_service.dart
// # ແກ້ເຮັດຫຍັງ: ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຢູ່ Backend/database.sql ເປັນ seed ຂອງຖານຂໍ້ມູນ
// #             ເຊິ່ງເປັນຂໍ້ມູນຈິງທີ່ແກ້ໄຂ/ລຶບໄດ້ຜ່ານໜ້າ Admin
