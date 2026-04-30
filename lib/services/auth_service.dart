import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _packPassword(String password) {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    return '$salt:$hash';
  }

  bool _verifyPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) {
      return password == stored;
    }
    final salt = parts[0];
    final expectedHash = _hashPassword(password, salt);
    return expectedHash == parts[1];
  }

  Future<String?> login(String username, String password) async {
    final client = SupabaseService.maybeClient;
    if (client == null) return '服务未初始化';

    try {
      var response = await client
          .from('app_users')
          .select('*')
          .eq('username', username)
          .maybeSingle();

      response ??= await client
          .from('app_users')
          .select('*')
          .eq('phone', username)
          .maybeSingle();

      if (response == null) {
        return '账号或密码错误';
      }

      final user = AppUser.fromSupabase(response);

      if (!_verifyPassword(password, user.password)) {
        return '账号或密码错误';
      }

      _currentUser = user;
      return null;
    } catch (error) {
      debugPrint('AuthService.login failed: $error');
      return '登录失败，请稍后再试';
    }
  }

  Future<String?> register({
    required String username,
    required String password,
    required String nickname,
    String? avatarUrl,
    String? bio,
    String? email,
    String? phone,
    String? profession,
    String? farm,
  }) async {
    final client = SupabaseService.maybeClient;
    if (client == null) return '服务未初始化';

    try {
      final existing = await client
          .from('app_users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existing != null) {
        return '该账号已存在';
      }

      await client.from('app_users').insert({
        'username': username,
        'password': _packPassword(password),
        'nickname': nickname,
        'avatar_url': avatarUrl,
        'bio': bio,
        'email': email,
        'phone': phone,
        'profession': profession,
        'farm': farm ?? '',
      });

      return null;
    } catch (error) {
      debugPrint('AuthService.register failed: $error');
      return '注册失败，请稍后再试';
    }
  }

  Future<String?> resetPassword(String username, String newPassword) async {
    final client = SupabaseService.maybeClient;
    if (client == null) return '服务未初始化';

    try {
      final existing = await client
          .from('app_users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existing == null) {
        return '账号不存在';
      }

      await client
          .from('app_users')
          .update({'password': _packPassword(newPassword)})
          .eq('username', username);

      return null;
    } catch (error) {
      debugPrint('AuthService.resetPassword failed: $error');
      return '重置密码失败，请稍后再试';
    }
  }

  Future<String?> updateProfile({
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? email,
    String? phone,
    String? profession,
    String? farm,
  }) async {
    final client = SupabaseService.maybeClient;
    if (client == null) return '服务未初始化';
    if (_currentUser == null) return '未登录';

    try {
      final updates = <String, dynamic>{};
      if (nickname != null) updates['nickname'] = nickname;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (profession != null) updates['profession'] = profession;
      if (farm != null) updates['farm'] = farm;

      if (updates.isEmpty) return null;

      await client
          .from('app_users')
          .update(updates)
          .eq('username', _currentUser!.username);

      final refreshed = await client
          .from('app_users')
          .select('*')
          .eq('username', _currentUser!.username)
          .maybeSingle();

      if (refreshed != null) {
        _currentUser = AppUser.fromSupabase(refreshed);
      }

      return null;
    } catch (error) {
      debugPrint('AuthService.updateProfile failed: $error');
      return '更新失败，请稍后再试';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('auto_login_enabled');
    prefs.remove('auto_login_username');
    prefs.remove('auto_login_password');
  }
}
