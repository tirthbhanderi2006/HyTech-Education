import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/cases_api.dart';

class AiAssessmentScreen extends StatefulWidget {
  final String caseId;
  const AiAssessmentScreen({super.key, required this.caseId});

  @override
  State<AiAssessmentScreen> createState() => _AiAssessmentScreenState();
}

class _AiAssessmentScreenState extends State<AiAssessmentScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<List<Map<String, dynamic>>> _assessmentFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final api = CasesApi();
    _assessmentFuture = Future.wait([
      api.runEligibility(widget.caseId),
      api.runRiskAnalysis(widget.caseId),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Copilot Assessment',
          style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15),
                tabs: const [
                  Tab(text: 'Eligibility Check'),
                  Tab(text: 'Rejection Risk'),
                ],
              ),
              Container(color: AppColors.surfaceVariant, height: 2),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _assessmentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary, strokeWidth: 4),
                  SizedBox(height: 16),
                  Text('AI Copilot analyzing case...', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.outline)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error running AI evaluation: ${snapshot.error}',
                  style: GoogleFonts.nunito(color: AppColors.error, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.length < 2) {
            return const Center(child: Text('Failed to load AI data.'));
          }

          final eligibility = snapshot.data![0];
          final risk = snapshot.data![1];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEligibilityTab(eligibility),
              _buildRiskTab(risk),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEligibilityTab(Map<String, dynamic> data) {
    final double score = (data['overall_score'] as num?)?.toDouble() ?? 0.0;
    final String category = data['category'] ?? 'Medium';
    final String explainability = data['explainability'] ?? '';
    final List<dynamic> gapAnalysis = data['gap_analysis'] ?? [];
    final List<dynamic> recommendedActions = data['recommended_actions'] ?? [];

    Color badgeColor = Colors.orange;
    if (category.toLowerCase() == 'high') badgeColor = Colors.green;
    if (category.toLowerCase() == 'low') badgeColor = Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          _card(
            border: badgeColor,
            shadow: badgeColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'OVERALL ELIGIBILITY',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.outline, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: GoogleFonts.nunito(fontSize: 54, fontWeight: FontWeight.w900, color: badgeColor),
                    ),
                    Text('%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: badgeColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$category Probability',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: badgeColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Explainability
          _sectionTitle('AI Assessment Summary'),
          const SizedBox(height: 8),
          _card(
            child: Text(
              explainability,
              style: GoogleFonts.nunito(fontSize: 14, height: 1.5, color: AppColors.onSurface),
            ),
          ),
          const SizedBox(height: 20),

          // Gaps Identified
          if (gapAnalysis.isNotEmpty) ...[
            _sectionTitle('Identified Document/Profile Gaps'),
            const SizedBox(height: 8),
            _card(
              child: Column(
                children: gapAnalysis.map((gap) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            gap.toString(),
                            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Recommended Actions
          if (recommendedActions.isNotEmpty) ...[
            _sectionTitle('Recommended Actions'),
            const SizedBox(height: 8),
            _card(
              child: Column(
                children: recommendedActions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            action.toString(),
                            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskTab(Map<String, dynamic> data) {
    final double riskScore = (data['risk_score'] as num?)?.toDouble() ?? 0.0;
    final String riskCategory = data['risk_category'] ?? 'Low';
    final List<dynamic> topRiskFactors = data['top_risk_factors'] ?? [];
    final List<dynamic> recommendations = data['improvement_recommendations'] ?? [];

    Color riskColor = Colors.green;
    if (riskCategory.toLowerCase() == 'high') riskColor = Colors.red;
    if (riskCategory.toLowerCase() == 'medium') riskColor = Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          _card(
            border: riskColor,
            shadow: riskColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'REJECTION RISK PROFILE',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.outline, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      riskScore.toStringAsFixed(1),
                      style: GoogleFonts.nunito(fontSize: 54, fontWeight: FontWeight.w900, color: riskColor),
                    ),
                    Text('%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: riskColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$riskCategory Risk Level',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: riskColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Risk Factors
          if (topRiskFactors.isNotEmpty) ...[
            _sectionTitle('Key Rejection Contributors'),
            const SizedBox(height: 8),
            _card(
              child: Column(
                children: topRiskFactors.map((factor) {
                  final name = factor['factor'] ?? 'Other';
                  final contribution = (factor['contribution'] as num?)?.toDouble() ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name.toString().replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13)),
                            Text('${contribution.toStringAsFixed(1)}%', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: riskColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: contribution / 100.0,
                          backgroundColor: AppColors.surfaceVariant,
                          color: riskColor,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Improvement Actions
          if (recommendations.isNotEmpty) ...[
            _sectionTitle('Recommended Mitigations'),
            const SizedBox(height: 8),
            _card(
              child: Column(
                children: recommendations.map((rec) {
                  final action = rec['action'] ?? '';
                  final reduction = (rec['estimated_risk_reduction'] as num?)?.toDouble() ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(action, style: GoogleFonts.nunito(fontSize: 14, color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                'Reduces overall risk by estimated ${reduction.toStringAsFixed(1)}%',
                                style: GoogleFonts.nunito(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.onSurface),
      ),
    );
  }

  Widget _card({required Widget child, Color border = AppColors.surfaceVariant, Color shadow = AppColors.surfaceVariant}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}
