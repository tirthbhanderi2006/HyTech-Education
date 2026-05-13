import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CommsLogScreen extends StatelessWidget {
  const CommsLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Communications Log', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)), bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _CommItem(icon: Icons.chat_bubble, color: Color(0xFF25D366), title: 'WhatsApp Sent', subtitle: 'Follow-up reminder to Arjun Kapoor', time: '10:30 AM', type: 'WhatsApp'),
          _CommItem(icon: Icons.mail_outline, color: AppColors.secondary, title: 'Email Sent', subtitle: 'Document checklist to Priya Sharma', time: '9:15 AM', type: 'Email'),
          _CommItem(icon: Icons.notifications_outlined, color: AppColors.primary, title: 'Push Notification', subtitle: 'Appointment reminder — Vikram Singh', time: '8:00 AM', type: 'Push'),
          _CommItem(icon: Icons.chat_bubble, color: Color(0xFF25D366), title: 'WhatsApp Received', subtitle: 'Reply from Ananya Sharma', time: 'Yesterday', type: 'WhatsApp'),
        ],
      ),
    );
  }
}

class _CommItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, time, type;
  const _CommItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(time, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(type, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))),
          ]),
        ],
      ),
    );
  }
}
