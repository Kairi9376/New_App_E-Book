import 'dart:async';

import 'package:file_picker/file_picker.dart';

import 'picked_file.dart';

export 'picked_file.dart';

// # ເຮັດຫຍັງ: ຕົວແທນເປົ່າຂອງຊັ້ນ platform - ຖືກ compile ຕອນ build ລົງ macOS/iOS/Android
// # ຍ້ອນຫຍັງ: ຕ້ອງມີ class ຊື່ ແລະ signature ຄືກັນກັບ web_platform_web.dart ທຸກປະການ
// #          ບໍ່ດັ່ງນັ້ນ conditional export ຈະ compile ບໍ່ຜ່ານ
// # ແກ້ຈາກສ່ວນໃດ: ໄຟລ໌ໃໝ່ ຄູ່ກັບ web_platform_web.dart
// # ແກ້ເຮັດຫຍັງ: ບົນ platform ທີ່ບໍ່ແມ່ນ Web ທຸກ method ບໍ່ເຮັດຫຍັງ ແລະ ບໍ່ throw
// #             ຈຶ່ງ build ຜ່ານ ແລະ ບໍ່ crash - ສ່ວນ UI ຄຸມການສະແດງຜົນເອງດ້ວຍ kIsWeb ຢູ່ແລ້ວ
class WebPlatform {
  /// ບົນ platform ນີ້ຄືນ false ສະເໝີ
  static bool get isWeb => false;

  /// ບໍ່ມີ window.postMessage ນອກ browser - ຄືນ null ໃຫ້ຜູ້ເອີ້ນຂ້າມການ cancel ໄປ
  static StreamSubscription<Map>? listenToWindowMessages(
    void Function(Map data) onMessage,
  ) {
    return null;
  }

  /// ບໍ່ມີ HtmlElementView ນອກ Web - ບໍ່ຕ້ອງລົງທະບຽນຫຍັງ
  static void registerIframeFactory(
    String viewType,
    String Function() buildSrcdoc,
  ) {}

  /// ບໍ່ມີ iframe ນອກ Web - ບໍ່ມີຫຍັງໃຫ້ປັບ
  static void setIframePointerEvents(bool enabled) {}

  // # ເຮັດຫຍັງ: ປ່ຽນຈາກ return null ມາເປັນເປີດຕົວເລືອກໄຟລ໌ຈິງດ້ວຍ package file_picker
  // # ຍ້ອນຫຍັງ: ແຕ່ກ່ອນຄືນ null ສະເໝີນອກ Web ເຮັດໃຫ້ອັບໂຫຼດ KYC, ສະລິບ,
  // #          ຮູບໂປຣໄຟລ໌ ແລະ PDF ໃນແອັບ (Windows/macOS/iOS/Android) ໃຊ້ບໍ່ໄດ້ເລີຍ
  // # ແກ້ຈາກສ່ວນໃດ: pickFile() ຂອງ stub ທີ່ມີແຕ່ "return null;"
  // # ແກ້ເຮັດຫຍັງ: ຄືນ PickedFile ຮູບແບບດຽວກັນກັບຝັ່ງ Web ຊັ້ນເທິງຈຶ່ງບໍ່ຕ້ອງແກ້ຫຍັງ
  static Future<PickedFile?> pickFile(String accept) async {
    // ແປງ accept ແບບ HTML ('image/*', '.pdf') ເປັນ FileType ຂອງ file_picker
    // ເພາະ file_picker ບໍ່ຮັບ MIME string ໂດຍກົງ ຕ້ອງລະບຸເປັນ extension
    final normalized = accept.toLowerCase();
    final isPdfOnly = normalized.contains('pdf') && !normalized.contains('image');

    // # ເຮັດຫຍັງ: ປ່ຽນກັບມາໃຊ້ FilePicker.platform.pickFiles()
    // # ຍ້ອນຫຍັງ: ຫຼັງ merge branch Nutt ເຂົ້າມາ file_picker ຖືກຫຼຸດເປັນ ^5.5.0
    // #          ເຊິ່ງ pickFiles ເປັນ instance member ຢູ່ໃຕ້ FilePicker.platform
    // #          ສ່ວນ static FilePicker.pickFiles() ແມ່ນ API ຂອງຮຸ່ນ 11 ຈຶ່ງ compile ບໍ່ຜ່ານ
    // #          (git ບໍ່ແຈ້ງ conflict ເພາະຄົນລະໄຟລ໌ - ເປັນ semantic conflict)
    // # ແກ້ຈາກສ່ວນໃດ: ບັນທັດທີ່ເອີ້ນ FilePicker.pickFiles() ແບບ static
    // # ແກ້ເຮັດຫຍັງ: ໃຊ້ຮຸ່ນ 5.5.0 ໄດ້ ເຊິ່ງເປັນຮຸ່ນທີ່ Windows (Flutter ເກົ່າກວ່າ)
    // #             ແລະ macOS (Flutter 3.44) ໃຊ້ຮ່ວມກັນໄດ້ທັງສອງເຄື່ອງ
    final result = await FilePicker.platform.pickFiles(
      type: isPdfOnly ? FileType.custom : FileType.image,
      allowedExtensions: isPdfOnly ? const ['pdf'] : null,
      // ຕ້ອງເປັນ true ເພື່ອໃຫ້ໄດ້ bytes ມາເລີຍ ຊັ້ນເທິງສົ່ງ bytes ໄປ backend
      // ໂດຍບໍ່ໄດ້ອ່ານຈາກ path (ແລະ path ໃຊ້ບໍ່ໄດ້ບົນ Web ຢູ່ແລ້ວ)
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    return PickedFile(
      name: file.name,
      bytes: bytes,
      size: file.size,
    );
  }
}
