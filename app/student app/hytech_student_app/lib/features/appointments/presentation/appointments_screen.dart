import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedSlot = 1;
  int _meetingType = 0;

  // Days that have available slots (mock data — swap with API later)
  final Set<DateTime> _availableDays = {
    DateTime.utc(2026, 5, 14),
    DateTime.utc(2026, 5, 15),
    DateTime.utc(2026, 5, 19),
    DateTime.utc(2026, 5, 20),
    DateTime.utc(2026, 5, 22),
    DateTime.utc(2026, 5, 26),
    DateTime.utc(2026, 5, 27),
    DateTime.utc(2026, 5, 28),
  };

  final List<String> _slots = ['09:00 AM', '10:30 AM', '01:00 PM', '03:45 PM'];

  bool _isAvailable(DateTime day) {
    return _availableDays.any((d) => isSameDay(d, day));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          const Text('Book Appointment', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 4),
          const Text('Select an available date and time slot.', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 20),

          // ── Calendar Card ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 120)),
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
                if (!selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              enabledDayPredicate: (day) => !day.isBefore(DateTime.now().subtract(const Duration(days: 1))),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(80),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                disabledTextStyle: TextStyle(color: AppColors.onSurfaceVariant.withAlpha(80)),
                weekendTextStyle: const TextStyle(color: AppColors.onSurface),
                defaultTextStyle: const TextStyle(color: AppColors.onSurface),
                markerDecoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                // Show green dot on available days
                markersMaxCount: 1,
              ),
              eventLoader: (day) {
                return _isAvailable(day) ? ['available'] : [];
              },
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
                decoration: const BoxDecoration(),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant),
                weekendStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              calendarBuilders: CalendarBuilders(
                // Custom marker — green pill for available days
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty && !isSameDay(day, _selectedDay)) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // ── Legend ───────────────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(AppColors.primaryContainer, 'Available'),
              const SizedBox(width: 16),
              _legend(AppColors.primary, 'Selected'),
              const SizedBox(width: 16),
              _legend(AppColors.surfaceVariant, 'Unavailable'),
            ],
          ),

          // ── Selected Day Info ────────────────────────────────────────
          if (_selectedDay != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(60), width: 2),
              ),
              child: Row(children: [
                const Icon(Icons.event_available, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Selected: ${_formatDate(_selectedDay!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                if (!_isAvailable(_selectedDay!)) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: const Text('No slots', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ),
          ],

          // ── Time Slots ───────────────────────────────────────────────
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Time', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
              if (_selectedDay != null && !_isAvailable(_selectedDay!))
                const Text('No available slots', style: TextStyle(fontSize: 12, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final selected = i == _selectedSlot;
                final enabled = _selectedDay == null || _isAvailable(_selectedDay!);
                return GestureDetector(
                  onTap: enabled ? () => setState(() => _selectedSlot = i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: !enabled
                          ? AppColors.surfaceContainerHigh
                          : selected
                              ? AppColors.primaryContainer.withAlpha(60)
                              : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !enabled
                            ? AppColors.surfaceVariant
                            : selected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected && enabled ? AppColors.primary : AppColors.surfaceVariant,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _slots[i],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !enabled
                            ? AppColors.onSurfaceVariant.withAlpha(100)
                            : selected
                                ? AppColors.onPrimaryContainer
                                : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Meeting Type & Notes ─────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceVariant, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meeting Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MeetingTypeButton(icon: Icons.videocam_outlined, label: 'Video Call', selected: _meetingType == 0, onTap: () => setState(() => _meetingType = 0))),
                    const SizedBox(width: 12),
                    Expanded(child: _MeetingTypeButton(icon: Icons.business_outlined, label: 'In-Person', selected: _meetingType == 1, onTap: () => setState(() => _meetingType = 1))),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Notes for Consultant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceVariant, width: 2),
                    boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))],
                  ),
                  child: const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'E.g., I have questions about my bank statement requirements...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Confirm Button ───────────────────────────────────────────
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDay != null ? AppColors.primary : AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _selectedDay != null ? _confirmBooking : null,
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

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          SizedBox(width: 10),
          Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow('Date', _formatDate(_selectedDay!)),
            _dialogRow('Time', _slots[_selectedSlot]),
            _dialogRow('Type', _meetingType == 0 ? 'Video Call' : 'In-Person'),
            _dialogRow('Consultant', 'Rahul Kapoor'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primaryContainer.withAlpha(40), borderRadius: BorderRadius.circular(8)),
              child: const Text('A confirmation will be sent via WhatsApp.', style: TextStyle(fontSize: 12, color: AppColors.onSurface)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
      ]),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = days[(d.weekday - 1) % 7];
    return '$wd, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _MeetingTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MeetingTypeButton({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          // Clearly visible selected tint vs flat white unselected
          color: selected
              ? AppColors.secondaryContainer.withAlpha(120)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.surfaceVariant,
            width: selected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? AppColors.secondary : AppColors.surfaceVariant,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              icon,
              key: ValueKey(selected),
              color: selected ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? AppColors.secondary : AppColors.onSurface,
            ),
          ),
          if (selected) ...[const SizedBox(height: 4), Container(width: 24, height: 3, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)))],
        ]),
      ),
    );
  }
}
