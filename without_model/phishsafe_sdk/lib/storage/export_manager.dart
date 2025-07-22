import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ExportManager {
  /// Save the session log locally in Downloads/PhishSafe
  Future<void> exportToJson(Map<String, dynamic> data, String baseFileName) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(":", "-");
      final fileName = '$baseFileName\_$timestamp.json';

      final directory = Directory('/sdcard/Download/PhishSafe');
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      final jsonData = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonData);

      print('✅ Saved to visible folder: ${file.path}');

      // ✅ Also upload the log to the Flask server (cloud)
      await uploadToServer(data);
    } catch (e) {
      print('❌ Failed to export or upload session data: $e');
    }
  }

  /// Save the user profile silently
  Future<void> exportUserProfile(Map<String, dynamic> data, String fileName) async {
    try {
      final directory = Directory('/sdcard/Download/PhishSafe');
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      final jsonData = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonData);

      print('✅ User profile saved silently to: ${file.path}');
    } catch (e) {
      print('❌ Failed to export user profile: $e');
    }
  }

  /// Upload the session log to the internet-accessible Flask server via ngrok
  Future<void> uploadToServer(Map<String, dynamic> logData) async {
    final url = Uri.parse("https://phishsafe-web.onrender.com/upload"); // ✅ Use your ngrok HTTPS URL here

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(logData),
      );

      if (response.statusCode == 200) {
        print("✅ Uploaded session log to Flask dashboard");
      } else {
        print("❌ Upload failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Exception during upload: $e");
    }
  }
}