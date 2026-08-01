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
  final String idCardNumber;
  final String fullName;
  final String idCardImagePath;
  final String selfieImagePath;
  final KycStatus status;
  final String? rejectReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  KycModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.idCardNumber,
    required this.fullName,
    required this.idCardImagePath,
    required this.selfieImagePath,
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

  KycModel copyWith({
    KycStatus? status,
    String? rejectReason,
    DateTime? reviewedAt,
  }) {
    return KycModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      idCardNumber: idCardNumber,
      fullName: fullName,
      idCardImagePath: idCardImagePath,
      selfieImagePath: selfieImagePath,
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
      id: 'kyc_001',
      userId: 'u123',
      userName: 'ສົມຊາຍ ໃຈດີ',
      userEmail: 'user1234@gmail.com',
      idCardNumber: '1-1002-34567-89-0',
      fullName: 'ທ່ານ ສົມຊາຍ ໃຈດີ',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    KycModel(
      id: 'kyc_002',
      userId: 'u124',
      userName: 'ສິລິພອນ ວົງສະຫວັດ',
      userEmail: 'siriporn@gmail.com',
      idCardNumber: '3-5099-00123-45-6',
      fullName: 'ນາງ ສິລິພອນ ວົງສະຫວັດ',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    KycModel(
      id: 'kyc_003',
      userId: 'u125',
      userName: 'ພຣີມ່ຽມ ສະມາຊິກ',
      userEmail: 'member@gmail.com',
      idCardNumber: '1-7099-00987-65-4',
      fullName: 'ທ່ານ ພຣີມ່ຽມ ສະມາຊິກ',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.approved,
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    KycModel(
      id: 'kyc_004',
      userId: 'u126',
      userName: 'ວີຣະໄຊ ມີສຸກ',
      userEmail: 'weerachai@gmail.com',
      idCardNumber: '2-1009-88776-54-3',
      fullName: 'ທ່ານ ວີຣະໄຊ ມີສຸກ',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.rejected,
      rejectReason: 'ຮູບຖ່າຍບັດປະຈຳຕົວບໍ່ຈະແຈ້ງ ກະລຸນາຖ່າຍຮູບໃໝ່ຢູ່ບ່ອນທີ່ມີແສງສະຫວ່າງ',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
