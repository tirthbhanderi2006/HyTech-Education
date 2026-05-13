import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.primaryContainer, width: 3)), child: const Center(child: Text('RS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)))),
              const SizedBox(width: 16),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rahul Singh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('+91 98765 43210', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('rahul.singh@email.com', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
              IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () {}),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Visa Application Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _infoCard([
            const _InfoRow(label: 'Visa Type', value: '🇬🇧 UK Student Visa'),
            const _InfoRow(label: 'Passport No.', value: 'Z1234567'),
            const _InfoRow(label: 'Nationality', value: 'Indian'),
            const _InfoRow(label: 'Date of Birth', value: '15 March 2000', isLast: true),
          ]),
          const SizedBox(height: 20),
          const Text('Application Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _infoCard([
            const _InfoRow(label: 'Current Status', value: 'Docs Submitted'),
            const _InfoRow(label: 'Assigned Consultant', value: 'Rahul Kapoor'),
            const _InfoRow(label: 'Target Intake', value: 'Fall 2024', isLast: true),
          ]),
          const SizedBox(height: 20),
          const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _settingTile(Icons.notifications_outlined, 'Notification Preferences'),
          _settingTile(Icons.language, 'Language'),
          _settingTile(Icons.help_outline, 'Help & Support'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {},
              icon: const Icon(Icons.logout),
              label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
      child: Column(children: rows),
    );
  }

  Widget _settingTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.onSurface))),
        const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _InfoRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 15, color: AppColors.onSurface)),
        if (!isLast) ...[const SizedBox(height: 10), const Divider(color: AppColors.surfaceVariant, height: 1), const SizedBox(height: 10)],
      ],
    );
  }
}
