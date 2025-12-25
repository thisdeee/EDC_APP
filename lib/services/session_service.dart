import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  static const String _sessionIdKey = 'app_session_id';
  static String? _sessionId;

  /// Get or create a unique session ID for this device/app instance
  /// This ID persists across app restarts and is used to verify payments
  static Future<String> getSessionId() async {
    if (_sessionId != null) {
      return _sessionId!;
    }

    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString(_sessionIdKey);

    if (_sessionId == null) {
      // Generate new session ID if it doesn't exist
      _sessionId = const Uuid().v4();
      await prefs.setString(_sessionIdKey, _sessionId!);
      print('🆕 Generated new session ID: $_sessionId');
    } else {
      print('♻️ Using existing session ID: $_sessionId');
    }

    return _sessionId!;
  }

  /// Reset session ID (useful for testing or switching accounts)
  static Future<void> resetSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    _sessionId = null;
    print('🔄 Session ID reset');
  }

  /// Verify if a given session ID matches the current device's session
  static Future<bool> verifySessionId(String sessionId) async {
    final currentSessionId = await getSessionId();
    final matches = sessionId == currentSessionId;
    if (!matches) {
      print('❌ Session mismatch! Expected: $currentSessionId, Got: $sessionId');
    }
    return matches;
  }

  /// Get current session ID without async (after it's been initialized)
  static String? getCurrentSessionId() {
    return _sessionId;
  }
}
