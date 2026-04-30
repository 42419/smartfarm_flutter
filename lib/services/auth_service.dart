import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/config.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  AppUser? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && Supabase.instance.client.auth.currentSession != null;

  Future<void> init() async {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && _currentUser == null) {
        _loadProfile();
      } else if (session == null) {
        _currentUser = null;
      }
    });

    if (Supabase.instance.client.auth.currentSession != null) {
      await _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final client = SupabaseService.maybeClient;
    if (client == null) return;

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final rows = await client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (rows != null) {
        _currentUser = AppUser.fromProfilesRow(rows);
      }
    } catch (error) {
      debugPrint('_loadProfile failed: $error');
    }
  }

  Future<String?> login(String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername;

      if (!emailOrUsername.contains('@')) {
        final lookedUp = await Supabase.instance.client.rpc(
          'lookup_email_by_username',
          params: {'p_username': emailOrUsername},
        );
        if (lookedUp == null) return '用户不存在';
        email = lookedUp.toString();
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '登录失败: $e';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String username,
    required String nickname,
    String? phone,
    String? farm,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'nickname': nickname,
          'phone': phone ?? '',
          'farm': farm ?? '',
        },
      );

      if (response.user == null) {
        return '注册失败，请重试';
      }

      await _loadProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '注册失败: $e';
    }
  }

  Future<String?> resetPassword(String email, String newPassword) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_user_id_by_email',
        params: {'p_email': email},
      );
      final userId = response?.toString();
      if (userId == null || userId.isEmpty) return '该邮箱未注册';

      final dio = Dio();
      await dio.put(
        '${Config.supabaseUrl}/auth/v1/admin/users/$userId',
        data: {'password': newPassword},
        options: Options(headers: {
          'Authorization': 'Bearer ${Config.supabaseServiceRoleKey}',
          'Content-Type': 'application/json',
        }),
      );
      return null;
    } catch (e) {
      return '重置失败: $e';
    }
  }

  Future<String?> updateProfile({
    String? username,
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? email,
    String? phone,
    String? profession,
    String? farm,
  }) async {
    if (_currentUser == null) return '未登录';

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (username != null) updates['username'] = username;
    if (email != null) updates['email'] = email;
    if (nickname != null) updates['nickname'] = nickname;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (profession != null) updates['profession'] = profession;
    if (farm != null) updates['farm'] = farm;

    final client = SupabaseService.maybeClient;
    if (client == null) return '数据库未初始化';

    try {
      await client
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      final rows = await client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      if (rows != null) {
        _currentUser = AppUser.fromProfilesRow(rows);
      }
      return null;
    } catch (e) {
      return '更新失败: $e';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
