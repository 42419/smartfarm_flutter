import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE2EAF4), // 浅蓝灰渐变顶部
            Color(0xFFF5F7FA), // 淡灰底色
          ],
          stops: [0.0, 0.25],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 依托外层渐变
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildUserInfo(),
                const SizedBox(height: 20),
                _buildFarmCard(),
                const SizedBox(height: 16),
                _buildSettingsCard1(),
                const SizedBox(height: 16),
                _buildSettingsCard2(),
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

  // 退出登录按钮
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
          onPressed: () {
            // 返回登录页并清空路由栈
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          },
          child: const Text(
            '退出登录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // 顶部大头像与用户信息
  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'YunFei',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 28, color: Colors.black87),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '管理账号、会员权益等',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              // 小标签
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '1个农场',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 1,
                      height: 10,
                      color: Colors.blueGrey.withValues(alpha: 0.3),
                    ),
                    Text(
                      '42个智能设备',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 右侧大头像
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // 农场所属小卡片 (对应图中的 "xxx的家")
  Widget _buildFarmCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '东郊农场',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1个成员',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                // 成员小头像占位
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFF0F2F5),
                  child: Icon(Icons.person, size: 18, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                // 添加按钮
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 第一组设置卡片
  Widget _buildSettingsCard1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildListTile(
              icon: Icons.battery_charging_full,
              iconColor: Colors.amber,
              title: '设备耗材',
            ),
            _buildListTile(
              icon: Icons.graphic_eq,
              iconColor: Colors.blueAccent,
              title: '语音控制',
            ),
            _buildListTile(
              icon: Icons.wifi_tethering,
              iconColor: Colors.purpleAccent,
              title: '农场网络',
              trailingText: '良好',
            ),
            _buildListTile(
              icon: Icons.hub_outlined,
              iconColor: Colors.green,
              title: '中枢与网关',
            ),
            _buildListTile(
              icon: Icons.api,
              iconColor: Colors.lightBlue,
              title: '连接三方平台',
            ),
            _buildListTile(
              icon: Icons.settings,
              iconColor: Colors.blueGrey,
              title: '更多设置',
              hasRedDot: true,
            ),
          ],
        ),
      ),
    );
  }

  // 第二组设置卡片
  Widget _buildSettingsCard2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildListTile(
              icon: Icons.shopping_bag_outlined,
              iconColor: Colors.amber,
              title: '农资商城',
            ),
            _buildListTile(
              icon: Icons.home_outlined,
              iconColor: Colors.green,
              title: '全场智能',
            ),
            _buildListTile(
              icon: Icons.support_agent,
              iconColor: Colors.orangeAccent,
              title: '农业服务',
            ),
          ],
        ),
      ),
    );
  }

  // 通用的列表项构造器
  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    bool hasRedDot = false,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            if (trailingText != null) const SizedBox(width: 8),
            if (hasRedDot)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
