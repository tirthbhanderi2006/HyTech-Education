import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/notifications_api.dart';
import '../../../core/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsApi _api = NotificationsApi();
  List<NotificationModel>? _notifications;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _api.markAsRead(id);
      _fetch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    } else if (_error != null) {
      content = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Failed to load notifications: $_error', style: const TextStyle(fontWeight: FontWeight.bold))));
    } else if (_notifications == null || _notifications!.isEmpty) {
      content = const Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No new notifications.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.outline))));
    } else {
      content = RefreshIndicator(
        onRefresh: _fetch,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications!.length,
          itemBuilder: (context, idx) {
            final n = _notifications![idx];
            IconData icon = Icons.notifications_outlined;
            Color bg = const Color(0xFFE0F2FE);
            Color iconColor = const Color(0xFF0284C7);

            if (n.type == 'payment') {
              icon = Icons.payment;
              bg = const Color(0xFFDCFCE7);
              iconColor = const Color(0xFF16A34A);
            } else if (n.type == 'document') {
              icon = Icons.verified;
              bg = const Color(0xFFD1FAE5);
              iconColor = AppColors.primary;
            } else if (n.type == 'deadline' || n.type == 'warning') {
              icon = Icons.warning;
              bg = AppColors.errorContainer;
              iconColor = AppColors.error;
            } else if (n.type == 'interview' || n.type == 'person_add') {
              icon = Icons.person_add;
              bg = const Color(0xFFEDE9FE);
              iconColor = AppColors.tertiary;
            }

            final timeStr = DateFormat('MMM d, h:mm a').format(n.sentAt);

            return InkWell(
              onTap: n.isRead ? null : () => _markRead(n.id),
              child: _NotifItem(
                icon: icon,
                bg: bg,
                iconColor: iconColor,
                title: n.title,
                subtitle: n.body,
                time: timeStr,
                isUnread: !n.isRead,
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Notifications', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2)),
      ),
      body: content,
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
