import 'package:flutter/material.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _professionController;
  late final TextEditingController _farmController;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _professionController =
        TextEditingController(text: user?.profession ?? '');
    _farmController = TextEditingController(text: user?.farm ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _professionController.dispose();
    _farmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      showAppToast('昵称不能为空');
      return;
    }

    setState(() => _loading = true);

    final error = await AuthService.instance.updateProfile(
      nickname: nickname,
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      profession: _professionController.text.trim().isEmpty
          ? null
          : _professionController.text.trim(),
      farm: _farmController.text.trim().isEmpty
          ? null
          : _farmController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      showAppToast(error);
    } else {
      showAppToast('保存成功');
      Navigator.of(context).pop(true);
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
        title: const Text(
          '编辑资料',
          style: TextStyle(
            color: Color(0xFF2B3245),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _handleSave,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2B3245),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Color(0xFF2B3245),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildInputField(
                controller: _nicknameController,
                hintText: '昵称',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _avatarUrlController,
                hintText: '头像链接（选填）',
                icon: Icons.link,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _bioController,
                hintText: '个人简介（选填）',
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _phoneController,
                hintText: '手机号',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _emailController,
                hintText: '邮箱',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _professionController,
                hintText: '职业',
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _farmController,
                hintText: '农场名称',
                icon: Icons.agriculture_outlined,
              ),
              const SizedBox(height: 40),
            ],
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
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Icon(icon, color: Colors.grey),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
