// # ເຮັດຫຍັງ: ເພີ່ມ class ກາງເກັບຜົນການເລືອກໄຟລ໌ ໃຫ້ຊັ້ນ platform ຄືນຄ່າຊະນິດດຽວກັນ
// # ຍ້ອນຫຍັງ: web_platform_web.dart ກັບ web_platform_stub.dart ຕ້ອງຄືນ type ດຽວກັນ
// #          ຖ້າໃຫ້ຄືນ SelectedFileInfo ຈາກ file_picker_helper.dart ຈະເກີດ import ວົນ
// #          (helper -> platform -> helper) ຈຶ່ງແຍກ type ນີ້ອອກມາເປັນໄຟລ໌ຕ່າງຫາກ
// # ແກ້ຈາກສ່ວນໃດ: ແຕ່ກ່ອນ file_picker_helper.dart ສ້າງ SelectedFileInfo ຈາກ dart:html ໂດຍກົງ
// # ແກ້ເຮັດຫຍັງ: ຊັ້ນ platform ຮູ້ຈັກແຕ່ຂໍ້ມູນດິບ ສ່ວນການນັບໜ້າ PDF ຍັງຢູ່ຊັ້ນເທິງຄືເກົ່າ
class PickedFile {
  final String name;
  final List<int> bytes;
  final int size;

  const PickedFile({
    required this.name,
    required this.bytes,
    required this.size,
  });
}
