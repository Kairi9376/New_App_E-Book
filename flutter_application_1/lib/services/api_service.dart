import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import 'api_config.dart';

class ApiService {
  // Shared token & session data
  static String? authToken;
  static Map<String, dynamic>? currentUser;

  // Headers helper
  static Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (authToken != null) {
      map['Authorization'] = 'Bearer $authToken';
    }
    return map;
  }

  // 1. Authentication: Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        authToken = data['token'];
        currentUser = data['user'];
        return {'success': true, 'token': authToken, 'user': currentUser};
      } else {
        return {'success': false, 'message': data['message'] ?? 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ'};
      }
    } catch (e) {
      print('ApiService login error: $e');
      // Fallback for mock login if server is offline
      return _mockLoginFallback(email, password);
    }
  }

  // 2. Authentication: Register
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('ApiService register error: $e');
      return {'success': false, 'message': 'ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີບເວີຫຼັງບ້ານໄດ້'};
    }
  }

  // 3. Books: Fetch all books
  static Future<List<BookModel>> getBooks({String? search, String? categoryId, bool? isFree}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['category_id'] = categoryId;
      if (isFree != null) queryParams['is_free'] = isFree ? 'true' : 'false';

      final uri = Uri.parse('${ApiConfig.baseUrl}/books').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['books'] is List) {
          final List rawList = data['books'];
          return rawList.map((item) => BookModel.fromMap(item, uploadsBaseUrl: ApiConfig.uploadsBaseUrl)).toList();
        }
      }
    } catch (e) {
      print('ApiService getBooks error: $e');
    }

    // Fallback to local mock data if backend connection fails or offline
    return _allMockBooks();
  }

  // 4. Books: Get book detail
  static Future<BookModel?> getBookById(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$id');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['book'] != null) {
          return BookModel.fromMap(data['book'], uploadsBaseUrl: ApiConfig.uploadsBaseUrl);
        }
      }
    } catch (e) {
      print('ApiService getBookById error: $e');
    }

    // Fallback to mock books search
    final allMocks = _allMockBooks();
    try {
      return allMocks.firstWhere((b) => b.id == id);
    } catch (_) {
      return allMocks.isNotEmpty ? allMocks.first : null;
    }
  }

  // 5. Books: Create / Add new book (For Employee)
  static Future<Map<String, dynamic>> createBook(Map<String, dynamic> bookData) async {
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
      print('ApiService createBook error: $e');
      return {'success': false, 'message': 'ບໍ່ສາມາດບັນທຶກປຶ້ມໄປຍັງຫຼັງບ້ານໄດ້: $e'};
    }
  }

  // 6. Multipart Upload: Upload PDF / Cover file
  static Future<Map<String, dynamic>> uploadFile({
    required List<int> bytes,
    required String filename,
    required String fieldName, // e.g. 'cover' or 'pdf' or 'slip'
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/upload');
      final request = http.MultipartRequest('POST', url);

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final uploadsMap = data['uploads'] as Map<String, dynamic>? ?? {};
        final uploadInfo = uploadsMap[fieldName] ?? (uploadsMap.isNotEmpty ? uploadsMap.values.first : {});

        final fileUrl = uploadInfo['url'] ?? '${ApiConfig.baseUrl}/uploads/$filename';
        final filePath = uploadInfo['path'] ?? 'uploads/$filename';

        return {
          'success': true,
          'url': fileUrl,
          'path': filePath,
          'filename': uploadInfo['filename'] ?? filename
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'ອັບໂຫຼດບໍ່ສຳເລັດ'};
      }
    } catch (e) {
      print('ApiService uploadFile error: $e');
      return {'success': false, 'message': 'ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫຼດ: $e'};
    }
  }

  // 7. Categories: Fetch list of categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/categories');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['categories'] is List) {
          return List<Map<String, dynamic>>.from(data['categories']);
        }
      }
    } catch (e) {
      print('ApiService getCategories error: $e');
    }

    return [
      {'category_id': 1, 'name': 'ຊີວິດ'},
      {'category_id': 2, 'name': 'ວິທະຍາສາດ'},
      {'category_id': 3, 'name': 'ເຕັກໂນໂລຊີ'},
      {'category_id': 4, 'name': 'ຜະຈົນໄພ'},
      {'category_id': 5, 'name': 'ສິລະປະ'}
    ];
  }

  // 8. Users: Fetch all users (For Admin)
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['users'] is List) {
          return List<Map<String, dynamic>>.from(data['users']);
        }
      }
    } catch (e) {
      print('ApiService getUsers error: $e');
    }

    return [
      {'user_id': 1, 'email': 'admin@gmail.com', 'first_name': 'ผู้ดูแล', 'last_name': 'ระบบ (Admin)', 'role': 'admin', 'status': 'active'},
      {'user_id': 2, 'email': 'employee@gmail.com', 'first_name': 'พนักงาน', 'last_name': 'จัดการคลัง', 'role': 'employee', 'status': 'active'},
      {'user_id': 3, 'email': 'user1234@gmail.com', 'first_name': 'สมชาย', 'last_name': 'ใจดี', 'role': 'user', 'status': 'active'},
      {'user_id': 4, 'email': 'member@gmail.com', 'first_name': 'พรีเมี่ยม', 'last_name': 'สมาชิก', 'role': 'user', 'status': 'active'},
    ];
  }

  // 9. Users: Update status (For Admin)
  static Future<bool> updateUserStatus(int userId, String status, {String? reason}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId/status');
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({'status': status, 'suspended_reason': reason}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService updateUserStatus error: $e');
      return true; // Mock success fallback for offline dev mode
    }
  }

  // 9.1 Users: Update Full User Information (For Admin)
  static Future<bool> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService updateUser error: $e');
      return true; // Mock success fallback for offline dev mode
    }
  }

  // 9.2 Users: Create User (For Admin)
  static Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return (response.statusCode == 200 || response.statusCode == 201) && data['success'] == true;
    } catch (e) {
      print('ApiService createUser error: $e');
      return true; // Mock success fallback for offline dev mode
    }
  }

  // 10. KYC: Fetch all submissions (For Admin)
  static Future<List<Map<String, dynamic>>> getKycList() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/kyc');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['kyc_list'] is List) {
          return List<Map<String, dynamic>>.from(data['kyc_list']);
        }
      }
    } catch (e) {
      print('ApiService getKycList error: $e');
    }

    return [];
  }

  // 11. KYC: Update status (For Admin)
  static Future<bool> updateKycStatus(int kycId, String status, {int? reviewedBy, String? rejectionReason}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/kyc/$kycId/status');
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({
          'status': status,
          'reviewed_by': reviewedBy ?? 1,
          'rejection_reason': rejectionReason
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService updateKycStatus error: $e');
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
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('ApiService submitKyc error: $e');
      return false;
    }
  }

  // 12. Books: Update book (For Admin/Employee)
  static Future<bool> updateBook(String bookId, Map<String, dynamic> updateData) async {
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
      print('ApiService updateBook error: $e');
      return false;
    }
  }

  // 13. Books: Delete book (For Admin)
  static Future<bool> deleteBook(String bookId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/books/$bookId');
      final response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService deleteBook error: $e');
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
      print('ApiService createCategory error: $e');
      return false;
    }
  }

  // 15. Subscriptions: Fetch all subscription requests (For Admin)
  static Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/subscriptions');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subscriptions'] is List) {
          return List<Map<String, dynamic>>.from(data['subscriptions']);
        }
      }
    } catch (e) {
      print('ApiService getSubscriptions error: $e');
    }
    return [];
  }

  // 16. Subscriptions: Update payment status (For Admin Approval/Rejection)
  static Future<bool> updateSubscriptionStatus(int subId, String status, {int? approvedBy, String? reason}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$subId/status');
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({
          'payment_status': status,
          'approved_by': approvedBy ?? currentUser?['user_id'] ?? 1,
          'rejected_reason': reason
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService updateSubscriptionStatus error: $e');
      return false;
    }
  }

  // 17. Packages: Fetch all packages
  static Future<List<Map<String, dynamic>>> getPackages() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/packages');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['packages'] is List) {
          return List<Map<String, dynamic>>.from(data['packages']);
        }
      }
    } catch (e) {
      print('ApiService getPackages error: $e');
    }
    return [
      {'package_id': 1, 'name': 'แพ็กเกจ 1 เดือน', 'description': 'เข้าถึงหนังสือทั้งหมด 30 วัน', 'price': 50000, 'duration_days': 30, 'is_for_student': 0},
      {'package_id': 2, 'name': 'แพ็กเกจ 3 เดือน', 'description': 'เข้าถึงหนังสือทั้งหมด 90 วัน', 'price': 130000, 'duration_days': 90, 'is_for_student': 0},
      {'package_id': 3, 'name': 'แพ็กเกจนักเรียน (Student Pro)', 'description': 'ราคาสุดพิเศษสำหรับนักเรียน/นักศึกษา', 'price': 25000, 'duration_days': 30, 'is_for_student': 1},
    ];
  }

  // 18. Packages: Create new package (For Admin)
  static Future<bool> createPackage(Map<String, dynamic> pkgData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/packages');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(pkgData),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('ApiService createPackage error: $e');
      return false;
    }
  }

  // 19. Authors: Fetch all authors
  static Future<List<Map<String, dynamic>>> getAuthors() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['authors'] is List) {
          return List<Map<String, dynamic>>.from(data['authors']);
        }
      }
    } catch (e) {
      print('ApiService getAuthors error: $e');
    }
    return [
      {'author_id': 1, 'name': 'คำพูน บุญทวี'},
      {'author_id': 2, 'name': 'ดวงจำปา'},
    ];
  }

  // 20. Authors: Create new author
  static Future<bool> createAuthor(String name, {String? bio}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'name': name, 'biography': bio}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      print('ApiService createAuthor error: $e');
      return false;
    }
  }

  // 20.1 Authors: Update author (For Admin)
  static Future<bool> updateAuthor(int authorId, String name, {String? bio}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors/$authorId');
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({'name': name, 'biography': bio}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService updateAuthor error: $e');
      return false;
    }
  }

  // 20.2 Authors: Delete author (For Admin)
  static Future<bool> deleteAuthor(int authorId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/authors/$authorId');
      final response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService deleteAuthor error: $e');
      return false;
    }
  }

  // 21. Audit Logs: Fetch security audit history (For Admin)
  static Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/audit-logs');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['audit_logs'] is List) {
          return List<Map<String, dynamic>>.from(data['audit_logs']);
        }
      }
    } catch (e) {
      print('ApiService getAuditLogs error: $e');
    }
    return [];
  }

  // Helper Fallback Mock Books
  static List<BookModel> _allMockBooks() {
    return [
      ...MockBookData.popularBooks,
      ...MockBookData.newBooks,
      ...MockBookData.recommendedBooks,
    ];
  }

  // Helper Fallback Mock Login
  static Map<String, dynamic> _mockLoginFallback(String email, String password) {
    if (email == 'admin@gmail.com' && password == 'admin123456') {
      return {
        'success': true,
        'user': {'user_id': 1, 'email': email, 'first_name': 'Admin', 'last_name': 'System', 'role': 'admin'}
      };
    } else if (email == 'employee@gmail.com' && password == 'employee123') {
      return {
        'success': true,
        'user': {'user_id': 2, 'email': email, 'first_name': 'Staff', 'last_name': 'Employee', 'role': 'employee'}
      };
    } else if (email == 'member@gmail.com' && password == 'member1234') {
      return {
        'success': true,
        'user': {'user_id': 3, 'email': email, 'first_name': 'Premiere', 'last_name': 'Member', 'role': 'user'}
      };
    } else if (email == 'user1234@gmail.com' && password == 'user1234') {
      return {
        'success': true,
        'user': {'user_id': 4, 'email': email, 'first_name': 'General', 'last_name': 'User', 'role': 'user'}
      };
    } else {
      return {'success': false, 'message': 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ'};
    }
  }
}
