import 'package:flutter/foundation.dart' show kIsWeb;

// # ເຮັດຫຍັງ: ເພີ່ມໄຟລ໌ໃໝ່ເປັນຕົວກາງກຳນົດວ່າ role ໃດເຂົ້າ platform ໃດໄດ້
// # ຍ້ອນຫຍັງ: ຕ້ອງການໃຫ້ Admin/Employee ຢູ່ Web ເທົ່ານັ້ນ ແລະ User/Member ຢູ່ Flutter App
// #          ເທົ່ານັ້ນ ຖ້າກະຈາຍເງື່ອນໄຂໄປໃສ່ແຕ່ລະໜ້າ ຈະລືມບ່ອນໃດບ່ອນໜຶ່ງແລ້ວຮົ່ວ
// # ແກ້ຈາກສ່ວນໃດ: ແຕ່ກ່ອນ login_screen.dart ຕັດສິນ role ເອງດ້ວຍ if/else ໂດຍບໍ່ສົນ platform
// # ແກ້ເຮັດຫຍັງ: ລວມກົດເກນໄວ້ບ່ອນດຽວ ໃຫ້ໜ້າ login, main.dart ແລະ ການກູ້ session
// #             ອ້າງອີງແຫຼ່ງດຽວກັນໝົດ

/// ກຸ່ມສິດການໃຊ້ງານ - ແຍກຕາມ platform ທີ່ອະນຸຍາດ
enum AuthAudience {
  /// Admin ແລະ Employee - ໃຊ້ໄດ້ບົນ Web ເທົ່ານັ້ນ
  staff,

  /// User ທົ່ວໄປ ແລະ Premiere Member - ໃຊ້ໄດ້ບົນ Flutter App ເທົ່ານັ້ນ
  customer,
}

class AuthGate {
  // # ເຮັດຫຍັງ: ລວມຊື່ role ດິບຈາກຖານຂໍ້ມູນໄວ້ເປັນຄ່າຄົງທີ່
  // # ຍ້ອນຫຍັງ: ຖານຂໍ້ມູນເກັບພຽງ 3 role (admin, employee, user) ສ່ວນ "member" ບໍ່ແມ່ນ role
  // #          ແຕ່ແມ່ນ user ທີ່ມີ subscription ຈຶ່ງຕ້ອງນັບ member ເປັນ customer ນຳ
  // # ແກ້ຈາກສ່ວນໃດ: ແຕ່ກ່ອນ login_screen.dart ຂຽນ 'admin'/'employee' ເປັນ string ຝັງໄວ້
  // # ແກ້ເຮັດຫຍັງ: ພິມຜິດຈະເປັນ compile error ແທນທີ່ຈະກາຍເປັນ bug ຕອນ runtime
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';
  static const String roleUser = 'user';

  static const Set<String> _staffRoles = {roleAdmin, roleEmployee};

  /// ຈັດ role ດິບເຂົ້າກຸ່ມສິດ - role ທີ່ບໍ່ຮູ້ຈັກຖືເປັນ customer ຕາມຄ່າເລີ່ມຕົ້ນ
  /// ເພາະເປັນສິດຕໍ່າສຸດ (ຫຼັກ fail-safe: ຜິດພາດແລ້ວໃຫ້ໄດ້ສິດໜ້ອຍ ບໍ່ແມ່ນໄດ້ສິດຫຼາຍ)
  static AuthAudience audienceOf(String? role) {
    final normalized = (role ?? '').trim().toLowerCase();
    return _staffRoles.contains(normalized)
        ? AuthAudience.staff
        : AuthAudience.customer;
  }

  /// ກຸ່ມສິດທີ່ platform ປັດຈຸບັນຮອງຮັບ - Web ຮັບແຕ່ staff, App ຮັບແຕ່ customer
  static AuthAudience get audienceForPlatform =>
      kIsWeb ? AuthAudience.staff : AuthAudience.customer;

  /// role ນີ້ເຂົ້າໃຊ້ platform ປັດຈຸບັນໄດ້ບໍ່
  static bool isAllowedHere(String? role) =>
      audienceOf(role) == audienceForPlatform;

  // # ເຮັດຫຍັງ: ຄືນຂໍ້ຄວາມແຈ້ງເຫດຜົນຕອນ role ຜິດ platform
  // # ຍ້ອນຫຍັງ: ຖ້າແຈ້ງພຽງ "ເຂົ້າບໍ່ໄດ້" ຜູ້ໃຊ້ຈະເຂົ້າໃຈຜິດວ່າລະຫັດຜ່ານຜິດ ແລ້ວລອງຊ້ຳ
  // # ແກ້ຈາກສ່ວນໃດ: ຂອງເກົ່າບໍ່ມີກໍລະນີນີ້ເລີຍ ເພາະທຸກ role ເຂົ້າໄດ້ໝົດທຸກ platform
  // # ແກ້ເຮັດຫຍັງ: ບອກຊັດວ່າຕ້ອງໄປໃຊ້ຊ່ອງທາງໃດແທນ
  static String deniedMessage(String? role) {
    return audienceOf(role) == AuthAudience.staff
        ? '⛔ ບັນຊີ Admin/ພະນັກງານ ໃຊ້ໄດ້ຜ່ານ Web ເທົ່ານັ້ນ ບໍ່ຮອງຮັບໃນແອັບ'
        : '⛔ ບັນຊີຜູ້ໃຊ້ທົ່ວໄປ/ສະມາຊິກ ໃຊ້ໄດ້ຜ່ານແອັບເທົ່ານັ້ນ ບໍ່ຮອງຮັບໃນ Web';
  }
}
