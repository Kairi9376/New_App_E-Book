// # ເຮັດຫຍັງ: ປ່ຽນຈາກ import 'dart:html' ໂດຍກົງ ມາໃຊ້ຊັ້ນກາງ web_platform.dart
// # ຍ້ອນຫຍັງ: comment ເກົ່າຂຽນວ່າ "Conditional import" ແຕ່ຂຽນເປັນ import ທຳມະດາ
// #          ບໍ່ມີ if (dart.library.html) ຈຶ່ງບໍ່ conditional ຈິງ ແລະ build ລົງມືຖືບໍ່ໄດ້
// # ແກ້ຈາກສ່ວນໃດ: import 'dart:html' as html; ບັນທັດ 4 ຂອງໄຟລ໌ນີ້
// # ແກ້ເຮັດຫຍັງ: ຍ້າຍການເອີ້ນ DOM ໄປໄວ້ web_platform_web.dart ສ່ວນນີ້ເຫຼືອແຕ່ logic ບໍລິສຸດ
import 'platform/web_platform.dart';

class SelectedFileInfo {
  final String name;
  final List<int> bytes;
  final int size;
  final int pageCount;

  SelectedFileInfo({
    required this.name,
    required this.bytes,
    required this.size,
    int? pageCount,
  }) : pageCount = pageCount ?? (name.toLowerCase().endsWith('.pdf') ? FilePickerHelper.getPdfPageCount(bytes) : 1);
}

class FilePickerHelper {
  /// Extracts total page count directly from PDF binary bytes
  static int getPdfPageCount(List<int> bytes) {
    try {
      final str = String.fromCharCodes(bytes);
      
      // Method 1: Look for /Count N in PDF objects catalog
      final countMatches = RegExp(r'/Count\s+(\d+)').allMatches(str);
      int maxCount = 0;
      for (final match in countMatches) {
        final countStr = match.group(1);
        if (countStr != null) {
          final count = int.tryParse(countStr) ?? 0;
          if (count > maxCount) maxCount = count;
        }
      }
      if (maxCount > 0) return maxCount;

      // Method 2: Count /Type /Page
      final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(str);
      if (pageMatches.isNotEmpty) {
        return pageMatches.length;
      }
    } catch (_) {}
    return 1;
  }

  // # ເຮັດຫຍັງ: ມອບໜ້າທີ່ເປີດ File Explorer ໃຫ້ WebPlatform ແລ້ວຫຸ້ມຜົນເປັນ SelectedFileInfo
  // # ຍ້ອນຫຍັງ: ໂຄ້ດ DOM ຕ້ອງຢູ່ຫຼັງ conditional import ເທົ່ານັ້ນ ຈຶ່ງຈະ build ຂ້າມ platform ໄດ້
  // #          ແລະ ບໍ່ຕ້ອງກວດ kIsWeb ອີກ ເພາະ stub ຄືນ null ໃຫ້ຢູ່ແລ້ວບົນ platform ອື່ນ
  // # ແກ້ຈາກສ່ວນໃດ: pickFile() ເດີມທີ່ເອີ້ນ html.FileUploadInputElement/FileReader ໂດຍກົງ
  // # ແກ້ເຮັດຫຍັງ: ຜົນລັບຄືເກົ່າທຸກປະການ - ບົນ Web ໄດ້ໄຟລ໌, ບົນມືຖື/desktop ໄດ້ null
  // #             ແລະ ການນັບໜ້າ PDF ຍັງເຮັດຢູ່ຊັ້ນນີ້ຜ່ານ constructor ຂອງ SelectedFileInfo
  /// Opens native OS / Browser File Explorer to select a file from user's local disk
  static Future<SelectedFileInfo?> pickFile({required String accept}) async {
    final picked = await WebPlatform.pickFile(accept);
    if (picked == null) return null;

    return SelectedFileInfo(
      name: picked.name,
      bytes: picked.bytes,
      size: picked.size,
    );
  }
}
