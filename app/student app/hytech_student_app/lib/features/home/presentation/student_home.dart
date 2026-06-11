import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/case_model.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../appointments/presentation/appointments_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/cases_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/models/meeting_model.dart';
import '../../appointments/bloc/meetings_bloc.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Dispatch CasesLoadRequested when home page loads
    context.read<CasesBloc>().add(CasesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onBookTap: () => setState(() => _currentIndex = 2)),
      const DocumentsScreen(),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('VisaFlow', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.surfaceVariant, height: 2),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.surfaceVariant, width: 2))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Documents'),
            BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: 'Appointments'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onBookTap;
  const _HomeTab({required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String applicantName = 'Rahul';
    String initials = 'AP';
    if (authState is AuthAuthenticated) {
      applicantName = authState.user.fullName.split(' ').first;
      final names = authState.user.fullName.split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        initials = names[0][0].toUpperCase();
      }
    }

    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, state) {
        CaseModel? activeCase;
        if (state is CasesLoaded && state.cases.isNotEmpty) {
          activeCase = state.cases.first;
        } else {
          // Check if CasesBloc already has cases loaded from the active state in bloc
          final currentBlocState = context.read<CasesBloc>().state;
          if (currentBlocState is CasesLoaded && currentBlocState.cases.isNotEmpty) {
            activeCase = currentBlocState.cases.first;
          }
        }

        final readiness = activeCase?.readinessScore ?? 0.0;
        final status = activeCase?.status ?? 'discovery';
        final visaType = activeCase?.visaType ?? 'Student Visa';
        final country = activeCase?.destinationCountry ?? 'UK';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceVariant, width: 2),
                  boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, $applicantName! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                              const SizedBox(height: 4),
                              Text('Track your $country $visaType application.', style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Application Progress', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                              Text('${readiness.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: readiness / 100,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.primary,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text('Current Stage: ${status.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Status chips
              Row(
                children: [
                  _statusChip('✈️ $country $visaType', AppColors.secondary),
                  const SizedBox(width: 8),
                  _statusChip(status.toUpperCase(), AppColors.primary),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.upload_file, label: 'Upload Docs', color: AppColors.primary, onTap: () => onBookTap())), // Taps to appointments screen or documents screen
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.event_available, label: 'Book Meeting', color: AppColors.secondary, onTap: onBookTap)),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.auto_awesome, label: 'AI Check', color: AppColors.tertiary, onTap: () {})),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Upcoming Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              BlocBuilder<MeetingsBloc, MeetingsState>(
                builder: (context, state) {
                  MeetingModel? upcomingMeeting;
                  if (state is MeetingsLoaded && state.meetings.isNotEmpty) {
                    final activeMeetings = state.meetings.where((m) => m.isConfirmed && m.startTime.isAfter(DateTime.now())).toList();
                    if (activeMeetings.isNotEmpty) {
                      upcomingMeeting = activeMeetings.first;
                    }
                  }

                  if (upcomingMeeting == null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.event_note, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('No sessions booked yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface)),
                                    SizedBox(height: 2),
                                    Text('Connect with an advisor for expert visa guidance.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: onBookTap,
                              child: const Text('Book Video Consultation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    );
                  }

                  final dateStr = DateFormat('EEEE, d MMMM').format(upcomingMeeting.startTime);
                  final timeStr = DateFormat('h:mm a').format(upcomingMeeting.startTime);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary, width: 2),
                      boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.videocam, color: AppColors.secondary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(upcomingMeeting.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
                              const Text('Visa Counselor Consultation', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text('$dateStr, $timeStr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (upcomingMeeting.canJoin)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(upcomingMeeting!.meetLink!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant, width: 2),
          boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
