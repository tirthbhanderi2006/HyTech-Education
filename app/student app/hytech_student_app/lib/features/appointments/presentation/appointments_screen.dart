import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/models/user_model.dart';
import '../bloc/meetings_bloc.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _selectedTab = 0; // 0: My Sessions, 1: Book Session

  // Booking states
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedSlot = 0;
  String? _selectedCounselorId;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _slots = ['09:00 AM', '10:30 AM', '01:00 PM', '03:45 PM'];

  // Map slot index to start & end hour/minute
  DateTime _getSlotDateTime(DateTime day, int slotIndex, bool isEnd) {
    int hour = 9;
    int minute = 0;
    
    switch (slotIndex) {
      case 0: // 09:00 AM
        hour = 9; minute = 0;
        break;
      case 1: // 10:30 AM
        hour = 10; minute = 30;
        break;
      case 2: // 01:00 PM
        hour = 13; minute = 0;
        break;
      case 3: // 03:45 PM
        hour = 15; minute = 45;
        break;
    }

    if (isEnd) {
      // Meetings are 45 minutes long
      final start = DateTime(day.year, day.month, day.day, hour, minute);
      return start.add(const Duration(minutes: 45));
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingsBloc, MeetingsState>(
      listener: (context, state) {
        if (state is MeetingBooked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment booked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reset booking form and switch to My Sessions tab
          setState(() {
            _selectedTab = 0;
            _selectedDay = null;
            _selectedSlot = 0;
            _notesController.clear();
          });
        } else if (state is MeetingsError) {
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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header & Custom Tab Toggle ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Counseling Sessions',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Book and join 1-on-1 sessions with expert visa counselors.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Capsule Tab Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _tabButton(
                              label: 'My Sessions',
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                          ),
                          Expanded(
                            child: _tabButton(
                              label: 'Book a Session',
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Contents ───────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<MeetingsBloc, MeetingsState>(
                  builder: (context, state) {
                    if (state is MeetingsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (state is MeetingsLoaded) {
                      return _selectedTab == 0
                          ? _buildMySessionsTab(state.meetings)
                          : _buildBookSessionTab(state.counselors);
                    }

                    // Initial / Error state handler
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.onSurfaceVariant),
                          const SizedBox(height: 16),
                          const Text('Something went wrong or data is missing.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<MeetingsBloc>().add(MeetingsLoadRequested());
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Switcher Button Widget ─────────────────────────────────────────────
  Widget _tabButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: My Sessions View ────────────────────────────────────────────────
  Widget _buildMySessionsTab(List<MeetingModel> meetings) {
    final activeMeetings = meetings.where((m) => !m.isCancelled).toList();

    if (activeMeetings.isEmpty) {
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
                'No Upcoming Sessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'You do not have any visa counseling sessions booked. Book a new session to connect with a consultant.',
                textAlign: Center,
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() => _selectedTab = 1),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Book Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: activeMeetings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final meeting = activeMeetings[index];
        return _meetingCard(meeting);
      },
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
            // Status and Date
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
            
            // Session Info
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
                      const Text(
                        'Visa Counselor Session',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
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

            // Action Buttons
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
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
        content: const Text('Are you sure you want to cancel this counseling session? This will release the time slot and notify the counselor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
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

  // ── Tab 2: Book Session View ───────────────────────────────────────────────
  Widget _buildBookSessionTab(List<UserModel> counselors) {
    if (counselors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: AppColors.onSurfaceVariant),
              SizedBox(height: 12),
              Text('No available counselors to book at the moment.'),
            ],
          ),
        ),
      );
    }

    // Set a default counselor if not yet selected
    if (_selectedCounselorId == null && counselors.isNotEmpty) {
      _selectedCounselorId = counselors.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Calendar Card ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 Weeks',
                CalendarFormat.week: 'Week',
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              enabledDayPredicate: (day) {
                // Disable weekends for business/consultation calls
                return day.weekday != DateTime.saturday && day.weekday != DateTime.sunday;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                disabledTextStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.3)),
                weekendTextStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                defaultTextStyle: const TextStyle(color: AppColors.onSurface),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.surfaceVariant, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 12),
                formatButtonPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.onSurface),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant),
                weekendStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ),
          ),

          // ── Selector Legend ─────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(AppColors.primary, 'Selected'),
              const SizedBox(width: 16),
              _legend(AppColors.primaryContainer.withOpacity(0.3), 'Today'),
              const SizedBox(width: 16),
              _legend(AppColors.surfaceVariant, 'Weekends (Off)'),
            ],
          ),

          // ── Selected Date Info ───────────────────────────────────────
          if (_selectedDay != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
              ),
              child: Row(children: [
                const Icon(Icons.event_available, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Selected: ${_formatDate(_selectedDay!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ]),
            ),
          ],

          // ── Counselor Dropdown ───────────────────────────────────────
          const SizedBox(height: 20),
          const Text('Select Counselor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant, width: 2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCounselorId,
                isExpanded: true,
                items: counselors.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCounselorId = val),
              ),
            ),
          ),

          // ── Time Slots ───────────────────────────────────────────────
          const SizedBox(height: 20),
          const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final selected = i == _selectedSlot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryContainer.withOpacity(0.3)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.surfaceVariant,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _slots[i],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Notes ───────────────────────────────────────────────────
          const SizedBox(height: 20),
          const Text('Notes for Consultant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceVariant, width: 2),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'E.g., I have questions about my bank statement requirements...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),

          // ── Confirm Booking FAB Button ───────────────────────────────
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDay != null ? AppColors.primary : AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _selectedDay != null ? _bookMeeting : null,
              icon: Icon(Icons.check_circle_outline, color: _selectedDay != null ? Colors.white : AppColors.onSurfaceVariant),
              label: Text(
                _selectedDay != null ? 'CONFIRM BOOKING' : 'SELECT A DATE FIRST',
                style: TextStyle(
                  color: _selectedDay != null ? Colors.white : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookMeeting() {
    if (_selectedDay == null || _selectedCounselorId == null) return;
    
    final start = _getSlotDateTime(_selectedDay!, _selectedSlot, false);
    final end = _getSlotDateTime(_selectedDay!, _selectedSlot, true);

    context.read<MeetingsBloc>().add(
      MeetingBookRequested(
        counselorId: _selectedCounselorId!,
        startTime: start,
        endTime: end,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
    ]);
  }

  String _formatDate(DateTime d) {
    return DateFormat('EEEE, d MMMM yyyy').format(d);
  }
}
