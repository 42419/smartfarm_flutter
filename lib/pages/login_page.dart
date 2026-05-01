import 'package:flutter/material.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _loading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text;

    if (account.isEmpty) {
      showAppToast('请输入用户名或邮箱');
      return;
    }
    if (password.isEmpty) {
      showAppToast('请输入密码');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.instance.login(account, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppToast(error);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, "/main", (context) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 80),
                Image.asset("assets/img/logo.png", width: 120),
                const SizedBox(height: 20),
                Text(
                  "禾寻",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "寻味自然，追寻良田",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: TextField(
                    controller: _accountController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: "用户名或邮箱",
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      hintText: "请输入密码",
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: cs.onSurfaceVariant),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.primary, width: 1.5),
                      backgroundColor: cs.surface,
                      foregroundColor: cs.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : Text(
                            "登 录",
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/register'),
                      child: Text("注册账号",
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("|",
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
                      child: Text("忘记密码",
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14)),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant, endIndent: 10)),
                    Text("其他登录方式",
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    Expanded(child: Divider(color: cs.outlineVariant, indent: 10)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50, height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Icon(Icons.wechat, size: 28, color: const Color(0xFF07C160)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
