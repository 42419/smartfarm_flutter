import 'package:flutter/material.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureText = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty) {
      showAppToast('请输入注册邮箱');
      return;
    }
    if (password.isEmpty) {
      showAppToast('请输入新密码');
      return;
    }
    if (password.length < 6) {
      showAppToast('密码至少6位');
      return;
    }
    if (password != confirm) {
      showAppToast('两次密码不一致');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.instance.resetPassword(email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppToast(error);
    } else {
      showAppToast('密码重置成功，请重新登录');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('重置密码', style: TextStyle(color: cs.onSurface)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Icon(Icons.lock_reset, size: 56, color: cs.primary),
                const SizedBox(height: 16),
                Text('输入注册邮箱和新密码即可重置',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 24),
                _buildField(_emailController, '注册邮箱', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildField(_passwordController, '新密码（至少6位）', Icons.lock_outline_rounded, isPassword: true),
                const SizedBox(height: 14),
                _buildField(_confirmController, '确认新密码', Icons.lock_outline_rounded, isPassword: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _handleReset,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.primary, width: 1.5),
                      backgroundColor: cs.surface,
                      foregroundColor: cs.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                        : Text('重置密码', style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: cs.onSurfaceVariant),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
