import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
            child: Row(
              children: [
                Container(width: 60, height: 60, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Center(child: Text('A', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)))),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Admin User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                  Text('admin@visaflow.com', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  SizedBox(height: 4),
                  Text('Super Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ])),
                IconButton(icon: const Icon(Icons.edit, color: AppColors.primary), onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Platform Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Manage push and email alerts', onTap: () {}),
          _SettingsTile(icon: Icons.people_outline, title: 'Consultant Accounts', subtitle: 'Manage team members and roles', onTap: () {}),
          _SettingsTile(icon: Icons.payments_outlined, title: 'Razorpay Settings', subtitle: 'Configure payment gateway', onTap: () {}),
          _SettingsTile(icon: Icons.message_outlined, title: 'WhatsApp (WATI)', subtitle: 'Templates and automation config', onTap: () {}),
          _SettingsTile(icon: Icons.document_scanner_outlined, title: 'OCR Pipeline', subtitle: 'Document processing settings', onTap: () {}),
          const SizedBox(height: 24),
          const Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _SettingsTile(icon: Icons.lock_outline, title: 'Change Password', subtitle: 'Update your admin credentials', onTap: () {}),
          _SettingsTile(icon: Icons.history, title: 'Audit Log', subtitle: 'View all admin actions', onTap: () {}),
          const SizedBox(height: 24),
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primary, size: 22)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onSurface)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ])),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
