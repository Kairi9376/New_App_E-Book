// # ເຮັດຫຍັງ: ປ່ຽນ print() ເປັນ debugPrint() ທັງໄຟລ໌
// # ຍ້ອນຫຍັງ: print() ຖືກຮັກສາໄວ້ໃນ release build ຈຶ່ງຮົ່ວລາຍລະອຽດ error ຂອງ API
// #          ອອກສູ່ log ຂອງເຄື່ອງຜູ້ໃຊ້ ແລະ ຖ້າຂໍ້ຄວາມຍາວເກີນ Android ຈະຕັດຖິ້ມກາງຄັນ
// #          ສ່ວນ debugPrint ຈຳກັດອັດຕາການພິມ ແລະ ຖືກຕັດອອກຕອນ build release
// # ແກ້ຈາກສ່ວນໃດ: ທຸກຈຸດທີ່ເອີ້ນ print() ໃນ catch block ຂອງໄຟລ໌ນີ້
// # ແກ້ເຮັດຫຍັງ: log ຍັງເຫັນຕອນ debug ຄືເກົ່າ ແຕ່ບໍ່ຕິດໄປກັບ build ທີ່ສົ່ງມອບ
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_model.dart';
import '../models/history_model.dart';
import '../models/saved_model.dart';
import '../models/downloads_model.dart';
import '../models/kyc_model.dart';
import '../models/notification_model.dart';
import 'api_config.dart';
import 'membership.dart';

class ApiService {
  // Shared token & session data
  static String? authToken;
  static Map<String, dynamic>? currentUser;

  // Persistent Session Management
  static Future<void> saveSession(
      Map<String, dynamic> user, String? token) async {
    currentUser = user;
    authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user));
      if (token != null) {
        await prefs.setString('authToken', token);
      } else {
        await prefs.remove('authToken');
      }
    } catch (e) {
      debugPrint('ApiService saveSession error: $e');
    }
  }

  static Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('currentUser');
      final token = prefs.getString('authToken');

      if (userStr != null && userStr.isNotEmpty) {
        currentUser = jsonDecode(userStr);
        authToken = token;
        return true;
      }
    } catch (e) {
      debugPrint('ApiService loadSession error: $e');
    }
    return false;
  }

  static Future<void> clearSession() async {
    currentUser = null;
    authToken = null;
    // # ເຮັດຫຍັງ: ລ້າງສະຖານະສະມາຊິກພ້ອມ session
    // # ຍ້ອນຫຍັງ: Membership ເປັນ static ຖ້າບໍ່ລ້າງ ຜູ້ໃຊ້ຄົນຕໍ່ໄປທີ່ login
    // #          ໃນເຄື່ອງດຽວກັນຈະສືບທອດສິດ Premiere ຂອງຄົນກ່ອນໜ້າ
    // # ແກ້ຈາກສ່ວນໃດ: clearSession() ທີ່ລ້າງແຕ່ currentUser ກັບ authToken
    // # ແກ້ເຮັດຫຍັງ: ອອກຈາກລະບົບແລ້ວສິດຫາຍໄປພ້ອມກັນ
    Membership.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      await prefs.remove('authToken');
    } catch (e) {
      debugPrint('ApiService clearSession error: $e');
    }
  }


  // # ເຮັດຫຍັງ: ເພີ່ມ helper ອ່ານ user_id ຂອງຜູ້ທີ່ login ຢູ່ ຄືນ null ຖ້າບໍ່ມີ
  // # ຍ້ອນຫຍັງ: ທົ່ວໄຟລ໌ນີ້ຂຽນ `user['user_id'] ?? 3` ຢູ່ 9 ບ່ອນ ຊຶ່ງແປວ່າ
  // #          ຖ້າບໍ່ມີຜູ້ໃຊ້ login ຢູ່ ການກະທຳຈະຖືກບັນທຶກໃສ່ບັນຊີ user_id = 3
  // #          (ສົມຊາຍ ໃຈດີ) ໂດຍອັດຕະໂນມັດ - ປະຫວັດການອ່ານ, ບຸກມາກ, ດາວໂຫຼດ
  // #          ແລະ KYC ຂອງຄົນອື່ນຈຶ່ງອາດຖືກຂຽນທັບບັນຊີນັ້ນ
  // # ແກ້ຈາກສ່ວນໃດ: ຄ່າເລີ່ມຕົ້ນ `?? 3` ທີ່ກະຈາຍຢູ່ທົ່ວ ApiService
  // # ແກ້ເຮັດຫຍັງ: ຜູ້ເອີ້ນຕ້ອງກວດ null ແລ້ວຢຸດ ແທນທີ່ຈະຂຽນໃສ່ບັນຊີຜິດຄົນ
  static int? get currentUserId {
    final raw = currentUser?['user_id'] ?? currentUser?['id'];
    return int.tryParse(raw?.toString() ?? '');
  }

  // Headers helper
  static Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (authToken != null) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  // 1. Authentication: Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'login_input': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        authToken = data['token'];
        currentUser = data['user'];
        await saveSession(currentUser!, authToken);
        // # ເຮັດຫຍັງ: ດຶງສະຖານະສະມາຊິກທັນທີຫຼັງ login ສຳເລັດ
        // # ຍ້ອນຫຍັງ: ໜ້າຈໍທີ່ເປີດຕໍ່ຈາກ login ອ່ານ Membership.isPremiere ທັນທີ
        // #          ຖ້າບໍ່ດຶງກ່ອນ ຈະໄດ້ຄ່າ false ຂອງຜູ້ໃຊ້ຄົນກ່ອນ ຫຼື ຄ່າເລີ່ມຕົ້ນ
        // # ແກ້ຈາກສ່ວນໃດ: login() ທີ່ບັນທຶກ session ແລ້ວຄືນຜົນເລີຍ
        // # ແກ້ເຮັດຫຍັງ: ຮັບປະກັນວ່າສິດຖືກຕ້ອງຕັ້ງແຕ່ໜ້າທຳອິດຫຼັງເຂົ້າລະບົບ
        await Membership.refresh();
        return {'success': true, 'token': authToken, 'user': currentUser};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ'
        };
      }
    } catch (e) {
      // # ເຮັດຫຍັງ: ຕັດ _mockLoginFallback ອອກ ຕອນຕິດຕໍ່ server ບໍ່ໄດ້ໃຫ້ລົ້ມເຫຼວ
      // # ຍ້ອນຫຍັງ: ຂອງເກົ່າສ້າງ session admin (user_id 1) ໃນເຄື່ອງ **ໂດຍບໍ່ມີ token**
      // #          ຜູ້ໃຊ້ຈຶ່ງເຫັນໜ້າ Admin ເຕັມຮູບແບບ ແຕ່ທຸກຄຳຮ້ອງຈະ 401
      // #          ກາຍເປັນແອັບທີ່ເບິ່ງຄືເຂົ້າໄດ້ແຕ່ໃຊ້ຫຍັງບໍ່ໄດ້ ແລະ ຫຼອກຜູ້ໃຊ້
      // # ແກ້ຈາກສ່ວນໃດ: catch ຂອງ login() ທີ່ເອີ້ນ _mockLoginFallback ແລ້ວ saveSession
      // # ແກ້ເຮັດຫຍັງ: ແຈ້ງບອກຊັດວ່າຕິດຕໍ່ server ບໍ່ໄດ້ ຜູ້ໃຊ້ຈຶ່ງຮູ້ວ່າຕ້ອງກວດເນັດ/backend
      return {
        'success': false,
        'message': 'ຕິດຕໍ່ server ບໍ່ໄດ້ ກະລຸນາກວດການເຊື່ອມຕໍ່ແລ້ວລອງໃໝ່',
      };
    }
  }

  // 2. Authentication: Register (General User Registration)
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              ...userData,
              'role': 'user', // Enforce General User role
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['token'] != null) authToken = data['token'];
        if (data['user'] != null) currentUser = data['user'];
        return {
          'success': true,
          'message': 'ລົງທະບຽນສຳເລັດ',
          'user': data['user']
        };
      }
      return data;
    } catch (e) {
      // # ເຮັດຫຍັງ: ຕັດ mock registration ອອກ
      // # ຍ້ອນຫຍັງ: ຂອງເກົ່າແຈ້ງ "ລົງທະບຽນສຳເລັດ" ພ້ອມສ້າງ user ປອມໃນໜ່ວຍຄວາມຈຳ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ບັນທຶກຫຍັງເລີຍ ຜູ້ໃຊ້ຈຶ່ງເຊື່ອວ່າມີບັນຊີແລ້ວ
      // #          ແຕ່ພໍ login ຮອບໜ້າຈະເຂົ້າບໍ່ໄດ້ ໂດຍບໍ່ຮູ້ສາເຫດ
      // # ແກ້ຈາກສ່ວນໃດ: catch ຂອງ register() ທີ່ຄືນ success:true ພ້ອມ newMockUser
      // # ແກ້ເຮັດຫຍັງ: ບອກຄວາມຈິງວ່າລົງທະບຽນບໍ່ສຳເລັດ
      return {
        'success': false,
        'message': 'ຕິດຕໍ່ server ບໍ່ໄດ້ ລົງທະບຽນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່',
      };
    }
  }

  // 3. Books: Fetch all books
  static Future<List<BookModel>> getBooks({
    String? search,
    String? categoryId,
    bool? isFree,
    String? status,
    String? uploadedBy,
    String? role,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }
      if (isFree != null) queryParams['is_free'] = isFree ? 'true' : 'false';
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (uploadedBy != null && uploadedBy.isNotEmpty) {
        queryParams['uploaded_by'] = uploadedBy;
      }

      final userRole = role ?? currentUser?['role'];
      if (userRole != null && userRole.toString().isNotEmpty) {
        queryParams['role'] = userRole.toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/books')
          .replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['books'] is List) {
          final List rawList = data['books'];
          return rawList
              .map((item) => BookModel.fromMap(item,
                  uploadsBaseUrl: ApiConfig.uploadsBaseUrl))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService getBooks error: $e');
    }

    // # ເຮັດຫຍັງ: ຄືນລາຍການຫວ່າງ ແທນທີ່ຈະຄືນ _allMockBooks()
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າສະແດງປຶ້ມປອມທີ່ hardcode ໄວ້ຕອນ backend ຕິດຕໍ່ບໍ່ໄດ້
    // #          ຜູ້ໃຊ້ຈຶ່ງເຫັນຄັງປຶ້ມທີ່ບໍ່ມີຢູ່ຈິງ ກົດເຂົ້າອ່ານກໍ່ບໍ່ໄດ້
    // #          ແລະ ຜູ້ພັດທະນາກໍ່ບໍ່ຮູ້ວ່າ backend ລົ້ມ ເພາະໜ້າຈໍຍັງມີຂໍ້ມູນຢູ່
    // # ແກ້ຈາກສ່ວນໃດ: ບັນທັດສຸດທ້າຍຂອງ getBooks() ທີ່ return _allMockBooks()
    // # ແກ້ເຮັດຫຍັງ: ລາຍການຫວ່າງເປັນຄວາມຈິງ - UI ຈະສະແດງ "ບໍ່ມີປຶ້ມ" ຢ່າງຖືກຕ້ອງ
    return [];
  }

  // 4. Books: Get book detail
  static Future<BookModel?> getBookById(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$id');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['book'] != null) {
          return BookModel.fromMap(data['book'],
              uploadsBaseUrl: ApiConfig.uploadsBaseUrl);
        }
      }
    } catch (e) {
      debugPrint('ApiService getBookById error: $e');
    }

    // # ເຮັດຫຍັງ: ຄືນ null ແທນທີ່ຈະຄົ້ນຫາໃນ _allMockBooks()
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຮ້າຍກວ່າ getBooks ອີກ - ຖ້າຫາ id ບໍ່ພົບໃນ mock
    // #          ມັນຄືນ "ປຶ້ມຫົວທຳອິດ" ແທນ ຜູ້ໃຊ້ຈຶ່ງກົດປຶ້ມ A ແຕ່ໄດ້ປຶ້ມ B
    // # ແກ້ຈາກສ່ວນໃດ: ບລັອກ fallback ທ້າຍ getBookById() ທີ່ firstWhere ແລ້ວ .first
    // # ແກ້ເຮັດຫຍັງ: null ບອກຜູ້ເອີ້ນວ່າໂຫຼດບໍ່ໄດ້ ໃຫ້ UI ແຈ້ງເຕືອນຢ່າງຖືກຕ້ອງ
    return null;
  }

  // 5. Books: Create / Add new book (For Employee)
  static Future<Map<String, dynamic>> createBook(
      Map<String, dynamic> bookData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(bookData),
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('ApiService createBook error: $e');
      return {
        'success': false,
        'message': 'ບໍ່ສາມາດບັນທຶກປຶ້ມໄປຍັງຫຼັງບ້ານໄດ້: $e'
      };
    }
  }

  // 6. Multipart Upload: Upload PDF / Cover file
  static Future<Map<String, dynamic>> uploadFile({
    required List<int> bytes,
    required String filename,
    required String fieldName, // e.g. 'cover' or 'pdf' or 'slip'
    String? oldFileUrl,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/upload');
      final request = http.MultipartRequest('POST', url);

      // # ເຮັດຫຍັງ: ຕິດ Authorization header ໃສ່ຄຳຮ້ອງອັບໂຫຼດ
      // # ຍ້ອນຫຍັງ: MultipartRequest ບໍ່ໄດ້ໃຊ້ _headers ຄືກັບຄຳຮ້ອງອື່ນ ຈຶ່ງບໍ່ເຄີຍສົ່ງ
      // #          token ໄປເລີຍ ພໍ backend ຕິດ requireAuth ໃສ່ /api/upload ແລ້ວ
      // #          ການອັບໂຫຼດທຸກຢ່າງຈະ 401 ທັນທີ
      // # ແກ້ຈາກສ່ວນໃດ: uploadFile() ທີ່ສ້າງ MultipartRequest ໂດຍບໍ່ຕັ້ງ headers
      // # ແກ້ເຮັດຫຍັງ: ໃສ່ສະເພາະ Authorization ບໍ່ໃສ່ Content-Type ເພາະ multipart
      // #             ຕ້ອງໃຫ້ package ກຳນົດ boundary ເອງ
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      if (oldFileUrl != null && oldFileUrl.isNotEmpty) {
        request.fields['old_file_url'] = oldFileUrl;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final uploadsMap = data['uploads'] as Map<String, dynamic>? ?? {};
        final uploadInfo = uploadsMap[fieldName] ??
            (uploadsMap.isNotEmpty ? uploadsMap.values.first : {});

        final fileUrl =
            uploadInfo['url'] ?? '${ApiConfig.baseUrl}/uploads/$filename';
        final filePath = uploadInfo['path'] ?? 'uploads/$filename';

        return {
          'success': true,
          'url': fileUrl,
          'path': filePath,
          'filename': uploadInfo['filename'] ?? filename
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'ອັບໂຫຼດບໍ່ສຳເລັດ'
        };
      }
    } catch (e) {
      debugPrint('ApiService uploadFile error: $e');
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫຼດ: $e'};
    }
  }

  // 7. Categories: Fetch list of categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/categories');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['categories'] is List) {
          return List<Map<String, dynamic>>.from(data['categories']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getCategories error: $e');
    }

    return [
      {'category_id': 1, 'name': 'ຊີວະປະຫວັດ / ຊີວິດ'},
      {'category_id': 2, 'name': 'ວິທະຍາສາດ / Physics'},
      {'category_id': 3, 'name': 'ເຕັກໂນໂລຊີ / Computer'},
      {'category_id': 4, 'name': 'ສິນລະປະ / ວັນນະຄະດີ'},
      {'category_id': 5, 'name': 'ຄະນິດສາດ'},
    ];
  }

  // 8. Users: Fetch all users (For Admin)
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['users'] is List) {
          return List<Map<String, dynamic>>.from(data['users']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getUsers error: $e');
    }

    return [
      {
        'user_id': 1,
        'email': 'admin@gmail.com',
        'first_name': 'ຜູ້ດູແລ',
        'last_name': 'ລະບົບ (Admin)',
        'role': 'admin',
        'status': 'active'
      },
      {
        'user_id': 2,
        'email': 'employee@gmail.com',
        'first_name': 'ພະນັກງານ',
        'last_name': 'ຈັດການຄັງ',
        'role': 'employee',
        'status': 'active'
      },
      {
        'user_id': 3,
        'email': 'user1234@gmail.com',
        'first_name': 'ສົມຊາຍ',
        'last_name': 'ໃຈດີ',
        'role': 'user',
        'status': 'active'
      },
      {
        'user_id': 4,
        'email': 'member@gmail.com',
        'first_name': 'ພຣີມ່ຽມ',
        'last_name': 'ສະມາຊິກ',
        'role': 'user',
        'status': 'active'
      },
    ];
  }

  // 9. Users: Update status (For Admin)
  static Future<bool> updateUserStatus(int userId, String status,
      {String? reason}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/status');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({'status': status, 'suspended_reason': reason}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateUserStatus error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນຈາກ return true ເປັນ return false ຕອນເກີດ exception
      // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຄືນ true ໃຫ້ "offline dev mode" ເຮັດໃຫ້ UI ຂຶ້ນວ່າສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ບັນທຶກຫຍັງເລີຍ - ນີ້ຄືເຫດຜົນທີ່ bug
      // #          "ເພີ່ມພະນັກງານບໍ່ໄດ້" ຖືກປິດບັງໄວ້ດົນ ເພາະ 404 ຂອງ Express
      // #          ຄືນ HTML ເຮັດໃຫ້ jsonDecode throw ແລ້ວຕົກມາທາງນີ້ພໍດີ
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ createUser, updateUser ແລະ updateUserStatus
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ຜູ້ໃຊ້ຈຶ່ງເຫັນບັນຫາຈິງ
      return false;
    }
  }

  // 9.1 Users: Update Full User Information (For Admin)
  static Future<bool> updateUser(
      int userId, Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateUser error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນຈາກ return true ເປັນ return false ຕອນເກີດ exception
      // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຄືນ true ໃຫ້ "offline dev mode" ເຮັດໃຫ້ UI ຂຶ້ນວ່າສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ບັນທຶກຫຍັງເລີຍ - ນີ້ຄືເຫດຜົນທີ່ bug
      // #          "ເພີ່ມພະນັກງານບໍ່ໄດ້" ຖືກປິດບັງໄວ້ດົນ ເພາະ 404 ຂອງ Express
      // #          ຄືນ HTML ເຮັດໃຫ້ jsonDecode throw ແລ້ວຕົກມາທາງນີ້ພໍດີ
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ createUser, updateUser ແລະ updateUserStatus
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ຜູ້ໃຊ້ຈຶ່ງເຫັນບັນຫາຈິງ
      return false;
    }
  }

  // 9.2 Users: Create User (For Admin)
  static Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true;
    } catch (e) {
      debugPrint('ApiService createUser error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນຈາກ return true ເປັນ return false ຕອນເກີດ exception
      // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຄືນ true ໃຫ້ "offline dev mode" ເຮັດໃຫ້ UI ຂຶ້ນວ່າສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ບັນທຶກຫຍັງເລີຍ - ນີ້ຄືເຫດຜົນທີ່ bug
      // #          "ເພີ່ມພະນັກງານບໍ່ໄດ້" ຖືກປິດບັງໄວ້ດົນ ເພາະ 404 ຂອງ Express
      // #          ຄືນ HTML ເຮັດໃຫ້ jsonDecode throw ແລ້ວຕົກມາທາງນີ້ພໍດີ
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ createUser, updateUser ແລະ updateUserStatus
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ຜູ້ໃຊ້ຈຶ່ງເຫັນບັນຫາຈິງ
      return false;
    }
  }

  // 10. KYC: Fetch all submissions (For Admin)
  static Future<List<Map<String, dynamic>>> getKycList() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/kyc');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['kyc_list'] is List) {
          return List<Map<String, dynamic>>.from(data['kyc_list']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getKycList error: $e');
    }

    return [];
  }

  // 11. KYC: Update status (For Admin)
  static Future<bool> updateKycStatus(int kycId, String status,
      {int? reviewedBy, String? rejectionReason}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/kyc/$kycId/status');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              'status': status,
              'reviewed_by': reviewedBy ?? 1,
              'rejection_reason': rejectionReason
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateKycStatus error: $e');
      return false;
    }
  }

  // 11.1 KYC: Submit Verification (For User)
  static Future<bool> submitKyc(Map<String, dynamic> kycData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/kyc');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(kycData),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true;
    } catch (e) {
      debugPrint('ApiService submitKyc error: $e');
      return false;
    }
  }

  // 11.2 KYC: Get User KYC Status (For User)
  static Future<KycModel?> getUserKycStatus(int userId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/kyc/user/$userId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['kyc'] != null) {
          return KycModel.fromMap(data['kyc']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getUserKycStatus error: $e');
      return null;
    }
  }

  // 12. Books: Update book (For Admin/Employee)
  static Future<bool> updateBook(
      String bookId, Map<String, dynamic> updateData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$bookId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode(updateData),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateBook error: $e');
      return false;
    }
  }

  // 12.1 Books: Update Book Approval Status (For Admin)
  static Future<bool> updateBookStatus(
    dynamic bookId,
    String status, {
    int? approvedBy,
    String? rejectionReason,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$bookId/status');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              'status': status,
              'approved_by': approvedBy ?? currentUser?['user_id'] ?? 1,
              if (rejectionReason != null) 'rejection_reason': rejectionReason,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateBookStatus error: $e');
      return false;
    }
  }

  // 13. Books: Delete book (For Admin)
  static Future<bool> deleteBook(String bookId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$bookId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService deleteBook error: $e');
      return false;
    }
  }

  // 13.1 Books: Fetch deleted (soft-deleted) books (For Restore)
  static Future<List<BookModel>> getDeletedBooks() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/deleted');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['books'] is List) {
          final List rawList = data['books'];
          return rawList
              .map((item) => BookModel.fromMap(item,
                  uploadsBaseUrl: ApiConfig.uploadsBaseUrl))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService getDeletedBooks error: $e');
    }
    return [];
  }

  // 13.2 Books: Restore soft-deleted book (For Employee/Admin)
  static Future<bool> restoreBook(String bookId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$bookId/restore');
      final response = await http
          .put(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService restoreBook error: $e');
      return false;
    }
  }

  // 14. Categories: Create Category (For Admin)
  static Future<bool> createCategory(String categoryName) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/categories');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'name': categoryName}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService createCategory error: $e');
      return false;
    }
  }

  // 14.1 Categories: Update Category (For Admin/Employee)
  static Future<bool> updateCategory(int categoryId, String name) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/categories/$categoryId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateCategory error: $e');
      return false;
    }
  }

  // 14.2 Categories: Delete Category (For Admin/Employee)
  static Future<bool> deleteCategory(int categoryId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/categories/$categoryId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService deleteCategory error: $e');
      return false;
    }
  }

  // 15. Subscriptions: Fetch all subscription requests (For Admin)
  static Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/subscriptions');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subscriptions'] is List) {
          return List<Map<String, dynamic>>.from(data['subscriptions']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getSubscriptions error: $e');
    }
    return [];
  }

  // 16. Subscriptions: Update payment status (For Admin Approval/Rejection)
  static Future<bool> updateSubscriptionStatus(int subId, String status,
      {int? approvedBy, String? reason}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$subId/status');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({
              'payment_status': status,
              'approved_by': approvedBy ?? currentUser?['user_id'] ?? 1,
              'rejected_reason': reason
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateSubscriptionStatus error: $e');
      return false;
    }
  }

  // 17. Subscriptions: Create subscription request (User)
  static Future<bool> createSubscription(Map<String, dynamic> subData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/subscriptions');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(subData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService createSubscription error: $e');
      return false;
    }
  }

  // 18. Subscriptions: Fetch live user subscription status
  static Future<Map<String, dynamic>?> getUserSubscriptionStatus(
      int userId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/subscriptions/user/$userId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      // # ເຮັດຫຍັງ: ແຍກ "ບໍ່ມີແພັກເກັດ" ອອກຈາກ "ຄຳຮ້ອງລົ້ມເຫຼວ"
      // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຄືນ null ທັງສອງກໍລະນີ ຜູ້ເອີ້ນຈຶ່ງແຍກບໍ່ອອກ
      // #          Membership.refresh ຈຶ່ງລ້າງສິດຖິ້ມທຸກຄັ້ງທີ່ເນັດສະດຸດ ຫຼື 401
      // #          ສະມາຊິກຈິງທີ່ຈ່າຍເງິນແລ້ວຈຶ່ງກາຍເປັນຜູ້ໃຊ້ທຳມະດາຊົ່ວຄາວ
      // #          ໂດຍບໍ່ຮູ້ສາເຫດ - ເປັນບັນຫາຄອບຄົວດຽວກັບ mock fallback ທີ່ຫາກໍ່ຕັດອອກ
      // # ແກ້ຈາກສ່ວນໃດ: return null; ຢູ່ທັງ 2 ບ່ອນ (ນອກ if ແລະ ໃນ catch)
      // # ແກ້ເຮັດຫຍັງ: throw ຕອນຕິດຕໍ່ບໍ່ໄດ້ ໃຫ້ Membership ຮັກສາຄ່າເກົ່າໄວ້
      // #             ສ່ວນ null ໝາຍເຖິງ "server ຕອບແລ້ວວ່າບໍ່ມີແພັກເກັດ" ຢ່າງດຽວ
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subscription'] != null) {
          return Map<String, dynamic>.from(data['subscription']);
        }
        return null; // server ຕອບແລ້ວ - ຜູ້ໃຊ້ນີ້ບໍ່ມີແພັກເກັດຈິງໆ
      }
      throw Exception(
          'getUserSubscriptionStatus HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService getUserSubscriptionStatus error: $e');
      rethrow;
    }
  }

  // 17. Packages: Fetch all packages
  static Future<List<Map<String, dynamic>>> getPackages(
      {bool showAll = false}) async {
    try {
      final url = Uri.parse
          ('${ApiConfig.baseUrl}/packages${showAll ? '?all=true' : ''}');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['packages'] is List) {
          return List<Map<String, dynamic>>.from(data['packages']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getPackages error: $e');
    }
    return [
      {
        'package_id': 1,
        'name': 'Standard Monthly',
        'description': 'ເຂົ້າເຖິງປຶ້ມອ່ານຟຣີ ແລະ ສະມາຊິກທົ່ວໄປ 30 ວັນ',
        'price': 49000.00,
        'duration_days': 30,
        'is_for_student': 0
      },
      {
        'package_id': 2,
        'name': 'Student Special',
        'description': 'ແພັກເກັດພິເສດສຳລັບນັກຮຽນ/ນັກສຶກສາ ຢືນຢັນຜ່ານ KYC',
        'price': 29000.00,
        'duration_days': 30,
        'is_for_student': 1
      },
      {
        'package_id': 3,
        'name': 'Premium Yearly',
        'description': 'ເຂົ້າເຖິງປຶ້ມທຸກເລົ່ມໃນຄັງແບບບໍ່ຈຳກັດ 365 ວັນ',
        'price': 490000.00,
        'duration_days': 365,
        'is_for_student': 0
      },
    ];
  }

  // 18. Packages: Create new package (For Admin)
  static Future<bool> createPackage(Map<String, dynamic> pkgData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/packages');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(pkgData),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService createPackage error: $e');
      return false;
    }
  }

  // 18.1 Packages: Update package status (For Admin)
  static Future<bool> updatePackageStatus(
      dynamic packageId, bool isActive) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/packages/$packageId/status');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({'is_active': isActive}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updatePackageStatus error: $e');
      return false;
    }
  }

  // 18.2 Packages: Update full package details (For Admin)
  static Future<bool> updatePackage(
      dynamic packageId, Map<String, dynamic> pkgData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/packages/$packageId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode(pkgData),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updatePackage error: $e');
      return false;
    }
  }

  // 19. Authors: Fetch all authors
  static Future<List<Map<String, dynamic>>> getAuthors() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['authors'] is List) {
          return List<Map<String, dynamic>>.from(data['authors']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getAuthors error: $e');
    }
    return [
      {'author_id': 1, 'name': 'ຄຳພູນ ບຸນທະວີ'},
      {'author_id': 2, 'name': 'ດວງຈຳປາ'},
    ];
  }

  // 20. Authors: Create new author
  static Future<bool> createAuthor(String name, {String? bio}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'name': name, 'biography': bio}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService createAuthor error: $e');
      return false;
    }
  }

  // 20.1 Authors: Update author (For Admin)
  static Future<bool> updateAuthor(int authorId, String name,
      {String? bio}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors/$authorId');
      final response = await http
          .put(
            url,
            headers: _headers,
            body: jsonEncode({'name': name, 'biography': bio}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService updateAuthor error: $e');
      return false;
    }
  }

  // 20.2 Authors: Delete author (For Admin)
  static Future<bool> deleteAuthor(int authorId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors/$authorId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService deleteAuthor error: $e');
      return false;
    }
  }

  // 21. Audit Logs: Fetch security audit history (For Admin)
  static Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/audit-logs');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['audit_logs'] is List) {
          return List<Map<String, dynamic>>.from(data['audit_logs']);
        }
      }
    } catch (e) {
      debugPrint('ApiService getAuditLogs error: $e');
    }
    return [];
  }

  // 21.1 Audit Logs: Record security action
  static Future<bool> logAudit({
    required String action,
    required String details,
  }) async {
    try {
      final user = currentUser ?? {};
      final rawUserId = user['user_id'] ?? user['id'];
      final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 1) : 1;

      final url = Uri.parse('${ApiConfig.baseUrl}/audit-logs');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'action': action,
              'details': details,
            }),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService logAudit error: $e');
      return false;
    }
  }

  // 22. User: Fetch Reading History
  static Future<List<HistoryBookItem>> getHistory() async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return [];

      final url = Uri.parse('${ApiConfig.baseUrl}/history?user_id=$userId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['history'] is List) {
          final List rawList = data['history'];
          return rawList
              .map((item) => HistoryBookItem.fromMap(item,
                  uploadsBaseUrl: ApiConfig.uploadsBaseUrl))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService getHistory error: $e');
    }
    // # ເຮັດຫຍັງ: ຄືນລາຍການຫວ່າງ ແທນ Mock*Data ທີ່ hardcode ໄວ້
    // # ຍ້ອນຫຍັງ: ຂໍ້ມູນປອມທີ່ຂຶ້ນຕອນ backend ລົ້ມ ເຮັດໃຫ້ຜູ້ໃຊ້ເຫັນລາຍການ
    // #          ທີ່ບໍ່ມີຢູ່ຈິງ ກົດເຂົ້າໄປກໍ່ບໍ່ໄດ້ ແລະ ຜູ້ພັດທະນາບໍ່ຮູ້ວ່າ API ລົ້ມ
    // #          ເພາະໜ້າຈໍຍັງມີເນື້ອຫາ - ບັນຫາຄອບຄົວດຽວກັບ mock fallback ອື່ນ
    // # ແກ້ຈາກສ່ວນໃດ: ບັນທັດສຸດທ້າຍທີ່ return Mock*Data
    // # ແກ້ເຮັດຫຍັງ: ຫວ່າງ = ຄວາມຈິງ ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຢູ່ database.sql ແທນ
    return [];
  }

  // 22b. User: Record Reading History & Progress
  // # ເຮັດຫຍັງ: ເພີ່ມ method ໃໝ່ເອີ້ນ POST /books/:id/increment-readers
  // # ຍ້ອນຫຍັງ: backend ມີ endpoint ນີ້ມາແຕ່ຕົ້ນ ແລະ ຖານຂໍ້ມູນມີຖັນ readers_count
  // #          ແຕ່ບໍ່ມີໃຜເອີ້ນເລີຍ ຕົວນັບຜູ້ອ່ານຈຶ່ງເປັນ 0 ຕະຫຼອດ ແລະ ໜ້າແອັບ
  // #          ສະແດງ "ຜູ້ອ່ານ 350" ຈາກຄ່າ seed ທີ່ບໍ່ເຄີຍປ່ຽນ
  // # ແກ້ຈາກສ່ວນໃດ: ApiService ບໍ່ມີ method ຄູ່ກັບ endpoint ນີ້ເລີຍ
  // # ແກ້ເຮັດຫຍັງ: ໃຫ້ pdf_viewer_screen ເອີ້ນຕອນເປີດອ່ານ ຕົວນັບຈຶ່ງເພີ່ມຈິງ
  static Future<bool> incrementReadersCount(String bookId) async {
    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}/books/$bookId/increment-readers');
      final response = await http
          .post(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService incrementReadersCount error: $e');
      return false;
    }
  }

  static Future<bool> recordReadingHistory(
      {required String bookId,
      required int lastPageRead,
      int totalPages = 1}) async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return false;
      final double progressPercent = totalPages > 0
          ? (lastPageRead / totalPages * 100.0).clamp(0.0, 100.0)
          : 0.0;

      final url = Uri.parse('${ApiConfig.baseUrl}/history');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'book_id': bookId,
              'last_page_read': lastPageRead,
              'progress_percent': progressPercent,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 ||
          response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService recordReadingHistory error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  // 23. User: Fetch Saved/Bookmarked Books
  static Future<List<SavedBookItem>> getSavedBooks() async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return [];

      final url = Uri.parse('${ApiConfig.baseUrl}/bookmarks?user_id=$userId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['bookmarks'] is List) {
          final List rawList = data['bookmarks'];
          return rawList
              .map((item) => SavedBookItem.fromMap(item,
                  uploadsBaseUrl: ApiConfig.uploadsBaseUrl))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService getSavedBooks error: $e');
    }
    // # ເຮັດຫຍັງ: ຄືນລາຍການຫວ່າງ ແທນ Mock*Data ທີ່ hardcode ໄວ້
    // # ຍ້ອນຫຍັງ: ຂໍ້ມູນປອມທີ່ຂຶ້ນຕອນ backend ລົ້ມ ເຮັດໃຫ້ຜູ້ໃຊ້ເຫັນລາຍການ
    // #          ທີ່ບໍ່ມີຢູ່ຈິງ ກົດເຂົ້າໄປກໍ່ບໍ່ໄດ້ ແລະ ຜູ້ພັດທະນາບໍ່ຮູ້ວ່າ API ລົ້ມ
    // #          ເພາະໜ້າຈໍຍັງມີເນື້ອຫາ - ບັນຫາຄອບຄົວດຽວກັບ mock fallback ອື່ນ
    // # ແກ້ຈາກສ່ວນໃດ: ບັນທັດສຸດທ້າຍທີ່ return Mock*Data
    // # ແກ້ເຮັດຫຍັງ: ຫວ່າງ = ຄວາມຈິງ ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຢູ່ database.sql ແທນ
    return [];
  }

  // 24. User: Fetch Downloaded Offline Files
  static Future<List<DownloadedBookItem>> getDownloads() async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return [];

      final url = Uri.parse('${ApiConfig.baseUrl}/downloads?user_id=$userId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['downloads'] is List) {
          final List rawList = data['downloads'];
          return rawList
              .map((item) => DownloadedBookItem.fromMap(item,
                  uploadsBaseUrl: ApiConfig.uploadsBaseUrl))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('ApiService getDownloads error: $e');
    }
    // # ເຮັດຫຍັງ: ຄືນລາຍການຫວ່າງ ແທນ Mock*Data ທີ່ hardcode ໄວ້
    // # ຍ້ອນຫຍັງ: ຂໍ້ມູນປອມທີ່ຂຶ້ນຕອນ backend ລົ້ມ ເຮັດໃຫ້ຜູ້ໃຊ້ເຫັນລາຍການ
    // #          ທີ່ບໍ່ມີຢູ່ຈິງ ກົດເຂົ້າໄປກໍ່ບໍ່ໄດ້ ແລະ ຜູ້ພັດທະນາບໍ່ຮູ້ວ່າ API ລົ້ມ
    // #          ເພາະໜ້າຈໍຍັງມີເນື້ອຫາ - ບັນຫາຄອບຄົວດຽວກັບ mock fallback ອື່ນ
    // # ແກ້ຈາກສ່ວນໃດ: ບັນທັດສຸດທ້າຍທີ່ return Mock*Data
    // # ແກ້ເຮັດຫຍັງ: ຫວ່າງ = ຄວາມຈິງ ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຢູ່ database.sql ແທນ
    return [];
  }

  // 24b. User: Record Book Download
  static Future<bool> recordDownload(String bookId) async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/downloads');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'book_id': bookId,
              'device_info': 'Flutter Application',
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 ||
          response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService recordDownload error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  // 24c. User: Delete Download Record
  static Future<bool> deleteDownload(String downloadId) async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return false;

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/downloads/$downloadId?user_id=$userId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService deleteDownload error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  // 25. User: Toggle Bookmark State
  static Future<bool> toggleBookmark(String bookId) async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/bookmarks');
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'book_id': bookId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 ||
          response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      debugPrint('ApiService toggleBookmark error: $e');
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  // 25b. User: Toggle Like State
  static Future<bool> toggleLike(String bookId) async {
    return toggleBookmark(bookId);
  }

  // 26. User: Get Full Profile Details
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      // # ເຮັດຫຍັງ: ປ່ຽນ path ຈາก '/user/profile' ເປັນ '/users/profile'
      // # ຍ້ອນຫຍັງ: backend mount route ໄວ້ທີ່ '/api/users' (ມີ s) ບໍ່ມີ '/api/user'
      // #          ເລີຍ ຄຳຮ້ອງນີ້ຈຶ່ງໄດ້ 404 ທຸກຄັ້ງ ແລ້ວຕົກໄປໃຊ້ຂໍ້ມູນສຳຮອງ
      // #          ທີ່ hardcode ໄວ້ດ້ານລຸ່ມ ໂດຍຜູ້ໃຊ້ບໍ່ຮູ້ວ່າບໍ່ແມ່ນຂໍ້ມູນຈິງຂອງຕົນ
      // # ແກ້ຈາກສ່ວນໃດ: getUserProfile() ທີ່ຂຽນ path ເປັນຄຳນາມເອກະພົດ
      // # ແກ້ເຮັດຫຍັງ: ຕົງກັບ route ໃໝ່ GET /api/users/profile ທີ່ອ່ານ user ຈາກ JWT
      final url = Uri.parse('${ApiConfig.baseUrl}/users/profile');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          currentUser = data['user'];
          return data['user'];
        }
      }
    } catch (e) {
      debugPrint('ApiService getUserProfile error: $e');
    }
    // # ເຮັດຫຍັງ: ຄືນ session ທີ່ມີຢູ່ ຫຼື map ຫວ່າງ ແທນຂໍ້ມູນຜູ້ໃຊ້ປອມ
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຄືນ 'ສົມຊາຍ ໃຈດີ / user1234@gmail.com / user_id 3'
    // #          ຕອນດຶງບໍ່ໄດ້ ໜ້າໂປຣໄຟລ໌ຈຶ່ງສະແດງຊື່ ແລະ ອີເມວຂອງຄົນອື່ນ
    // #          ໂດຍຜູ້ໃຊ້ບໍ່ຮູ້ວ່າບໍ່ແມ່ນຂໍ້ມູນຂອງຕົນ (ພົບຕອນແກ້ bug /user/profile 404)
    // # ແກ້ຈາກສ່ວນໃດ: return currentUser ?? { ...ຂໍ້ມູນຕົວຢ່າງ... }
    // # ແກ້ເຮັດຫຍັງ: ບໍ່ມີຂໍ້ມູນກໍ່ຄືນຫວ່າງ ໃຫ້ UI ສະແດງສະຖານະຫວ່າງແທນຂໍ້ມູນປອມ
    return currentUser ?? {};
  }

  // 27. Notifications API
  // # ເຮັດຫຍັງ: ເລີ່ມຕົ້ນເປັນລາຍການຫວ່າງ ແທນການ copy ຈາກ MockNotificationsData
  // # ຍ້ອນຫຍັງ: ແອັບຂຶ້ນແຈ້ງເຕືອນປອມທັນທີທີ່ເປີດ ກ່ອນຈະດຶງຂອງຈິງດ້ວຍຊ້ຳ
  // #          ຜູ້ໃຊ້ຈຶ່ງເຫັນແຈ້ງເຕືອນທີ່ບໍ່ແມ່ນຂອງຕົນ
  // # ແກ້ຈາກສ່ວນໃດ: List.from(MockNotificationsData.items)
  // # ແກ້ເຮັດຫຍັງ: ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຕາຕະລາງ notifications ໃນ database.sql
  static final List<NotificationItem> _userNotifications = [];

  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return [];
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/user/$userId');
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notifications'] is List) {
          final List list = data['notifications'];
          return list.map((item) => NotificationItem.fromMap(item)).toList();
        }
      }
      return List.from(_userNotifications);
    } catch (_) {
      return List.from(_userNotifications);
    }
  }

  static Future<bool> markNotificationAsRead(String id) async {
    try {
      final index = _userNotifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _userNotifications[index] =
            _userNotifications[index].copyWith(isRead: true);
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read');
      await http
          .put(url, headers: _headers)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      for (int i = 0; i < _userNotifications.length; i++) {
        _userNotifications[i] = _userNotifications[i].copyWith(isRead: true);
      }
      final userId = currentUserId;
      // ບໍ່ມີຜູ້ໃຊ້ login ຢູ່ - ຢຸດແທນທີ່ຈະບັນທຶກໃສ່ບັນຊີ user_id=3
      if (userId == null) return false;
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/notifications/user/$userId/read-all');
      await http
          .put(url, headers: _headers)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  static Future<bool> deleteNotification(String id) async {
    try {
      _userNotifications.removeWhere((n) => n.id == id);
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/$id');
      await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      // # ເຮັດຫຍັງ: ປ່ຽນ return true; ໃນ catch ເປັນ return false;
      // # ຍ້ອນຫຍັງ: ຄືນ true ຕອນເກີດ exception ເຮັດໃຫ້ UI ຂຶ້ນວ່າບັນທຶກສຳເລັດ
      // #          ທັງທີ່ backend ບໍ່ໄດ້ຮັບຫຍັງເລີຍ (ເນັດຂາດ, 401, server ລົ້ມ)
      // #          ຜູ້ໃຊ້ຈຶ່ງເຂົ້າໃຈວ່າຂໍ້ມູນຖືກເກັບແລ້ວ ແຕ່ຫາຍໄປຕອນໂຫຼດໃໝ່
      // # ແກ້ຈາກສ່ວນໃດ: catch block ຂອງ function ນີ້
      // # ແກ້ເຮັດຫຍັງ: ລົ້ມເຫຼວແລ້ວບອກວ່າລົ້ມເຫຼວ ໃຫ້ UI ແຈ້ງເຕືອນໄດ້ຖືກຕ້ອງ
      return false;
    }
  }

  // Helper Fallback Mock Books

  // Helper Fallback Mock Login
}
