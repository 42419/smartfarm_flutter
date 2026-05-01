import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

class FarmCard extends StatelessWidget {
  const FarmCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              children: [
                Text(
                  AuthService.instance.currentUser?.farm.isNotEmpty ==
                          true
                      ? AuthService.instance.currentUser!.farm
                      : '东郊农场',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('1个成员',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -35,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: ClipOval(
                            child: _buildSmallAvatar(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(Icons.add,
                              size: 22, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAvatar() {
    final avatarUrl = AuthService.instance.currentUser?.avatarUrl;
    final hasAvatarUrl = avatarUrl?.isNotEmpty == true;
    if (hasAvatarUrl) {
      return Image.network(
        avatarUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 28, color: Colors.grey);
        },
      );
    }
    return const Icon(Icons.person, size: 28, color: Colors.grey);
  }
}
