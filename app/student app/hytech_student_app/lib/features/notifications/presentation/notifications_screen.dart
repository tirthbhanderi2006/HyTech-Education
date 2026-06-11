import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/notifications_bloc.dart';
import '../../../core/models/notification_model.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(NotificationsLoadRequested());
  }

  IconData _getIcon(String type) {
    return switch (type) {
      'appointment' => Icons.event_available,
      'document' => Icons.check_circle,
      'action_required' => Icons.warning_amber,
      _ => Icons.message,
    };
  }

  Color _getBg(String type) {
    return switch (type) {
      'appointment' => const Color(0xFFE0F2FE),
      'document' => const Color(0xFFD1FAE5),
      'action_required' => AppColors.errorContainer,
      _ => const Color(0xFFF0FDF4),
    };
  }

  Color _getIconColor(String type) {
    return switch (type) {
      'appointment' => const Color(0xFF0284C7),
      'document' => AppColors.primary,
      'action_required' => AppColors.error,
      _ => const Color(0xFF16A34A),
    };
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.surfaceVariant, height: 2),
        ),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Failed to load notifications: ${state.message}', style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationsBloc>().add(NotificationsLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is NotificationsLoaded) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return GestureDetector(
                  onTap: () {
                    if (!notif.isRead) {
                      context.read<NotificationsBloc>().add(NotificationMarkReadRequested(notif.id));
                    }
                  },
                  child: _NotifItem(
                    icon: _getIcon(notif.type),
                    bg: _getBg(notif.type),
                    iconColor: _getIconColor(notif.type),
                    title: notif.title,
                    subtitle: notif.body,
                    time: _formatTime(notif.sentAt),
                    isUnread: !notif.isRead,
                  ),
                );
              },
            );
          }
          return const Center(child: Text('No notifications.'));
        },
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color bg, iconColor;
  final String title, subtitle, time;
  final bool isUnread;
  const _NotifItem({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
  });

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface))),
                    if (isUnread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ],
                ),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
