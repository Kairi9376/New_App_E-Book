import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'http://localhost:5000/api';

  group('Phase 4.1 - Flutter Runtime Integration Verification', () {
    testWidgets('Health Check', (tester) async {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(
        const Duration(seconds: 5),
      );
      expect(response.statusCode, 200);
      final data = jsonDecode(response.body);
      expect(data['status'], 'OK');
      print('HEALTH: HTTP ${response.statusCode} - ${response.body}');
    });

    testWidgets('Books API', (tester) async {
      final response = await http
          .get(Uri.parse('$baseUrl/books'))
          .timeout(const Duration(seconds: 5));
      expect(response.statusCode, 200);
      final data = jsonDecode(response.body);
      expect(data['success'], true);
      expect(data['books'], isA<List>());
      print('BOOKS: HTTP ${response.statusCode} - Records: ${(data['books'] as List).length}');
      print('BOOKS DATA SOURCE: Backend');
    });

    testWidgets('Categories API', (tester) async {
      final response = await http
          .get(Uri.parse('$baseUrl/categories'))
          .timeout(const Duration(seconds: 5));
      expect(response.statusCode, 200);
      final data = jsonDecode(response.body);
      expect(data['success'], true);
      expect(data['categories'], isA<List>());
      print('CATEGORIES: HTTP ${response.statusCode} - Records: ${(data['categories'] as List).length}');
      print('CATEGORIES DATA SOURCE: Backend');
    });

    testWidgets('Authors API', (tester) async {
      final response = await http
          .get(Uri.parse('$baseUrl/authors'))
          .timeout(const Duration(seconds: 5));
      expect(response.statusCode, 200);
      final data = jsonDecode(response.body);
      expect(data['success'], true);
      expect(data['authors'], isA<List>());
      print('AUTHORS: HTTP ${response.statusCode} - Records: ${(data['authors'] as List).length}');
      print('AUTHORS DATA SOURCE: Backend');
    });

    testWidgets('Login API', (tester) async {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': 'admin@gmail.com',
              'login_input': 'admin@gmail.com',
              'password': 'admin123456',
            }),
          )
          .timeout(const Duration(seconds: 5));
      print('LOGIN: HTTP ${response.statusCode}');
      print('LOGIN BODY: ${response.body}');
      expect(response.statusCode, 200);
      final data = jsonDecode(response.body);
      expect(data['success'], true);
      expect(data['token'], isNotNull);
      expect(data['user'], isNotNull);
      print('LOGIN DATA SOURCE: Backend');
      print('LOGIN: JWT received: ${data['token'] != null}');

      // Test /api/auth/me with JWT
      final token = data['token'] as String;
      final userId = data['user']['user_id'];
      final meResponse = await http
          .get(
            Uri.parse('$baseUrl/auth/me?user_id=$userId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      print('AUTH/ME: HTTP ${meResponse.statusCode}');
      print('AUTH/ME BODY: ${meResponse.body}');
      expect(meResponse.statusCode, 200);

      // Test Bookmarks with JWT and user_id
      final bookmarksResponse = await http
          .get(
            Uri.parse('$baseUrl/bookmarks?user_id=$userId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      print('BOOKMARKS: HTTP ${bookmarksResponse.statusCode}');
      expect(bookmarksResponse.statusCode, 200);

      // Test History with JWT and user_id
      final historyResponse = await http
          .get(
            Uri.parse('$baseUrl/history?user_id=$userId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      print('HISTORY: HTTP ${historyResponse.statusCode}');
      expect(historyResponse.statusCode, 200);

      // Test Notifications with JWT and user_id
      final notificationsResponse = await http
          .get(
            Uri.parse('$baseUrl/notifications?user_id=$userId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      print('NOTIFICATIONS: HTTP ${notificationsResponse.statusCode}');
      expect(notificationsResponse.statusCode, 200);
    });
  });
}
