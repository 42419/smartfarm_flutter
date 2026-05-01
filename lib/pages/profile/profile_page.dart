import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'widgets/farm_card.dart';
import 'widgets/settings_card.dart';
import 'widgets/user_info_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2EAF4), Color(0xFFF5F7FA)],
          stops: [0.0, 0.25],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                UserInfoSection(
                  onEditTap: () async {
                    await Navigator.of(context).pushNamed('/edit-profile');
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                const FarmCard(),
                const SizedBox(height: 16),
                const SettingsCard(tiles: [
                  SettingTile(
                    icon: Icons.battery_charging_full,
                    iconColor: Colors.amber,
                    title: '设备耗材',
                  ),
                  SettingTile(
                    icon: Icons.graphic_eq,
                    iconColor: Colors.blueAccent,
                    title: '语音控制',
                  ),
                  SettingTile(
                    icon: Icons.wifi_tethering,
                    iconColor: Colors.purpleAccent,
                    title: '农场网络',
                    trailingText: '良好',
                  ),
                  SettingTile(
                    icon: Icons.hub_outlined,
                    iconColor: Colors.green,
                    title: '中枢与网关',
                  ),
                  SettingTile(
                    icon: Icons.api,
                    iconColor: Colors.lightBlue,
                    title: '连接三方平台',
                  ),
                  SettingTile(
                    icon: Icons.settings,
                    iconColor: Colors.blueGrey,
                    title: '更多设置',
                    hasRedDot: true,
                  ),
                ]),
                const SizedBox(height: 16),
                const SettingsCard(tiles: [
                  SettingTile(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: Colors.amber,
                    title: '农资商城',
                  ),
                  SettingTile(
                    icon: Icons.home_outlined,
                    iconColor: Colors.green,
                    title: '全场智能',
                  ),
                  SettingTile(
                    icon: Icons.support_agent,
                    iconColor: Colors.orangeAccent,
                    title: '农业服务',
                  ),
                ]),
                const SizedBox(height: 30),
                _buildLogoutButton(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.redAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () async {
            await AuthService.instance.logout();
            if (!context.mounted) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          },
          child: const Text('退出登录',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
