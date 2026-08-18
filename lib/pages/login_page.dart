import 'package:flutter/material.dart';

import '../services/app_feedback.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController(text: "yunfei");
  final TextEditingController _passwordController = TextEditingController(text: "yunfeiii");
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
                      Image.asset("assets/img/logo.png", width: 140),
                      const SizedBox(height: 32),
                      Text(
                        "禾寻",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 42,
                          color: cs.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "寻味自然，追寻良田",
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "智慧农业管理平台",
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 100, 48, 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _buildForm(context, cs, showHeader: true),
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
                _buildForm(context, cs, showHeader: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ColorScheme cs, {bool showHeader = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Text(
            "欢迎回来",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "登录您的禾寻账号",
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
        ],
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
              prefixIcon:
                  Icon(Icons.person_outline, color: cs.onSurfaceVariant),
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
              prefixIcon:
                  Icon(Icons.lock_outline_rounded, color: cs.onSurfaceVariant),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => _obscureText = !_obscureText),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.primary),
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
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '登录即表示您已同意',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
            GestureDetector(
              onTap: () =>
                  _showAgreement(context, '用户协议', _userAgreement),
              child: Text(
                '《用户协议》',
                style: TextStyle(color: cs.primary, fontSize: 11),
              ),
            ),
            Text(
              '和',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
            GestureDetector(
              onTap: () =>
                  _showAgreement(context, '隐私政策', _privacyPolicy),
              child: Text(
                '《隐私政策》',
                style: TextStyle(color: cs.primary, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed('/register'),
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
              onTap: () =>
                  Navigator.of(context).pushNamed('/forgot-password'),
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
            Expanded(
                child: Divider(color: cs.outlineVariant, endIndent: 10)),
            Text("其他登录方式",
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            Expanded(
                child: Divider(color: cs.outlineVariant, indent: 10)),
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
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.wechat,
                  size: 28, color: const Color(0xFF07C160)),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  static const String _userAgreement = '''
用户协议

最后更新日期：2026年5月

欢迎使用智慧农场管理系统（以下简称"本系统"）。请您仔细阅读以下条款。

一、服务说明
本系统提供农场环境监测、设备远程控制、数据分析及农资商城等服务。

二、免责声明
1. 本应用中所有页面展示的图片、视频等素材来源于互联网公开资源，仅用于UI展示参考，版权归原作者所有。如有侵权行为，请联系我们删除。
2. 本系统提供的数据监测结果仅供参考，不构成农业生产的唯一决策依据。
3. 因不可抗力、网络故障、设备故障等原因导致的服务中断，本系统不承担责任。

三、用户责任
1. 用户应妥善保管账号密码，因账号泄露导致的损失由用户自行承担。
2. 用户不得利用本系统从事违法活动。

四、服务变更
我们保留随时修改或中断服务的权利，修改后的协议将在应用内公布。

如有疑问，请联系客服。
''';

  static const String _privacyPolicy = '''
隐私政策

最后更新日期：2026年5月

我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全。

一、信息收集
1. 注册信息：用户名、密码、农场名称等基本注册信息。
2. 设备信息：为保障服务稳定性，我们可能收集设备型号、操作系统版本等匿名化信息。
3. 农场数据：温度、湿度、光照等环境监测数据仅用于为您提供分析服务。

二、信息使用
1. 您的个人信息仅用于提供和改进服务，不会用于其他商业用途。
2. 未经您明确同意，我们不会向第三方共享您的个人信息。

三、信息安全
我们采用行业标准的安全措施保护您的个人信息，包括数据加密和访问控制。

四、免责声明
本应用中所有页面展示的图片、视频等素材来源于互联网，仅供UI展示参考使用，如涉及版权问题请联系我们处理。

五、条款更新
我们可能适时更新本隐私政策，更新后的政策将在应用内公布。

如有疑问，请联系客服。
''';

  void _showAgreement(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
