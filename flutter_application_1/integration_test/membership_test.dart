import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/membership.dart';
import 'package:flutter_application_1/services/api_config.dart';

// # ເຮັດຫຍັງ: ເພີ່ມ integration test ທີ່ແລ່ນ ApiService.login ແລະ Membership.refresh
// #          ດ້ວຍ backend ຈິງ ບົນ platform ຈິງ (macOS/Windows)
// # ຍ້ອນຫຍັງ: ຜູ້ໃຊ້ລາຍງານວ່າຊື້ແພັກເກັດແລ້ວແຕ່ຍັງອ່ານປຶ້ມສະເພາະສະມາຊິກບໍ່ໄດ້
// #          ຂະນະທີ່ curl ຢືນຢັນວ່າ backend ຄືນ payment_status=active ຖືກຕ້ອງ
// #          ຈຶ່ງຕ້ອງມີຫຼັກຖານຕອນ runtime ວ່າຝັ່ງແອັບຕີຄວາມຄ່ານັ້ນແນວໃດ
// # ແກ້ຈາກສ່ວນໃດ: integration_test ເດີມຍິງ http ດິບໄປ port 5000 (ຜິດ) ແລະ
// #              ບໍ່ໄດ້ແຕະ ApiService/Membership ເລີຍ ຈຶ່ງຈັບ bug ຊັ້ນນີ້ບໍ່ໄດ້
// # ແກ້ເຮັດຫຍັງ: ເອີ້ນຜ່ານຊັ້ນຈິງທີ່ແອັບໃຊ້ ເພື່ອໃຫ້ຜົນທົດສອບສະທ້ອນພຶດຕິກຳຈິງ
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Membership resolution against the live backend', () {
    testWidgets('base URL points at the running backend', (tester) async {
      // ignore: avoid_print
      print('BASE URL = ${ApiConfig.baseUrl}');
      expect(ApiConfig.baseUrl.contains('5001'), isTrue,
          reason: 'ApiConfig.apiPort ຕ້ອງຕົງກັບ ports: ໃນ docker-compose.yml');
    });

    testWidgets('subscriber is recognised as Premiere', (tester) async {
      final result =
          await ApiService.login('user1234@gmail.com', 'user1234');
      // ignore: avoid_print
      print('LOGIN success=${result['success']} msg=${result['message']}');
      expect(result['success'], isTrue, reason: 'login ຕ້ອງຜ່ານກ່ອນ');

      // ignore: avoid_print
      print('currentUser = ${ApiService.currentUser}');

      final rawId = ApiService.currentUser?['user_id'];
      // ignore: avoid_print
      print('user_id ດິບ = $rawId (${rawId.runtimeType})');

      final sub = await ApiService.getUserSubscriptionStatus(
          int.parse(rawId.toString()));
      // ignore: avoid_print
      print('subscription = $sub');
      expect(sub, isNotNull,
          reason: 'getUserSubscriptionStatus ຄືນ null = ຄຳຮ້ອງລົ້ມເຫຼວ');

      await Membership.refresh();
      // ignore: avoid_print
      print('isPremiere=${Membership.isPremiere} '
          'expiresAt=${Membership.expiresAt} pkg=${Membership.packageName}');

      expect(Membership.isPremiere, isTrue,
          reason: 'ຜູ້ໃຊ້ນີ້ມີ subscription active ຈຶ່ງຕ້ອງເປັນ Premiere');
    });


    // # ເຮັດຫຍັງ: ທົດສອບດ່ານກັ້ນຈິງຂອງໜ້າລາຍລະອຽດປຶ້ມ (ເສັ້ນທາງທີ່ຜູ້ໃຊ້ລາຍງານ)
    // # ຍ້ອນຫຍັງ: test ກ່ອນໜ້າພິສູດແຕ່ວ່າ Membership ຖືກ ແຕ່ບໍ່ໄດ້ພິສູດວ່າ
    // #          ເງື່ອນໄຂ `!isFree && !isMember` ໃນ _openReader() ຈະປ່ອຍຜ່ານຫຼືບໍ່
    // #          ຊຶ່ງຕ້ອງອາໄສ BookModel.isFree ທີ່ແປງມາຈາກ is_free ຂອງ backend ນຳ
    // # ແກ້ຈາກສ່ວນໃດ: ບໍ່ເຄີຍມີ test ຄຸມເສັ້ນທາງນີ້
    // # ແກ້ເຮັດຫຍັງ: ຈຳລອງເງື່ອນໄຂດຽວກັນກັບ _openReader ເພື່ອຢືນຢັນວ່າເປີດອ່ານໄດ້
    testWidgets('paid book opens for a subscriber', (tester) async {
      await ApiService.login('user1234@gmail.com', 'user1234');
      await Membership.refresh();

      final book = await ApiService.getBookById('6');
      // ignore: avoid_print
      print('BOOK id=${book?.id} title=${book?.title} isFree=${book?.isFree}');
      expect(book, isNotNull, reason: 'ຕ້ອງໂຫຼດ Gold Block ໄດ້');

      final isFree = book?.isFree ?? true;
      final isMember = Membership.isPremiere;
      final blocked = !isFree && !isMember;
      // ignore: avoid_print
      print('GATE isFree=$isFree isMember=$isMember -> blocked=$blocked');

      expect(blocked, isFalse,
          reason: 'ສະມາຊິກທີ່ມີແພັກເກັດ active ຕ້ອງເປີດອ່ານປຶ້ມ VIP ໄດ້');
    });

    testWidgets('logout clears the cached membership', (tester) async {
      await ApiService.login('user1234@gmail.com', 'user1234');
      expect(Membership.isPremiere, isTrue);

      await ApiService.clearSession();
      expect(Membership.isPremiere, isFalse,
          reason: 'ອອກຈາກລະບົບແລ້ວສິດຕ້ອງຫາຍໄປ');
    });
  });
}
