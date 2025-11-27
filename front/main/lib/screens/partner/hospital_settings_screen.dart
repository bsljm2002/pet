import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class HospitalSettingsScreen extends StatelessWidget {
  const HospitalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8D8D0),
      appBar: AppBar(
        title: const Text('병원 설정'),
        backgroundColor: const Color(0xFF3BA688),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          _buildSettingSection(
            context,
            icon: Icons.person,
            title: '계정 정보',
            items: [
              _buildSettingItem(context, '프로필 수정', Icons.edit),
              _buildSettingItem(context, '비밀번호 변경', Icons.lock),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingSection(
            context,
            icon: Icons.business,
            title: '병원 정보',
            items: [
              _buildSettingItem(context, '병원 정보 수정', Icons.local_hospital),
              _buildSettingItem(context, '진료 시간 설정', Icons.access_time),
              _buildSettingItem(context, '진료 과목 설정', Icons.medical_services),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingSection(
            context,
            icon: Icons.notifications,
            title: '알림 설정',
            items: [
              _buildSettingItem(context, '예약 알림', Icons.notifications_active),
              _buildSettingItem(context, '문의 알림', Icons.message),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingSection(
            context,
            icon: Icons.info,
            title: '기타',
            items: [
              _buildSettingItem(context, '공지사항', Icons.campaign),
              _buildSettingItem(context, '이용약관', Icons.description),
              _buildSettingItem(context, '개인정보처리방침', Icons.privacy_tip),
              _buildSettingItem(context, '로그아웃', Icons.logout, isDestructive: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3BA688), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3E3F),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, IconData icon, {bool isDestructive = false}) {
    return InkWell(
      onTap: () async {
        if (title == '로그아웃') {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(
                    color: Color(0xFF2D3E3F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text('정말 로그아웃 하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('취소', style: TextStyle(color: Colors.grey[600])),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        color: Color(0xFF3BA688),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            final authService = AuthService();
            await authService.logout();

            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFF5A6C6D),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? Colors.red : const Color(0xFF2D3E3F),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : const Color(0xFF5A6C6D),
            ),
          ],
        ),
      ),
    );
  }
}
