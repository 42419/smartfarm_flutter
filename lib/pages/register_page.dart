import 'package:flutter/material.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmController = TextEditingController();
  bool _obscureText = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _farmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty) {
      showAppToast('请输入邮箱');
      return;
    }
    if (username.isEmpty) {
      showAppToast('请输入用户名');
      return;
    }
    if (password.isEmpty) {
      showAppToast('请输入密码');
      return;
    }
    if (password != confirm) {
      showAppToast('两次密码不一致');
      return;
    }
    if (password.length < 6) {
      showAppToast('密码至少6位');
      return;
    }
    if (nickname.isEmpty) {
      showAppToast('请输入昵称');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.instance.register(
      email: email,
      password: password,
      username: username,
      nickname: nickname,
      phone: _phoneController.text.trim(),
      farm: _farmController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppToast(error);
    } else {
      showAppToast('注册成功');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (context) => false);
    }
  }

  Widget _buildField(TextEditingController controller, String hint,
      IconData icon,
      {bool isPassword = false, TextInputType? keyboardType}) {
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
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      setState(() => _obscureText = !_obscureText),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = Responsive.isLargeScreen(context);
    if (isLarge) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withValues(alpha: 0.08),
                      cs.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/img/logo.png", width: 120),
                      const SizedBox(height: 28),
                      Text(
                        "禾寻",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          color: cs.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "创建新账号",
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 32),
                    child: _buildFormContent(context, cs),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('注册账号', style: TextStyle(color: cs.onSurface)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildFormContent(context, cs),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, ColorScheme cs) {
    final isLarge = Responsive.isLargeScreen(context);
    final double spacer = 14;

    Widget makeRow(Widget left, Widget right) {
      if (isLarge) {
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      }
      return Column(children: [left, SizedBox(height: spacer), right]);
    }

    return Column(
      children: [
        makeRow(
          _buildField(_emailController, '邮箱（必填）', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          _buildField(
              _usernameController, '用户名（必填）', Icons.person_outline),
        ),
        SizedBox(height: spacer),
        makeRow(
          _buildField(
              _passwordController, '密码（至少6位）', Icons.lock_outline_rounded,
              isPassword: true),
          _buildField(
              _confirmController, '确认密码', Icons.lock_outline_rounded,
              isPassword: true),
        ),
        SizedBox(height: spacer),
        makeRow(
          _buildField(
              _nicknameController, '昵称（必填）', Icons.badge_outlined),
          _buildField(_phoneController, '手机号（选填）', Icons.phone_outlined,
              keyboardType: TextInputType.phone),
        ),
        SizedBox(height: spacer),
        _buildField(
            _farmController, '农场名称（选填）', Icons.agriculture_outlined),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _loading ? null : _handleRegister,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary, width: 1.5),
              backgroundColor: cs.surface,
              foregroundColor: cs.onSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary))
                : Text("注 册",
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('已有账号？返回登录',
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        ),
      ],
    );
  }
}
