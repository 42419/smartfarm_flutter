import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _autoLogin = false;
  bool _loading = false;
  bool _autoLoggingIn = true;
  bool _autoLoginFailed = false;

  static const _keyUsername = 'auto_login_username';
  static const _keyPassword = 'auto_login_password';
  static const _keyEnabled = 'auto_login_enabled';

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyEnabled) ?? false;
      if (!enabled) {
        if (mounted) setState(() => _autoLoggingIn = false);
        return;
      }

      final username = prefs.getString(_keyUsername) ?? '';
      final password = prefs.getString(_keyPassword) ?? '';
      if (username.isEmpty || password.isEmpty) {
        await _clearCredentials();
        if (mounted) setState(() => _autoLoggingIn = false);
        return;
      }

      _usernameController.text = username;
      _passwordController.text = password;

      await Future.delayed(const Duration(milliseconds: 500));

      String? error;
      for (var i = 0; i < 2; i++) {
        error = await AuthService.instance.login(username, password);
        if (error == null) break;
        if (i == 0) await Future.delayed(const Duration(seconds: 1));
      }

      if (!mounted) return;

      if (error != null) {
        await _clearCredentials();
        if (mounted) {
          setState(() {
            _autoLoggingIn = false;
            _autoLogin = false;
            _autoLoginFailed = true;
          });
        }
      } else {
        Navigator.pushNamedAndRemoveUntil(context, "/main", (context) => false);
      }
    } catch (e, stack) {
      debugPrint('Auto-login exception: $e');
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        await _clearCredentials();
        setState(() {
          _autoLoggingIn = false;
          _autoLogin = false;
          _autoLoginFailed = true;
        });
      }
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      showAppToast('请输入账号');
      return;
    }
    if (password.isEmpty) {
      showAppToast('请输入密码');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.instance.login(username, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppToast(error);
    } else {
      if (_autoLogin) {
        await _saveCredentials(username, password);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/main", (context) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_autoLoggingIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/img/logo.png", width: 120),
              const SizedBox(height: 16),
              const Text(
                "禾寻",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Color(0xFF2B3245),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2B3245),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset("assets/img/logo.png", width: 120),
              const SizedBox(height: 20),
              const Text(
                "禾寻",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Color(0xFF2B3245),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "寻味自然，追寻良田",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: "请输入用户名或手机号",
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: "请输入密码",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _autoLogin,
                      onChanged: (value) {
                        setState(() {
                          _autoLogin = value ?? false;
                        });
                        if (_autoLogin == false) {
                          _clearCredentials();
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "自动登录",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF2B3245),
                      width: 1.5,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2B3245),
                          ),
                        )
                      : const Text(
                          "登 录",
                          style: TextStyle(
                            color: Color(0xFF2B3245),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // 注册与忘记密码
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: const Text(
                      "注册账号",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "|",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: const Text(
                      "忘记密码",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, endIndent: 10),
                  ),
                  const Text(
                    "其他登录方式",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, indent: 10),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Image.asset(
                      "assets/img/wechat.png",
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Image.asset(
                      "assets/img/QQ.png",
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              if (_autoLoginFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "自动登录失败，请手动登录",
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
    }
  }
