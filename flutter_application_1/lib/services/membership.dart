import 'package:flutter/foundation.dart';

import 'api_service.dart';

// # ເຮັດຫຍັງ: ເພີ່ມໄຟລ໌ໃໝ່ເປັນແຫຼ່ງຄວາມຈິງດຽວວ່າ "ຜູ້ໃຊ້ນີ້ເປັນສະມາຊິກ Premiere ບໍ່"
// # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນ 4 ໜ້າຕັດສິນເອງ ແລະ ຕັດສິນດ້ວຍ email ທີ່ hardcode ໄວ້:
// #            role == 'admin' || role == 'employee' || email == 'member@gmail.com'
// #          ຜູ້ໃຊ້ຈິງທີ່ຊື້ແພັກເກັດແລ້ວ (ເຊັ່ນ user1234@gmail.com) ຈຶ່ງບໍ່ເຄີຍຖືກນັບ
// #          ເປັນສະມາຊິກເລີຍ - ໜ້າແພັກເກັດບອກວ່າ "ເປັນສະມາຊິກແລ້ວ" ແຕ່ໜ້າໂປຣໄຟລ໌
// #          ຍັງຂຶ້ນ General User ແລະ ອ່ານປຶ້ມສະເພາະສະມາຊິກບໍ່ໄດ້
// #          ນອກຈາກນັ້ນ ບໍ່ມີໜ້າໃດກວດວັນໝົດອາຍຸເລີຍ - subscription ທີ່ໝົດອາຍຸແລ້ວ
// #          ແຕ່ payment_status ຍັງເປັນ active ຈະຍັງເຂົ້າໄດ້ຢູ່
// # ແກ້ຈາກສ່ວນໃດ: ເງື່ອນໄຂທີ່ກະຈາຍຢູ່ profile_screen, user_home_screen (2 ບ່ອນ),
// #              book_detail_screen ແລະ admin_reports_tab
// # ແກ້ເຮັດຫຍັງ: ລວມໄວ້ບ່ອນດຽວ ອີງ subscription ຈິງ + ກວດວັນໝົດອາຍຸ
// #             ໜ້າຈໍພຽງແຕ່ອ່ານ Membership.isPremiere ບໍ່ຕ້ອງຮູ້ກົດເກນ
class Membership {
  static bool _hasActiveSubscription = false;
  static DateTime? _expiresAt;

  /// ຊື່ແພັກເກັດປັດຈຸບັນ - ໃຊ້ສະແດງຜົນ ບໍ່ໄດ້ໃຊ້ຕັດສິນສິດ
  static String? packageName;

  /// ວັນໝົດອາຍຸ (null = ບໍ່ມີກຳນົດ ເຊັ່ນ admin/employee)
  static DateTime? get expiresAt => _expiresAt;

  // # ເຮັດຫຍັງ: ນັບ admin ແລະ employee ເປັນສະມາຊິກໂດຍບໍ່ຕ້ອງຊື້
  // # ຍ້ອນຫຍັງ: ພະນັກງານຕ້ອງເປີດອ່ານປຶ້ມທຸກຫົວເພື່ອກວດສອບເນື້ອຫາກ່ອນອະນຸມັດ
  // #          ເປັນກົດເກນເດີມທີ່ມີຢູ່ແລ້ວໃນທຸກໜ້າ ຈຶ່ງຮັກສາໄວ້
  // # ແກ້ຈາກສ່ວນໃດ: ເງື່ອນໄຂ role == 'admin' || role == 'employee' ທີ່ຊ້ຳກັນ 4 ບ່ອນ
  // # ແກ້ເຮັດຫຍັງ: ຂຽນບ່ອນດຽວ
  static bool get _isStaff {
    final role = (ApiService.currentUser?['role'] ?? '').toString().toLowerCase();
    return role == 'admin' || role == 'employee';
  }

  /// ຜູ້ໃຊ້ປັດຈຸບັນເປີດອ່ານເນື້ອຫາສະເພາະສະມາຊິກໄດ້ບໍ່
  static bool get isPremiere {
    if (_isStaff) return true;
    if (!_hasActiveSubscription) return false;

    // ໝົດອາຍຸແລ້ວບໍ່ນັບ - ບໍ່ມີ end_date ຖືວ່າບໍ່ມີກຳນົດ
    final exp = _expiresAt;
    return exp == null || exp.isAfter(DateTime.now());
  }

  // # ເຮັດຫຍັງ: ດຶງສະຖານະ subscription ຈາກ backend ມາເກັບໄວ້
  // # ຍ້ອນຫຍັງ: ຕ້ອງມີບ່ອນດຽວທີ່ຕີຄວາມ payment_status ແລະ end_date
  // #          ແທນທີ່ຈະໃຫ້ແຕ່ລະໜ້າອ່ານ map ດິບເອງແລ້ວຕີຄວາມຕ່າງກັນ
  // # ແກ້ຈາກສ່ວນໃດ: book_detail_screen ເຄີຍເອີ້ນ getUserSubscriptionStatus ເອງ
  // #              ສ່ວນໜ້າອື່ນບໍ່ເອີ້ນເລີຍ ຈຶ່ງບໍ່ຮູ້ຈັກ subscription
  // # ແກ້ເຮັດຫຍັງ: ເອີ້ນຫຼັງ login ແລະ ຫຼັງກູ້ session ໃຫ້ທຸກໜ້າໄດ້ຄ່າດຽວກັນ
  static Future<void> refresh() async {
    if (_isStaff) {
      _hasActiveSubscription = true;
      _expiresAt = null;
      return;
    }

    final rawId =
        ApiService.currentUser?['user_id'] ?? ApiService.currentUser?['id'];
    final userId = int.tryParse(rawId?.toString() ?? '');
    if (userId == null) {
      clear();
      return;
    }

    // # ເຮັດຫຍັງ: ຮັກສາຄ່າເກົ່າໄວ້ຖ້າຄຳຮ້ອງລົ້ມເຫຼວ ລ້າງສະເພາະຕອນ server ຢືນຢັນວ່າບໍ່ມີ
    // # ຍ້ອນຫຍັງ: refresh() ຖືກເອີ້ນທຸກຄັ້ງທີ່ເປີດໜ້າປຶ້ມ ຖ້າເນັດສະດຸດຄັ້ງດຽວ
    // #          ແລ້ວລ້າງສິດຖິ້ມ ສະມາຊິກຈະຖືກກັ້ນທັນທີໂດຍບໍ່ມີສາເຫດທີ່ອະທິບາຍໄດ້
    // # ແກ້ຈາກສ່ວນໃດ: ບລັອກທີ່ຮັບ null ຈາກ getUserSubscriptionStatus ແລ້ວ clear() ເລີຍ
    // # ແກ້ເຮັດຫຍັງ: null = server ບອກວ່າບໍ່ມີແພັກເກັດ (ລ້າງຖືກຕ້ອງ)
    // #             exception = ຕິດຕໍ່ບໍ່ໄດ້ (ຮັກສາຄ່າເກົ່າ ແລ້ວລອງໃໝ່ຮອບໜ້າ)
    final Map<String, dynamic>? sub;
    try {
      sub = await ApiService.getUserSubscriptionStatus(userId);
    } catch (e) {
      debugPrint('Membership: ດຶງສະຖານະບໍ່ໄດ້ ($e) - ຮັກສາຄ່າເກົ່າໄວ້');
      return;
    }

    if (sub == null) {
      clear();
      return;
    }

    // backend ຄືນ payment_status ສ່ວນ 'status' ເປັນຊື່ສຳຮອງທີ່ບາງ endpoint ໃຊ້
    final status =
        (sub['status'] ?? sub['payment_status'] ?? '').toString().toLowerCase();
    _hasActiveSubscription = status == 'active' || status == 'approved';

    _expiresAt = DateTime.tryParse(
      (sub['end_date'] ?? sub['expires_at'] ?? '').toString(),
    );
    packageName = sub['package_name']?.toString();

    debugPrint(
      'Membership: active=$_hasActiveSubscription exp=$_expiresAt pkg=$packageName',
    );
  }

  /// ລ້າງຕອນອອກຈາກລະບົບ - ບໍ່ດັ່ງນັ້ນຜູ້ໃຊ້ຄົນຕໍ່ໄປຈະສືບທອດສິດຂອງຄົນກ່ອນ
  static void clear() {
    _hasActiveSubscription = false;
    _expiresAt = null;
    packageName = null;
  }
}
