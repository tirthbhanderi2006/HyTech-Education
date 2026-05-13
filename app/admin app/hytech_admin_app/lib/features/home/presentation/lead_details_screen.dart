import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String name;
  const LeadDetailsScreen({super.key, required this.name});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
            title: Text(widget.name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 20), overflow: TextOverflow.ellipsis),
            actions: [IconButton(icon: const Icon(Icons.edit, color: AppColors.primary), onPressed: () {})],
            bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2)),
          ),
        ],
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Strip
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: Center(child: Text(widget.name.split(' ').map((e) => e[0]).take(2).join(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)))),
                        Positioned(bottom: 0, right: 0, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.flag, size: 14, color: AppColors.onSecondaryContainer))),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                          const Row(children: [Icon(Icons.school, color: Colors.white70, size: 16), SizedBox(width: 4), Text('F1 Student Visa (USA)', style: TextStyle(color: Colors.white70))]),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.circle, color: Color(0xFF87FE45), size: 10), SizedBox(width: 6), Text('Status: Documents Pending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, backgroundColor: Colors.white, side: const BorderSide(color: Colors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () {},
                            icon: const Icon(Icons.update, size: 16),
                            label: const Text('Change Status', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Bar
              Container(
                color: AppColors.surface,
                child: Row(
                  children: ['Overview', 'Documents', 'Timeline', 'Comms'].asMap().entries.map((e) {
                    final active = e.key == _tabIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 3))),
                          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: active ? AppColors.primary : AppColors.onSurfaceVariant)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(color: AppColors.surfaceVariant, height: 2),
              // Tab Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // AI Eligibility Score
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.tertiary, width: 2), boxShadow: const [BoxShadow(color: AppColors.tertiaryContainer, offset: Offset(0, 3))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [Icon(Icons.auto_awesome, color: AppColors.tertiary), SizedBox(width: 8), Text('AI Eligibility Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.tertiary))]),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('85', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
                              const Text('%', style: TextStyle(fontSize: 24, color: AppColors.tertiary)),
                              const SizedBox(width: 12),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.tertiaryFixed.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.tertiaryContainer)), child: const Text('High Probability', style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Strong academic credentials and sufficient financial backing. Minor flag on gap year documentation.', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: 0.85, backgroundColor: AppColors.surfaceVariant, color: AppColors.tertiary, minHeight: 10, borderRadius: BorderRadius.circular(5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Next Action
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Next Action Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.errorContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Row(children: const [Icon(Icons.schedule, size: 12, color: AppColors.error), SizedBox(width: 4), Text('Urgent', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12))])),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surfaceVariant)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Verify Financial Documents', style: TextStyle(fontWeight: FontWeight.bold)), Text('Bank statements uploaded yesterday need manual verification.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))])),
                                const SizedBox(width: 12),
                                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () {}, child: const Text('Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Personal Info
                    _infoCard('Personal Info', Icons.badge_outlined, const [
                      _InfoRow(label: 'Email Address', value: 'ananya.sharma@example.com'),
                      _InfoRow(label: 'Phone Number', value: '+91 98765 43210'),
                      _InfoRow(label: 'Date of Birth', value: '14 Oct 1999 (24 yrs)', isLast: true),
                    ]),
                    const SizedBox(height: 16),
                    _infoCard('Case Details', Icons.work_outline, const [
                      _InfoRow(label: 'Assigned Consultant', value: 'Rahul Kapoor'),
                      _InfoRow(label: 'Applied Date', value: '22 Aug 2023'),
                      _InfoRow(label: 'Target Intake', value: 'Fall 2024', isLast: true),
                    ]),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.outline, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _InfoRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, color: AppColors.onSurface)),
        if (!isLast) ...[const SizedBox(height: 10), const Divider(color: AppColors.surfaceVariant, height: 1), const SizedBox(height: 10)],
      ],
    );
  }
}
