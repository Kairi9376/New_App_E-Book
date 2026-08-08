import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

import 'picked_file.dart';

export 'picked_file.dart';

// # ເຮັດຫຍັງ: ໂຕຈິງຂອງຊັ້ນ platform - ໄຟລ໌ນີ້ຖືກ compile ສະເພາະຕອນ build ລົງ Web
// # ຍ້ອນຫຍັງ: ເປັນບ່ອນດຽວໃນໂປຣເຈັກທີ່ຍັງແຕະ dart:html ແລະ dart:js ໄດ້
// #          ໂຄ້ດ UI ບໍ່ຕ້ອງຮູ້ຈັກ library ເຫຼົ່ານີ້ອີກ
// # ແກ້ຈາກສ່ວນໃດ: ຍົກມາຈາກ pdf_viewer_screen.dart (ບັນທັດ 46, 64-82, 261-282, 330-339)
// #              ແລະ file_picker_helper.dart (ບັນທັດ 48-81) ແບບຮັກສາ logic ເດີມທຸກຢ່າງ
// # ແກ້ເຮັດຫຍັງ: ພຶດຕິກຳບົນ Web ຄືເກົ່າ 100% ແຕ່ບົນ platform ອື່ນຈະໄປໃຊ້ stub ແທນ
class WebPlatform {
  /// ບົນ Web ຄືນ true ສະເໝີ - ໃຊ້ຢືນຢັນວ່າ implementation ໃດຖືກໂຫຼດເຂົ້າມາ
  static bool get isWeb => true;

  /// ຟັງຂໍ້ຄວາມ postMessage ຈາກ iframe (PDF.js ສົ່ງຈຳນວນໜ້າຈິງກັບມາທາງນີ້)
  static StreamSubscription<Map>? listenToWindowMessages(
    void Function(Map data) onMessage,
  ) {
    return html.window.onMessage
        .where((event) => event.data is Map)
        .map((event) => event.data as Map)
        .listen(onMessage);
  }

  /// ລົງທະບຽນ iframe ເປັນ platform view ໃຫ້ HtmlElementView ເອີ້ນໃຊ້
  static void registerIframeFactory(
    String viewType,
    String Function() buildSrcdoc,
  ) {
    try {
      (js.context as dynamic).platformViewRegistry?.registerViewFactory(
        viewType,
        (int id) {
          final iframe = html.IFrameElement()
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.pointerEvents = 'auto';

          iframe.srcdoc = buildSrcdoc();
          return iframe;
        },
      );
    } catch (e) {
      // ລົງທະບຽນຊ້ຳ viewType ເກົ່າຈະ throw - ບໍ່ແມ່ນຂໍ້ຜິດພາດທີ່ຕ້ອງຢຸດການເຮັດວຽກ
      // ignore: avoid_print
      print('Platform view registration info: $e');
    }
  }

  /// ເປີດ/ປິດການຮັບ mouse ຂອງ iframe ທັງໝົດ
  /// ໃຊ້ຕອນເປີດ Modal ບໍ່ໃຫ້ iframe ແຍ່ງຈັບ event (ຕາມທີ່ລະບຸໄວ້ໃນ GEMINI.md ຂໍ້ 4.D)
  static void setIframePointerEvents(bool enabled) {
    try {
      final iframes = html.document.querySelectorAll('iframe');
      for (var el in iframes) {
        (el as html.IFrameElement).style.pointerEvents =
            enabled ? 'auto' : 'none';
      }
    } catch (_) {}
  }

  /// ເປີດ File Explorer ຂອງ browser ໃຫ້ຜູ້ໃຊ້ເລືອກໄຟລ໌
  static Future<PickedFile?> pickFile(String accept) {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = accept; // e.g. '.pdf' or 'image/*'
    uploadInput.click();

    final completer = Completer<PickedFile?>();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoadEnd.first;
      final bytes = (reader.result as List<int>).toList();

      completer.complete(PickedFile(
        name: file.name,
        bytes: bytes,
        size: file.size,
      ));
    });

    return completer.future;
  }
}
