import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _rememberPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.local_florist_outlined,
                size: 60,
                color: Color(0xFF2B3245),
              ),
              const SizedBox(height: 16),
              const Text(
                "智慧农业",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Color(0xFF2B3245),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "科技赋能，智慧耕种",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 50),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: "请输入手机号",
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey),
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
                      value: _rememberPassword,
                      onChanged: (value) {
                        setState(() {
                          _rememberPassword = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "记住密码",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/main",
                      (context) => false,
                    );
                  },
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
                  child: const Text(
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
                    onTap: () {},
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
                    onTap: () {},
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Colors.grey,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "安全加密登录，保障您的账号安全",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
