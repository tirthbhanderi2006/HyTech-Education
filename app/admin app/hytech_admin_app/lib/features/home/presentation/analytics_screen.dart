import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/auth_api.dart';

class AnalyticsScreen extends StatefulWidget {
  final int refreshTrigger;
  const AnalyticsScreen({super.key, this.refreshTrigger = 0});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    try {
      final data = await AuthApi().getAdminStats();
      if (mounted) {
        setState(() {
          _stats = data;
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
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load analytics: $_error', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _fetchStats();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final leadsCount = _stats!['leads_count'] ?? 0;
    final pendingDocs = _stats!['pending_docs_count'] ?? 0;
    final appointments = _stats!['appointments_count'] ?? 0;
    final revenue = _stats!['revenue_mtd'] ?? '₹0K';
    
    final countryDist = _stats!['country_distribution'] as Map? ?? {};
    final statusDist = _stats!['status_distribution'] as Map? ?? {};

    // Dynamic bar data
    final List<_BarData> barData = [
      _BarData('Discovery', (statusDist['Discovery'] ?? 0).toDouble(), const Color(0xFFC8E6FF)),
      _BarData('In Progress', (statusDist['In Progress'] ?? 0).toDouble(), const Color(0xFF2FB8FF)),
      _BarData('Docs Sub', (statusDist['Docs Submitted'] ?? 0).toDouble(), const Color(0xFF87FE45)),
      _BarData('Approved', (statusDist['Approved'] ?? 0).toDouble(), AppColors.primaryContainer),
      _BarData('Rejected', (statusDist['Rejected'] ?? 0).toDouble(), AppColors.errorContainer),
    ];

    // Dynamic pie data (only show non-zero countries or a fallback)
    final List<_PieData> pieData = [
      _PieData('USA', (countryDist['US'] ?? 0).toDouble(), AppColors.primaryContainer),
      _PieData('UK', (countryDist['GB'] ?? 0).toDouble(), AppColors.secondaryContainer),
      _PieData('Canada', (countryDist['CA'] ?? 0).toDouble(), AppColors.tertiaryContainer),
      _PieData('Australia', (countryDist['AU'] ?? 0).toDouble(), const Color(0xFF2FB8FF)),
      _PieData('Germany', (countryDist['DE'] ?? 0).toDouble(), const Color(0xFF87FE45)),
    ].where((p) => p.value > 0).toList();

    if (pieData.isEmpty) {
      pieData.add(const _PieData('No Cases', 100.0, AppColors.outline));
    }

    // Calculate dynamic conversion rate
    final approvedCount = statusDist['Approved'] ?? 0;
    final totalCases = barData.fold<double>(0, (sum, b) => sum + b.value);
    final conversion = totalCases > 0 ? (approvedCount / totalCases * 100).toStringAsFixed(1) : '0';

    // Max value for bar chart bounding
    final double maxBarY = barData.fold<double>(10, (max, b) => b.value > max ? b.value : max) + 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                    Text('Visa processing performance overview.', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceVariant, width: 2),
                  boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, size: 15, color: AppColors.outline),
                    const SizedBox(width: 5),
                    Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Icon(Icons.arrow_drop_down, color: AppColors.outline),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── KPI Grid ────────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _KpiCard(label: 'Total Leads', value: '$leadsCount', trend: '+100%', icon: Icons.group, color: AppColors.secondary, trendGood: true),
              _KpiCard(label: 'Conversion', value: '$conversion%', trend: '+5.0%', icon: Icons.check_circle, color: AppColors.primary, trendGood: true),
              _KpiCard(label: 'Appointments', value: '$appointments', trend: 'Active', icon: Icons.event, color: AppColors.error, trendGood: true),
              _KpiCard(label: 'M.T.D. Revenue', value: revenue, trend: 'Dynamic', icon: Icons.payments, color: AppColors.tertiary, trendGood: true),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bar Chart ───────────────────────────────────────────────
          _SectionCard(
            title: 'Leads by Status',
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxBarY,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedBarIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.onSurface.withAlpha(220),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                        '${barData[groupIndex].label}\n${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: (maxBarY / 4).clamp(1, 100).toDouble(),
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i < 0 || i >= barData.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(barData[i].label, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.surfaceVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(barData.length, (i) {
                    final d = barData[i];
                    final isTouched = i == _touchedBarIndex;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: d.value,
                          color: isTouched ? AppColors.primary : d.color,
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxBarY,
                            color: AppColors.surfaceVariant.withAlpha(80),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Pie Chart ───────────────────────────────────────────────
          _SectionCard(
            title: 'Visa Distribution',
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                _touchedPieIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                              });
                            },
                          ),
                          sections: List.generate(pieData.length, (i) {
                            final d = pieData[i];
                            final isTouched = i == _touchedPieIndex;
                            return PieChartSectionData(
                              value: d.value.toDouble(),
                              color: d.color,
                              radius: isTouched ? 38 : 32,
                              title: '${d.value.toInt()}',
                              titleStyle: TextStyle(
                                fontSize: isTouched ? 13 : 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            );
                          }),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$leadsCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                          const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: pieData.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(d.label, style: const TextStyle(fontSize: 13, color: AppColors.onSurface)),
                          ]),
                          Text('${d.value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Top Consultants ─────────────────────────────────────────
          _SectionCard(
            title: 'Top Consultants',
            trailing: const Icon(Icons.emoji_events, color: AppColors.tertiary),
            child: Column(
              children: const [
                _ConsultantRow(rank: 1, name: 'Aisha Patel', cases: '142 Cases Closed', success: '98%', rankColor: AppColors.tertiary),
                Divider(color: AppColors.surfaceVariant, height: 20),
                _ConsultantRow(rank: 2, name: 'Rahul Sharma', cases: '128 Cases Closed', success: '95%'),
                Divider(color: AppColors.surfaceVariant, height: 20),
                _ConsultantRow(rank: 3, name: 'Priya Singh', cases: '115 Cases Closed', success: '92%'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Action Required ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: AppColors.error, width: 4),
                right: BorderSide(color: AppColors.surfaceVariant, width: 2),
                top: BorderSide(color: AppColors.surfaceVariant, width: 2),
                bottom: BorderSide(color: AppColors.surfaceVariant, width: 2),
              ),
              boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_rounded, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Action Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                const SizedBox(height: 12),
                _alertRow('$pendingDocs Overdue Documents', 'Clients waiting for review > 48hrs', 'Review'),
                const SizedBox(height: 8),
                _alertRow('$appointments Active Appointments', 'Appointments currently booked in CRM', 'View'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertRow(String title, String subtitle, String action) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.surfaceVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {},
            child: Text(action, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────
class _BarData {
  final String label;
  final double value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  const _PieData(this.label, this.value, this.color);
}

// ── Shared Widgets ────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  final bool trendGood;
  const _KpiCard({required this.label, required this.value, required this.trend, required this.icon, required this.color, required this.trendGood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: trendGood ? AppColors.primary.withAlpha(20) : AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 11, color: trendGood ? AppColors.primary : AppColors.error),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: trendGood ? AppColors.primary : AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ConsultantRow extends StatelessWidget {
  final int rank;
  final String name, cases, success;
  final Color rankColor;
  const _ConsultantRow({required this.rank, required this.name, required this.cases, required this.success, this.rankColor = AppColors.onSurfaceVariant});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: rankColor.withAlpha(30), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rankColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.onSurface)),
              Text(cases, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Text('$success Success', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
      ],
    );
  }
}
