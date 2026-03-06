import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const String baseUrl = 'http://192.168.1.4:3000/api';

  static Future<Map<String, dynamic>> scanHardware(String barcode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scanner/hardware'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hardware_code': barcode}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data; // returns the hardware object, step, etc.
      } else {
        throw Exception(data['message'] ?? 'Failed to verify hardware');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> markLocation(
      int hardwareId, int locationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scanner/move'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hardware_id': hardwareId,
          'new_location_id': locationId,
          'moved_by': userId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to move hardware');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
