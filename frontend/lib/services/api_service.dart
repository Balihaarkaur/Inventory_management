import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Live render URL for global connections
  static const String baseUrl = 'https://inventory-management-oadl.onrender.com/api';

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
      } else if (response.statusCode == 404) {
        throw Exception('Hardware not found');
      } else {
        throw Exception(data['message'] ?? 'Failed to verify hardware');
      }
    } catch (e) {
      if (e.toString().contains('Hardware not found')) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> registerHardware({
    required String hardwareName,
    required String barcodeValue,
    required int currentLocationId, // Often 1 or the mapped ID
    String status = 'Active',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hardware'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hardware_name': hardwareName,
          'barcode_value': barcodeValue,
          'current_location_id': currentLocationId,
          'status': status,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error']?['message'] ?? 'Failed to register hardware');
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
