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
    required this.idCardImagePath,
    required this.selfieImagePath,
    this.isStudent = false,
    this.schoolName,
    required this.status,
    this.rejectReason,
    required this.submittedAt,
    this.reviewedAt,
  });

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

  factory KycModel.fromMap(Map<String, dynamic> map, {String uploadsBaseUrl = 'http://localhost:5000/uploads'}) {
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
      docImg = '$uploadsBaseUrl/${docImg.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String selfieImg = map['selfie_image_url'] ?? map['selfieImagePath'] ?? '';
    if (selfieImg.startsWith('/uploads/') || selfieImg.startsWith('uploads/')) {
      selfieImg = '$uploadsBaseUrl/${selfieImg.replaceAll(RegExp(r'^/?uploads/'), '')}';
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
    if (fn.isEmpty) fn = map['fullName'] ?? map['user_name'] ?? map['userName'] ?? 'ບໍ່ລະບຸຊື່';

    return KycModel(
      id: (map['kyc_id'] ?? map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      userName: map['user_name'] ?? map['userName'] ?? fn,
      userEmail: map['email'] ?? map['userEmail'] ?? '',
      documentType: map['document_type'] ?? map['documentType'] ?? 'national_id',
      idCardNumber: map['document_number'] ?? map['idCardNumber'] ?? '',
      fullName: fn,
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

class MockKycData {
  static List<KycModel> submissions = [
    KycModel(
      id: '1',
      userId: '3',
      userName: 'ສົມຊາຍ ໃຈດີ',
      userEmail: 'user1234@gmail.com',
      documentType: 'national_id',
      idCardNumber: '1-1002-34567-89-0',
      fullName: 'ທ່ານ ສົມຊາຍ ໃຈດີ',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    KycModel(
      id: '2',
      userId: '4',
      userName: 'ພຣີມ່ຽມ ສະມາຊິກ',
      userEmail: 'member@gmail.com',
      documentType: 'student_card',
      idCardNumber: 'STU-99887766',
      fullName: 'ທ່ານ ພຣີມ່ຽມ ສະມາຊິກ',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      isStudent: true,
      schoolName: 'ມະຫາວິທະຍາໄລແຫ່ງຊາດ',
      status: KycStatus.approved,
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];
}
