import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          _NotifItem(icon: Icons.payment, bg: Color(0xFFDCFCE7), iconColor: Color(0xFF16A34A), title: 'Payment Received', subtitle: '₹15,000 from Arjun Kapoor via Razorpay', time: '10 min ago', isUnread: true),
          _NotifItem(icon: Icons.verified, bg: Color(0xFFD1FAE5), iconColor: AppColors.primary, title: 'Document Verified', subtitle: "Priya Sharma's passport copy approved", time: '1 hour ago', isUnread: true),
          _NotifItem(icon: Icons.person_add, bg: Color(0xFFEDE9FE), iconColor: AppColors.tertiary, title: 'New Lead Added', subtitle: 'Neha Gupta — UK Student Visa enquiry', time: '3 hours ago'),
          _NotifItem(icon: Icons.warning, bg: AppColors.errorContainer, iconColor: AppColors.error, title: 'Action Required', subtitle: '12 documents pending review for >48hrs', time: 'Yesterday'),
          _NotifItem(icon: Icons.message, bg: Color(0xFFE0F2FE), iconColor: Color(0xFF0284C7), title: 'WhatsApp Automation', subtitle: 'Bulk reminder sent to 15 leads', time: 'Yesterday'),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }
}
