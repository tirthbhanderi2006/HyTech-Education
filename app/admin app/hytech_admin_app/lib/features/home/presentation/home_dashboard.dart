import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'lead_details_screen.dart';
import 'add_student_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
            ),
            const SizedBox(width: 8),
            const Text('VisaFlow', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2)),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _DashboardTab(),
          _LeadsTab(onLeadTap: (name) => Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailsScreen(name: name)))),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen())),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.surfaceVariant, width: 2))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Leads'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// ── DASHBOARD TAB ────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Overview Hero
          _card(
            border: AppColors.surfaceVariant,
            shadow: AppColors.surfaceVariant,
            color: AppColors.primaryContainer.withAlpha(38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Good morning, Admin 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                          const SizedBox(height: 6),
                          const Text("Here's your system overview for today.", style: TextStyle(fontSize: 15, color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
                            child: const Text('15 Active Leads  •  8 Docs Pending', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.onSurface)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // KPI Cards
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _KpiCard(title: 'Pending Verifications', value: '8', icon: Icons.verified_user_outlined, color: AppColors.primary, subtitle: 'Requires review'),
                SizedBox(width: 12),
                _KpiCard(title: 'WhatsApp Sent', value: '142', icon: Icons.message_outlined, color: AppColors.secondary, subtitle: 'Messages today'),
                SizedBox(width: 12),
                _KpiCard(title: 'Revenue (MTD)', value: '₹45K', icon: Icons.payments_outlined, color: Color(0xFFF97316), subtitle: 'Via Razorpay'),
                SizedBox(width: 12),
                _KpiCard(title: 'Appointments', value: '4', icon: Icons.event_outlined, color: AppColors.tertiary, subtitle: 'Today'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Action Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          // Action Card
          _card(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.tertiaryContainer.withAlpha(100), shape: BoxShape.circle), alignment: Alignment.center, child: const Text('AS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary, fontSize: 16))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ananya Sharma', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                          const Text('F1 Student Visa (USA) — Docs Pending', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Color(0xFFFEF08A), borderRadius: BorderRadius.circular(12)), child: const Text('URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF854D0E)))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceVariant)), child: Row(children: const [Icon(Icons.info_outline, size: 16, color: AppColors.onSurfaceVariant), SizedBox(width: 8), Expanded(child: Text('Bank statements uploaded yesterday need manual verification.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)))])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () {}, child: const Text('VERIFY DOCUMENTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))),
                    const SizedBox(width: 12),
                    SizedBox(height: 48, width: 48, child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.surfaceVariant, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero), onPressed: () {}, child: const Icon(Icons.message_outlined, color: AppColors.onSurface))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // AI OCR Pipeline Banner
          _card(
            border: AppColors.tertiary,
            shadow: AppColors.tertiary,
            color: AppColors.tertiaryFixed.withAlpha(76),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [Icon(Icons.auto_awesome, color: AppColors.tertiary), SizedBox(width: 8), Text('AI Document Processing', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.tertiary, fontSize: 16))]),
                const SizedBox(height: 8),
                const Text('OCR Engine extracted data from 5 new passports. Ready to sync with CRM.', style: TextStyle(color: AppColors.onSurface, fontSize: 14)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.tertiary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {},
                  icon: const Icon(Icons.sync, color: Colors.white, size: 18),
                  label: const Text('RUN OCR PIPELINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('System Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
          const SizedBox(height: 12),
          _card(
            child: Column(
              children: const [
                _LogItem(icon: Icons.payment, bg: Color(0xFFDCFCE7), iconColor: Color(0xFF16A34A), title: 'Payment Received', subtitle: '₹5000 via Razorpay – Arjun S.', time: '10 min ago'),
                _LogItem(icon: Icons.message, bg: Color(0xFFE0F2FE), iconColor: Color(0xFF0284C7), title: 'WhatsApp Automation', subtitle: 'Follow-up sent to 12 leads', time: '1 hour ago'),
                _LogItem(icon: Icons.person_add, bg: Color(0xFFD1FAE5), iconColor: AppColors.primary, title: 'New Profile Created', subtitle: 'Priya Mehta — via web intake form', time: '3 hours ago', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── LEADS TAB ────────────────────────────────────────────────────────
class _LeadsTab extends StatelessWidget {
  final Function(String name) onLeadTap;
  const _LeadsTab({required this.onLeadTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
            child: TextField(
              decoration: InputDecoration(hintText: 'Search leads by name, email, visa type...', hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withAlpha(128)), prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              _Chip(label: 'All', active: true), SizedBox(width: 8),
              _Chip(label: 'New'), SizedBox(width: 8),
              _Chip(label: 'In Progress'), SizedBox(width: 8),
              _Chip(label: 'Docs Submitted'), SizedBox(width: 8),
              _Chip(label: 'Approved'), SizedBox(width: 8),
              _Chip(label: 'Rejected'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            children: [
              _LeadCard(initials: 'AK', name: 'Arjun Kapoor', visa: 'US H1B Visa', flag: '🇺🇸', status: 'Approved', color: AppColors.primary, progress: 1.0, updated: '2 hrs ago', onTap: () => onLeadTap('Arjun Kapoor')),
              const SizedBox(height: 12),
              _LeadCard(initials: 'AS', name: 'Ananya Sharma', visa: 'F1 Student Visa (USA)', flag: '🇺🇸', status: 'Docs Pending', color: AppColors.tertiary, progress: 0.6, updated: 'Today', hasMagic: true, onTap: () => onLeadTap('Ananya Sharma')),
              const SizedBox(height: 12),
              _LeadCard(initials: 'PS', name: 'Priya Sharma', visa: 'Canada Express Entry', flag: '🇨🇦', status: 'In Progress', color: Color(0xFFF97316), progress: 0.45, updated: 'Yesterday', onTap: () => onLeadTap('Priya Sharma')),
              const SizedBox(height: 12),
              _LeadCard(initials: 'VS', name: 'Vikram Singh', visa: 'UK Student Visa', flag: '🇬🇧', status: 'Docs Submitted', color: AppColors.secondary, progress: 0.8, updated: '3 days ago', onTap: () => onLeadTap('Vikram Singh')),
            ],
          ),
        ),
      ],
    );
  }
}

// ── SHARED WIDGETS ───────────────────────────────────────────────────
Widget _card({Widget? child, Color color = AppColors.surfaceContainerLowest, Color border = AppColors.surfaceVariant, Color shadow = AppColors.surfaceVariant}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 2), boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))]),
    child: child,
  );
}

class _KpiCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  const _Chip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.primary : AppColors.surfaceVariant, width: 2),
      ),
      child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String initials, name, visa, flag, status, updated;
  final Color color;
  final double progress;
  final bool hasMagic;
  final VoidCallback onTap;
  const _LeadCard({required this.initials, required this.name, required this.visa, required this.flag, required this.status, required this.color, required this.progress, required this.updated, this.hasMagic = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withAlpha(38), shape: BoxShape.circle), alignment: Alignment.center, child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onSurface), overflow: TextOverflow.ellipsis),
                    Row(children: [Text(flag), const SizedBox(width: 4), Expanded(child: Text(visa, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis))]),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9))),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Progress', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress, backgroundColor: AppColors.surfaceVariant, color: color, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant), const SizedBox(width: 4), Text(updated, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant))]),
                Row(children: [if (hasMagic) const Icon(Icons.auto_awesome, color: AppColors.tertiary, size: 16), if (hasMagic) const SizedBox(width: 4), const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant)]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final IconData icon;
  final Color bg, iconColor;
  final String title, subtitle, time;
  final bool isLast;
  const _LogItem({required this.icon, required this.bg, required this.iconColor, required this.title, required this.subtitle, required this.time, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 16, color: iconColor)),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.surfaceVariant, margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
