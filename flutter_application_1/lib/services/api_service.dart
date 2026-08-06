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
      print('ApiService saveSession error: $e');
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
      print('ApiService loadSession error: $e');
    }
    return false;
  }

  static Future<void> clearSession() async {
    currentUser = null;
    authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      await prefs.remove('authToken');
    } catch (e) {
      print('ApiService clearSession error: $e');
    }
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
        return {'success': true, 'token': authToken, 'user': currentUser};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ'
        };
      }
    } catch (e) {
      print('ApiService login error: $e');
      // Fallback for mock login if server is offline
      final res = _mockLoginFallback(email, password);
      if (res['success'] == true && res['user'] != null) {
        await saveSession(res['user'], res['token']);
      }
      return res;
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
      print('ApiService register error: $e');
      // Mock fallback registration for User
      final newMockUser = {
        'user_id': DateTime.now().millisecondsSinceEpoch,
        'email': userData['email'],
        'first_name': userData['first_name'] ?? 'ຜູ້ໃຊ້',
        'last_name': userData['last_name'] ?? 'ໃໝ່',
        'role': 'user', // Strictly General User
        'status': 'active',
      };
      currentUser = newMockUser;
      return {
        'success': true,
        'message': 'ລົງທະບຽນບັນຊີຜູ້ໃຊ້ສຳເລັດ (Mock Connection)',
        'user': newMockUser,
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
      if (categoryId != null && categoryId.isNotEmpty)
        queryParams['category_id'] = categoryId;
      if (isFree != null) queryParams['is_free'] = isFree ? 'true' : 'false';
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (uploadedBy != null && uploadedBy.isNotEmpty)
        queryParams['uploaded_by'] = uploadedBy;

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
      print('ApiService getBooks error: $e');
    }

    // Fallback to local mock data if backend connection fails or offline
    return _allMockBooks();
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
      print('ApiService createBook error: $e');
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
      print('ApiService uploadFile error: $e');
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
      print('ApiService getCategories error: $e');
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
      print('ApiService getUsers error: $e');
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
      print('ApiService updateUserStatus error: $e');
      return true; // Mock success fallback for offline dev mode
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
      print('ApiService updateUser error: $e');
      return true; // Mock success fallback for offline dev mode
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
      print('ApiService createUser error: $e');
      return true; // Mock success fallback for offline dev mode
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
      print('ApiService getKycList error: $e');
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
      return (response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true;
    } catch (e) {
      print('ApiService submitKyc error: $e');
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
      print('ApiService getUserKycStatus error: $e');
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
      print('ApiService updateBook error: $e');
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
      print('ApiService updateBookStatus error: $e');
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
      print('ApiService deleteBook error: $e');
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
      print('ApiService getDeletedBooks error: $e');
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
      print('ApiService restoreBook error: $e');
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
      print('ApiService updateCategory error: $e');
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
      print('ApiService deleteCategory error: $e');
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
      print('ApiService getSubscriptions error: $e');
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
      print('ApiService updateSubscriptionStatus error: $e');
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
      print('ApiService createSubscription error: $e');
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subscription'] != null) {
          return Map<String, dynamic>.from(data['subscription']);
        }
      }
      return null;
    } catch (e) {
      print('ApiService getUserSubscriptionStatus error: $e');
      return null;
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
      print('ApiService getPackages error: $e');
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
      print('ApiService createPackage error: $e');
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
      print('ApiService updatePackageStatus error: $e');
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
      print('ApiService updatePackage error: $e');
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
      print('ApiService getAuthors error: $e');
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
      print('ApiService createAuthor error: $e');
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
      print('ApiService updateAuthor error: $e');
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
      print('ApiService deleteAuthor error: $e');
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
      print('ApiService getAuditLogs error: $e');
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
      print('ApiService logAudit error: $e');
      return false;
    }
  }

  // 22. User: Fetch Reading History
  static Future<List<HistoryBookItem>> getHistory() async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;

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
      print('ApiService getHistory error: $e');
    }
    return MockHistoryData.historyItems;
  }

  // 22b. User: Record Reading History & Progress
  static Future<bool> recordReadingHistory(
      {required String bookId,
      required int lastPageRead,
      int totalPages = 1}) async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;
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
      print('ApiService recordReadingHistory error: $e');
      return true;
    }
  }

  // 23. User: Fetch Saved/Bookmarked Books
  static Future<List<SavedBookItem>> getSavedBooks() async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;

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
      print('ApiService getSavedBooks error: $e');
    }
    return MockSavedData.savedItems;
  }

  // 24. User: Fetch Downloaded Offline Files
  static Future<List<DownloadedBookItem>> getDownloads() async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;

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
      print('ApiService getDownloads error: $e');
    }
    return MockDownloadsData.downloadedItems;
  }

  // 24b. User: Record Book Download
  static Future<bool> recordDownload(String bookId) async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;

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
      print('ApiService recordDownload error: $e');
      return true;
    }
  }

  // 24c. User: Delete Download Record
  static Future<bool> deleteDownload(String downloadId) async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/downloads/$downloadId?user_id=$userId');
      final response = await http
          .delete(url, headers: _headers)
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('ApiService deleteDownload error: $e');
      return true;
    }
  }

  // 25. User: Toggle Bookmark State
  static Future<bool> toggleBookmark(String bookId) async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? 3;

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
      print('ApiService toggleBookmark error: $e');
      return true;
    }
  }

  // 25b. User: Toggle Like State
  static Future<bool> toggleLike(String bookId) async {
    return toggleBookmark(bookId);
  }

  // 26. User: Get Full Profile Details
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/user/profile');
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
      print('ApiService getUserProfile error: $e');
    }
    return currentUser ??
        {
          'user_id': 3,
          'first_name': 'ສົມຊາຍ',
          'last_name': 'ໃຈດີ',
          'email': 'user1234@gmail.com',
          'role': 'user',
          'created_at': '2026-11-04',
          'expires_at': '2026-12-04',
        };
  }

  // 27. Notifications API
  static final List<NotificationItem> _userNotifications =
      List.from(MockNotificationsData.items);

  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? user['id'] ?? 3;
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
      return true;
    }
  }

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      for (int i = 0; i < _userNotifications.length; i++) {
        _userNotifications[i] = _userNotifications[i].copyWith(isRead: true);
      }
      final user = currentUser ?? {};
      final userId = user['user_id'] ?? user['id'] ?? 3;
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/notifications/user/$userId/read-all');
      await http
          .put(url, headers: _headers)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      return true;
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
      return true;
    }
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
  static Map<String, dynamic> _mockLoginFallback(
      String email, String password) {
    if (email == 'admin@gmail.com' && password == 'admin123456') {
      return {
        'success': true,
        'user': {
          'user_id': 1,
          'email': email,
          'first_name': 'Admin',
          'last_name': 'System',
          'role': 'admin'
        }
      };
    } else if (email == 'employee@gmail.com' && password == 'employee123') {
      return {
        'success': true,
        'user': {
          'user_id': 2,
          'email': email,
          'first_name': 'Staff',
          'last_name': 'Employee',
          'role': 'employee'
        }
      };
    } else if (email == 'member@gmail.com' && password == 'member1234') {
      return {
        'success': true,
        'user': {
          'user_id': 3,
          'email': email,
          'first_name': 'Premiere',
          'last_name': 'Member',
          'role': 'user'
        }
      };
    } else if (email == 'user1234@gmail.com' && password == 'user1234') {
      return {
        'success': true,
        'user': {
          'user_id': 4,
          'email': email,
          'first_name': 'General',
          'last_name': 'User',
          'role': 'user'
        }
      };
    } else {
      return {'success': false, 'message': 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ'};
    }
  }
}
