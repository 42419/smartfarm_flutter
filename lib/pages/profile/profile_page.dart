import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../utils/responsive.dart';
import 'widgets/farm_card.dart';
import 'widgets/settings_card.dart';
import 'widgets/user_info_section.dart';
import 'widgets/device_supplies_page.dart';
import 'widgets/farm_network_page.dart';
import 'widgets/agri_mall_page.dart';
import 'widgets/agri_service_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.modeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.modeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  String get _themeLabel {
    switch (ThemeService.instance.mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  IconData get _themeIcon {
    switch (ThemeService.instance.mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  void _showThemeSheet() {
    final currentMode = ThemeService.instance.mode;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '外观设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _themeOption(ctx, cs, Icons.settings_brightness, '跟随系统', ThemeMode.system, currentMode == ThemeMode.system),
                _themeOption(ctx, cs, Icons.light_mode, '浅色模式', ThemeMode.light, currentMode == ThemeMode.light),
                _themeOption(ctx, cs, Icons.dark_mode, '深色模式', ThemeMode.dark, currentMode == ThemeMode.dark),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeOption(
    BuildContext sheetCtx,
    ColorScheme cs,
    IconData icon,
    String title,
    ThemeMode mode,
    bool selected,
  ) {
    return InkWell(
      onTap: () {
        ThemeService.instance.setMode(mode);
        Navigator.of(sheetCtx).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? Colors.green.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: selected ? Colors.green : cs.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            if (selected) const Icon(Icons.check, size: 22, color: Colors.green),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = Responsive.isLargeScreen(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A2332), const Color(0xFF121212)]
              : [const Color(0xFFE2EAF4), const Color(0xFFF5F7FA)],
          stops: const [0.0, 0.25],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: isLarge
              ? _buildLandscapeBody(context)
              : _buildMobileBody(context),
        ),
      ),
    );
  }

  Widget _buildLandscapeBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    UserInfoSection(
                      onEditTap: () async {
                        await Navigator.of(context)
                            .pushNamed('/edit-profile');
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    const FarmCard(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    SettingsCard(tiles: [
                      SettingTile(
                        icon: Icons.battery_charging_full,
                        iconColor: Colors.amber,
                        title: '设备耗材',
                        onTap: () =>
                            _push(context, const DeviceSuppliesPage()),
                      ),
                      SettingTile(
                        icon: Icons.wifi_tethering,
                        iconColor: Colors.purpleAccent,
                        title: '农场网络',
                        trailingText: '良好',
                        onTap: () =>
                            _push(context, const FarmNetworkPage()),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SettingsCard(tiles: [
                      SettingTile(
                        icon: _themeIcon,
                        iconColor: Colors.blueGrey,
                        title: '外观',
                        trailingText: _themeLabel,
                        onTap: _showThemeSheet,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SettingsCard(tiles: [
                      SettingTile(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Colors.amber,
                        title: '农资商城',
                        onTap: () =>
                            _push(context, const AgriMallPage()),
                      ),
                      SettingTile(
                        icon: Icons.support_agent,
                        iconColor: Colors.orangeAccent,
                        title: '农业服务',
                        onTap: () =>
                            _push(context, const AgriServicePage()),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return SingleChildScrollView(
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
          SettingsCard(tiles: [
            SettingTile(
              icon: Icons.battery_charging_full,
              iconColor: Colors.amber,
              title: '设备耗材',
              onTap: () => _push(context, const DeviceSuppliesPage()),
            ),
            SettingTile(
              icon: Icons.wifi_tethering,
              iconColor: Colors.purpleAccent,
              title: '农场网络',
              trailingText: '良好',
              onTap: () => _push(context, const FarmNetworkPage()),
            ),
          ]),
          const SizedBox(height: 16),
          SettingsCard(tiles: [
            SettingTile(
              icon: _themeIcon,
              iconColor: Colors.blueGrey,
              title: '外观',
              trailingText: _themeLabel,
              onTap: _showThemeSheet,
            ),
          ]),
          const SizedBox(height: 16),
          SettingsCard(tiles: [
            SettingTile(
              icon: Icons.shopping_bag_outlined,
              iconColor: Colors.amber,
              title: '农资商城',
              onTap: () => _push(context, const AgriMallPage()),
            ),
            SettingTile(
              icon: Icons.support_agent,
              iconColor: Colors.orangeAccent,
              title: '农业服务',
              onTap: () => _push(context, const AgriServicePage()),
            ),
          ]),
          const SizedBox(height: 30),
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
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
