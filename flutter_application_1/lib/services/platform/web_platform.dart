// # ເຮັດຫຍັງ: ເພີ່ມໜ້າກາກ (facade) ເລືອກ implementation ຕອນ compile ຕາມ platform
// # ຍ້ອນຫຍັງ: ໂຄ້ດເກົ່າ import 'dart:html' ແລະ 'dart:js' ໂດຍກົງໃນ pdf_viewer_screen.dart
// #          ແລະ file_picker_helper.dart ເຊິ່ງສອງ library ນີ້ມີແຕ່ບົນ Web ເທົ່ານັ້ນ
// #          ເຮັດໃຫ້ build ລົ້ມທັນທີບົນ macOS/iOS/Android ດ້ວຍ
// #          "Dart library 'dart:html' is not available on this platform"
// #          ການຫຸ້ມດ້ວຍ if (kIsWeb) ຊ່ວຍບໍ່ໄດ້ ເພາະ compiler ຕ້ອງ resolve import ກ່ອນ
// #          ຈະຮອດ runtime
// # ແກ້ຈາກສ່ວນໃດ: ຍົກທຸກການເອີ້ນ dart:html/dart:js ອອກຈາກ 2 ໄຟລ໌ນັ້ນມາລວມໄວ້ນີ້
// # ແກ້ເຮັດຫຍັງ: ໃຊ້ conditional export - ບົນ Web ໄດ້ຕົວຈິງ ບົນ platform ອື່ນໄດ້ຕົວເປົ່າ
// #             ຈຶ່ງ build ໄດ້ທຸກ platform ໂດຍພຶດຕິກຳບົນ Web ບໍ່ປ່ຽນ
export 'web_platform_stub.dart' if (dart.library.html) 'web_platform_web.dart';
