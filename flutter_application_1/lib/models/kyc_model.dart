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
        return 'ยังไม่ได้ยืนยันตัวตน';
      case KycStatus.pending:
        return 'รอแอดมินอนุมัติ';
      case KycStatus.approved:
        return 'อนุมัติแล้ว (ผ่าน KYC)';
      case KycStatus.rejected:
        return 'ไม่อนุมัติ (ถูกปฏิเสธ)';
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
      userName: 'สมชาย ใจดี',
      userEmail: 'user1234@gmail.com',
      idCardNumber: '1-1002-34567-89-0',
      fullName: 'นาย สมชาย ใจดี',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    KycModel(
      id: 'kyc_002',
      userId: 'u124',
      userName: 'ศิริพร วงศ์สวัสดิ์',
      userEmail: 'siriporn@gmail.com',
      idCardNumber: '3-5099-00123-45-6',
      fullName: 'นางสาว ศิริพร วงศ์สวัสดิ์',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    KycModel(
      id: 'kyc_003',
      userId: 'u125',
      userName: 'พรีเมียร์ สมาชิก',
      userEmail: 'member@gmail.com',
      idCardNumber: '1-7099-00987-65-4',
      fullName: 'นาย พรีเมียร์ สมาชิก',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.approved,
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    KycModel(
      id: 'kyc_004',
      userId: 'u126',
      userName: 'วีระชัย มีสุข',
      userEmail: 'weerachai@gmail.com',
      idCardNumber: '2-1009-88776-54-3',
      fullName: 'นาย วีระชัย มีสุข',
      idCardImagePath: 'assets/sample_id_card.png',
      selfieImagePath: 'assets/sample_selfie.png',
      status: KycStatus.rejected,
      rejectReason: 'ภาพถ่ายบัตรประชาชนไม่ชัดเจน โปรดถ่ายภาพใหม่ในที่สว่าง',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
