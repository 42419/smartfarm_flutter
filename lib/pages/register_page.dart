import 'package:flutter/material.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _farmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty) {
      showAppToast('请输入账号');
      return;
    }
    if (password.isEmpty) {
      showAppToast('请输入密码');
      return;
    }
    if (password != confirmPassword) {
      showAppToast('两次密码不一致');
      return;
    }
    if (nickname.isEmpty) {
      showAppToast('请输入昵称');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.instance.register(
      username: username,
      password: password,
      nickname: nickname,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      farm: _farmController.text.trim().isEmpty
          ? null
          : _farmController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppToast(error);
    } else {
      showAppToast('注册成功');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2B3245)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "注册账号",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: Color(0xFF2B3245),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "创建您的智能农场账号",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              _buildInputField(
                controller: _usernameController,
                hintText: "请输入用户名",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _nicknameController,
                hintText: "请输入昵称",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _phoneController,
                hintText: "请输入手机号（选填）",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildPasswordField(
                controller: _passwordController,
                hintText: "请输入密码",
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 14),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: "请确认密码",
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _farmController,
                hintText: "请输入农场名称（选填）",
                icon: Icons.agriculture_outlined,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _loading ? null : _handleRegister,
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
                          "注 册",
                          style: TextStyle(
                            color: Color(0xFF2B3245),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text(
                  "已有账号？去登录",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
