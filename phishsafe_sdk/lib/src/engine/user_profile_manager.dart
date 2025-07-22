import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class UserProfileManager {
  Future<File> _getProfileFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/phishsafe_user_profile.json');
  }

  Future<Map<String, dynamic>> loadProfile() async {
    try {
      final file = await _getProfileFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      print("⚠️ Failed to load user profile: $e");
    }
    return {}; // return empty profile if not found or broken
  }

  Future<void> updateProfileFromSession(Map<String, dynamic> sessionData) async {
    final file = await _getProfileFile();
    Map<String, dynamic> existing = await loadProfile();

    // Handle 'summary' safely
    Map<String, dynamic> summaryRaw = sessionData['summary'] ?? {};
    Map<String, double> summary = summaryRaw.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    existing['avg_tap_duration_ms'] = summary['avg_tap_duration_ms'];
    existing['avg_screen_duration'] = summary['avg_screen_duration'];
    existing['tap_count'] = summary['tap_count'];
    existing['swipe_count'] = summary['swipe_count'];

    try {
      await file.writeAsString(jsonEncode(existing));
      print("💾 User profile updated.");
    } catch (e) {
      print("❌ Failed to write user profile: $e");
    }
  }

  Future<void> clearProfile() async {
    try {
      final file = await _getProfileFile();
      if (await file.exists()) {
        await file.delete();
        print("🗑️ User profile cleared.");
      }
    } catch (e) {
      print("❌ Failed to clear user profile: $e");
    }
  }
}