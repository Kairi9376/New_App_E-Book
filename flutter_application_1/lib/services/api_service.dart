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

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final uploadInfo = data['uploads'][fieldName];
        return {
          'success': true,
          'url': uploadInfo['url'],
          'path': uploadInfo['path'],
          'filename': uploadInfo['filename']
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
