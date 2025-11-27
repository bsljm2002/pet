import 'package:flutter/material.dart';

class SitterSettingsScreen extends StatelessWidget {
  const SitterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8D8D0),
      appBar: AppBar(
        title: const Text('펫시터 설정'),
        backgroundColor: const Color(0xFF3BA688),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          _buildSettingSection(
            icon: Icons.person,
            title: '계정 정보',
            items: [
              _buildSettingItem('프로필 수정', Icons.edit),
              _buildSettingItem('비밀번호 변경', Icons.lock),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingSection(
            icon: Icons.pets,
            title: '펫시터 정보',
            items: [
              _buildSettingItem('펫시터 정보 수정', Icons.badge),
              _buildSettingItem('근무 시간 설정', Icons.access_time),
              _buildSettingItem('서비스 종류 설정', Icons.work),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingSection(
            icon: Icons.notifications,
            title: '알림 설정',
            items: [
              _buildSettingItem('예약 알림', Icons.notifications_active),
              _buildSettingItem('문의 알림', Icons.message),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingSection(
            icon: Icons.info,
            title: '기타',
            items: [
              _buildSettingItem('공지사항', Icons.campaign),
              _buildSettingItem('이용약관', Icons.description),
              _buildSettingItem('개인정보처리방침', Icons.privacy_tip),
              _buildSettingItem('로그아웃', Icons.logout, isDestructive: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
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

  Widget _buildSettingItem(String title, IconData icon, {bool isDestructive = false}) {
    return InkWell(
      onTap: () {
        // TODO: 설정 항목 클릭 처리
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
