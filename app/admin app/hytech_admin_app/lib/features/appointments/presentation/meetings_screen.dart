import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/meeting_model.dart';
import '../bloc/meetings_bloc.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MeetingsBloc>().add(MeetingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingsBloc, MeetingsState>(
      listener: (context, state) {
        if (state is MeetingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Counseling Sessions', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2)),
        ),
        body: BlocBuilder<MeetingsBloc, MeetingsState>(
          builder: (context, state) {
            if (state is MeetingsLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is MeetingsLoaded) {
              final meetings = state.meetings;
              if (meetings.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MeetingsBloc>().add(MeetingsLoadRequested());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: meetings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return _meetingCard(meeting);
                  },
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Failed to load counseling sessions.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MeetingsBloc>().add(MeetingsLoadRequested());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Appointments Scheduled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no counseling sessions booked in the system at this moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meetingCard(MeetingModel meeting) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(meeting.startTime);
    final timeStr = '${DateFormat('hh:mm a').format(meeting.startTime)} - ${DateFormat('hh:mm a').format(meeting.endTime)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.surfaceVariant,
            offset: Offset(0, 3),
            blurRadius: 4,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                _statusBadge(meeting.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24, thickness: 1, color: AppColors.surfaceVariant),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface),
                      ),
                      Text(
                        'Counselor ID: ${meeting.counselorId.substring(0, 8)}...',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${meeting.notes}',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (meeting.canJoin)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _launchURL(meeting.meetLink!),
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      label: const Text('Join Meet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (meeting.canJoin) const SizedBox(width: 12),
                if (!meeting.isCancelled) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showRescheduleDialog(meeting),
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _confirmCancel(meeting.id),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = AppColors.surfaceVariant;
    Color fg = AppColors.onSurfaceVariant;
    String label = status.toUpperCase();

    if (status == 'confirmed') {
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green;
      label = 'CONFIRMED';
    } else if (status == 'rescheduled') {
      bg = Colors.amber.withOpacity(0.12);
      fg = Colors.amber[800]!;
      label = 'RESCHEDULED';
    } else if (status == 'cancelled') {
      bg = AppColors.errorContainer.withOpacity(0.5);
      fg = AppColors.error;
      label = 'CANCELLED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the Meet link.')),
      );
    }
  }

  void _confirmCancel(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this counseling session? This action will release the slot and notify the candidate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No, Keep It')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<MeetingsBloc>().add(MeetingCancelRequested(id));
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(MeetingModel meeting) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: meeting.startTime.isBefore(DateTime.now()) ? DateTime.now() : meeting.startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(meeting.startTime),
      );

      if (pickedTime != null) {
        final start = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        final end = start.add(const Duration(minutes: 45)); // Default 45 mins session

        if (mounted) {
          context.read<MeetingsBloc>().add(
            MeetingRescheduleRequested(
              meetingId: meeting.id,
              startTime: start,
              endTime: end,
            ),
          );
        }
      }
    }
  }
}
