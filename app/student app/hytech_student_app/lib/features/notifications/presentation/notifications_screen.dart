import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Notifications', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotifItem(icon: Icons.event_available, bg: Color(0xFFE0F2FE), iconColor: Color(0xFF0284C7), title: 'Appointment Confirmed', subtitle: 'Video consultation — Tomorrow 10:30 AM', time: '2 hours ago', isUnread: true),
          _NotifItem(icon: Icons.check_circle, bg: Color(0xFFD1FAE5), iconColor: AppColors.primary, title: 'Passport Verified', subtitle: 'Your passport copy has been approved', time: '5 hours ago', isUnread: true),
          _NotifItem(icon: Icons.warning_amber, bg: AppColors.errorContainer, iconColor: AppColors.error, title: 'Action Required', subtitle: 'Degree Certificate blurry — please re-upload', time: 'Yesterday'),
          _NotifItem(icon: Icons.message, bg: Color(0xFFF0FDF4), iconColor: Color(0xFF16A34A), title: 'WhatsApp Reminder', subtitle: 'Upload your bank statements before the deadline', time: '2 days ago'),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color bg, iconColor;
  final String title, subtitle, time;
  final bool isUnread;
  const _NotifItem({required this.icon, required this.bg, required this.iconColor, required this.title, required this.subtitle, required this.time, this.isUnread = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withOpacity(0.04) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnread ? AppColors.primary.withOpacity(0.3) : AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface))),
            if (isUnread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}
