import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/login_model.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _deviceIdKey = 'device_id';
  static const String _deviceNameKey = 'device_name';
  static const String _deviceAgentKey = 'device_agent';
  static const String _deviceIpKey = 'device_ip';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _prefs!.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs!.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs!.remove(_tokenKey);
  }

  // User data management
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs!.setString(_userKey, userJson);
  }

  Future<UserModel?> getUser() async {
    final userJson = _prefs!.getString(_userKey);
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        return UserModel.fromJson(userMap);
      } catch (e) {
        // Se houver erro na desserialização, limpa os dados corrompidos
        await clearUser();
        return null;
      }
    }
    return null;
  }

  Future<void> clearUser() async {
    await _prefs!.remove(_userKey);
  }

  // Login data management (token + user together)
  Future<void> saveLoginData(LoginResponse loginResponse) async {
    await saveToken(loginResponse.token);
    await saveUser(loginResponse.user);
  }

  Future<LoginResponse?> getLoginData() async {
    final token = await getToken();
    final user = await getUser();

    if (token != null && user != null) {
      // Reconstruir o LoginResponse com dados básicos
      return LoginResponse(
        user: user,
        token: token,
        iat: 0, // Não temos acesso aos dados originais
        exp: 0, // Não temos acesso aos dados originais
      );
    }
    return null;
  }

  Future<void> clearLoginData() async {
    await clearToken();
    await clearUser();
  }

  // Device information management
  Future<void> saveDeviceId(String deviceId) async {
    await _prefs!.setString(_deviceIdKey, deviceId);
  }

  Future<String?> getDeviceId() async {
    return _prefs!.getString(_deviceIdKey);
  }

  Future<void> saveDeviceName(String deviceName) async {
    await _prefs!.setString(_deviceNameKey, deviceName);
  }

  Future<String?> getDeviceName() async {
    return _prefs!.getString(_deviceNameKey);
  }

  Future<void> saveDeviceAgent(String deviceAgent) async {
    await _prefs!.setString(_deviceAgentKey, deviceAgent);
  }

  Future<String?> getDeviceAgent() async {
    return _prefs!.getString(_deviceAgentKey);
  }

  Future<void> saveDeviceIp(String deviceIp) async {
    await _prefs!.setString(_deviceIpKey, deviceIp);
  }

  Future<String?> getDeviceIp() async {
    return _prefs!.getString(_deviceIpKey);
  }

  // Authentication check
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && user != null;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs!.clear();
  }

  // Generic storage methods for future use
  Future<void> setString(String key, String value) async {
    await _prefs!.setString(key, value);
  }

  Future<String?> getString(String key) async {
    return _prefs!.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs!.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    return _prefs!.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs!.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    return _prefs!.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs!.remove(key);
  }
}
