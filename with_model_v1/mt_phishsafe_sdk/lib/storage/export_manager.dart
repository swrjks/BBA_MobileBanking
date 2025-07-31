import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ExportManager {
  /// Save the session log locally and upload to server
  Future<void> exportToJson(Map<String, dynamic> data, String baseFileName) async {
    try {
      final now = DateTime.now();
      // Format: 2025-07-19T14-43-40.016437
      final timestamp = now.toIso8601String().replaceAll(":", "-");
      final fileName = '${baseFileName}_$timestamp.json'; // e.g., session_log_2025-07-19T14-43-40.016437.json

      final directory = Directory('/sdcard/Download/PhishSafe');
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      final jsonData = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonData);

      print('✅ Session log saved to: ${file.path}');

      // 🔁 Upload to Flask server
      await uploadToServer(data);
    } catch (e) {
      print('❌ Error saving or uploading session log: $e');
    }
  }

  /// Save the user profile silently to Downloads/PhishSafe
  Future<void> exportUserProfile(Map<String, dynamic> data, String fileName) async {
    try {
      final directory = Directory('/sdcard/Download/PhishSafe');
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      final jsonData = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonData);

      print('✅ User profile saved to: ${file.path}');
    } catch (e) {
      print('❌ Failed to save user profile: $e');
    }
  }

  /// Upload the session log to the Flask server
  Future<void> uploadToServer(Map<String, dynamic> logData) async {
    final url = Uri.parse("https://phishsafe-web.onrender.com/upload");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      );

      if (response.statusCode == 200) {
        print("✅ Session log uploaded to Flask dashboard");
      } else {
        print("❌ Upload failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Exception during upload: $e");
    }
  }
}
