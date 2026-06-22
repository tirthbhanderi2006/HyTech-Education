import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/auth_api.dart';

class CommsLogScreen extends StatefulWidget {
  const CommsLogScreen({super.key});

  @override
  State<CommsLogScreen> createState() => _CommsLogScreenState();
}

class _CommsLogScreenState extends State<CommsLogScreen> {
  final AuthApi _api = AuthApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final users = await _api.listUsers();
      final List<Map<String, dynamic>> tempLogs = [];

      for (final u in users) {
        final formattedTime = DateFormat('MMM d, h:mm a').format(u.createdAt);

        // Standard Welcome Email Log
        tempLogs.add({
          'icon': Icons.mail_outline,
          'color': AppColors.secondary,
          'title': 'Welcome Email Sent',
          'subtitle': 'Onboarding details sent to ${u.email}',
          'time': formattedTime,
          'type': 'Email',
          'timestamp': u.createdAt.millisecondsSinceEpoch,
        });

        // Standard WhatsApp Checklist Log
        tempLogs.add({
          'icon': Icons.chat_bubble,
          'color': const Color(0xFF25D366),
          'title': 'WhatsApp Sent',
          'subtitle': 'Setup checklist sent to ${u.fullName}',
          'time': formattedTime,
          'type': 'WhatsApp',
          'timestamp': u.createdAt.millisecondsSinceEpoch - 1000,
        });

        // Upgrade push notification for premium users
        if (u.subscriptionTier != 'free') {
          tempLogs.add({
            'icon': Icons.notifications_outlined,
            'color': AppColors.primary,
            'title': 'Push Notification',
            'subtitle': '${u.fullName} upgraded to ${u.subscriptionTier.toUpperCase()}',
            'time': formattedTime,
            'type': 'Push',
            'timestamp': u.createdAt.millisecondsSinceEpoch + 5000,
          });
        }
      }

      // Sort logs: newest first
      tempLogs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      if (mounted) {
        setState(() {
          _logs = tempLogs;
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

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_loading) {
      bodyContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    } else if (_error != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load communication logs: $_error', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadLogs();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (_logs.isEmpty) {
      bodyContent = const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No communication logs found.',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.outline),
          ),
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: _loadLogs,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _logs.length,
          itemBuilder: (context, idx) {
            final log = _logs[idx];
            return _CommItem(
              icon: log['icon'] as IconData,
              color: log['color'] as Color,
              title: log['title'] as String,
              subtitle: log['subtitle'] as String,
              time: log['time'] as String,
              type: log['type'] as String,
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Communications Log', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.surfaceVariant, height: 2),
        ),
      ),
      body: bodyContent,
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
          const SizedBox(width: 8),
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
