import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

class UserInfoSection extends StatelessWidget {
  const UserInfoSection({
    super.key,
    required this.onEditTap,
  });

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final nickname = user?.nickname ?? 'YunFei';
    final bio = user?.bio;
    final avatarUrl = user?.avatarUrl;
    final hasBio = bio?.isNotEmpty == true;
    final hasAvatarUrl = avatarUrl?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onEditTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nickname,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 28, color: Theme.of(context).colorScheme.onSurface),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasBio ? bio! : '管理账号、会员权益等',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('1个农场',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              width: 1,
                              height: 10,
                              color: Colors.blueGrey
                                  .withValues(alpha: 0.3),
                            ),
                            Text('42个智能设备',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasAvatarUrl
                        ? Image.network(
                            avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person,
                                  size: 44, color: Colors.grey);
                            },
                          )
                        : const Icon(Icons.person,
                            size: 44, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (hasBio) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(user?.phone ?? '未设置',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.email_outlined,
                    size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(user?.email ?? '未设置',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
