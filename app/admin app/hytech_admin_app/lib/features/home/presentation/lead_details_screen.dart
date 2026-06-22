import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hytech_admin_app/core/models/case_model.dart';
import 'package:hytech_admin_app/core/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/checklist_model.dart';
import '../../../core/models/document_model.dart';
import '../../../core/api/cases_api.dart';
import '../bloc/admin_student_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadDetailsScreen extends StatefulWidget {
  final UserModel student;
  const LeadDetailsScreen({super.key, required this.student});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Dispatch LoadLeadDetails when lead profile screen is opened
    context.read<AdminStudentBloc>().add(AdminLoadLeadDetailsRequested(widget.student));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminStudentBloc, AdminStudentState>(
      builder: (context, state) {
        if (state is AdminStudentLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        } else if (state is AdminStudentError) {
          return Scaffold(
            appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
            body: Center(child: Text('Error loading student metrics: ${state.message}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error))),
          );
        } else if (state is! AdminLeadDetailsLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final student = state.student;
        final activeCase = state.activeCase;
        final checklist = state.checklist;
        final eligibility = state.eligibilityReport;
        final risk = state.riskReport;

        final visaType = activeCase?.visaType ?? 'Student Visa';
        final country = activeCase?.destinationCountry ?? 'US';
        final status = activeCase?.status ?? 'Discovery';

        // Circular initials
        final initials = widget.student.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  widget.student.fullName,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: Container(color: AppColors.surfaceVariant, height: 2),
                ),
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
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.student.fullName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.school, color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$country $visaType',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle, color: Color(0xFF87FE45), size: 10),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Status: ${status.toUpperCase()}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Case Selector Dropdown if student has multiple cases
                  if (state.allCases.length > 1) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant, width: 2),
                        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activeCase?.id,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                          items: state.allCases.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text('${c.destinationCountry} - ${c.visaType} (${c.status.toUpperCase()})'),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null && newVal != activeCase?.id) {
                              context.read<AdminStudentBloc>().add(
                                AdminLoadLeadDetailsRequested(student, caseId: newVal),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],

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
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 3)),
                              ),
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                                ),
                              ),
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
                    child: _buildTabContent(student, activeCase, checklist, state.uploadedDocs, eligibility, risk),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(
    UserModel student,
    CaseModel? activeCase,
    List<ChecklistItemModel> checklist,
    List<DocumentModel> uploadedDocs,
    Map<String, dynamic>? eligibility,
    Map<String, dynamic>? risk,
  ) {
    switch (_tabIndex) {
      case 0:
        return _buildOverviewTab(student, activeCase, eligibility, risk);
      case 1:
        return _buildDocumentsTab(activeCase, checklist, uploadedDocs);
      case 2:
        return _buildStaticTimelineTab();
      case 3:
        return _buildStaticCommsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab(
    UserModel student,
    CaseModel? activeCase,
    Map<String, dynamic>? eligibility,
    Map<String, dynamic>? risk,
  ) {
    final double elScore = (eligibility?['overall_score'] as num?)?.toDouble() ?? 85.0;
    final String elCategory = eligibility?['category'] ?? 'High';
    final String explainability = eligibility?['explainability'] ??
        'Strong academic credentials and sufficient financial backing. Minor flag on gap year documentation.';

    final double riskScore = (risk?['risk_score'] as num?)?.toDouble() ?? 12.0;
    final String riskCategory = risk?['risk_category'] ?? 'Low';

    return Column(
      children: [
        // AI Eligibility Score
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tertiary, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.tertiaryContainer, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: AppColors.tertiary),
                  SizedBox(width: 8),
                  Text('AI Eligibility Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.tertiary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(elScore.toStringAsFixed(0), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
                  const Text('%', style: TextStyle(fontSize: 24, color: AppColors.tertiary)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.tertiaryContainer),
                    ),
                    child: Text(
                      '$elCategory Probability',
                      style: const TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(explainability, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: elScore / 100.0,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.tertiary,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Risk Profile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error, width: 2),
            boxShadow: [BoxShadow(color: AppColors.errorContainer.withOpacity(0.2), offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.gpp_maybe, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('AI Visa Rejection Risk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(riskScore.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.error)),
                  const Text('%', style: TextStyle(fontSize: 24, color: AppColors.error)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$riskCategory Risk',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Personal Info
        _infoCard('Candidate Profile Details', Icons.badge_outlined, [
          _InfoRow(label: 'Email Address', value: student.email),
          _InfoRow(label: 'Phone Number', value: student.phone ?? 'N/A'),
          _InfoRow(label: 'Nationality', value: student.nationality ?? 'N/A'),
          _InfoRow(label: 'Education Degree', value: student.educationLevel ?? 'N/A', isLast: true),
        ]),
        const SizedBox(height: 16),

        // Financial Info
        _infoCard('Academic & Financial Info', Icons.payments_outlined, [
          _InfoRow(label: 'Language Score', value: '${langScoresDisplay(student.languageScores)} (Type: ${student.languageScores?['type']?.toString().toUpperCase() ?? 'None'})'),
          _InfoRow(label: 'Sponsor Details', value: student.financialInfo?['sponsor']?.toString() ?? 'Self'),
          _InfoRow(label: 'Available Savings', value: student.financialInfo?['savings']?.toString() != null ? 'INR ${student.financialInfo!['savings']}' : 'N/A'),
          _InfoRow(label: 'Sponsor Monthly Income', value: student.financialInfo?['monthly_income']?.toString() != null ? 'INR ${student.financialInfo!['monthly_income']}' : 'N/A', isLast: true),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  String langScoresDisplay(Map<String, dynamic>? scores) {
    if (scores == null || scores['score'] == null) return 'N/A';
    return scores['score'].toString();
  }

  Widget _buildDocumentsTab(CaseModel? activeCase, List<ChecklistItemModel> checklist, List<DocumentModel> uploadedDocs) {
    if (checklist.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No required documents checklist generated for this lead case.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.outline)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: checklist.length,
        separatorBuilder: (_, __) => const Divider(height: 24, color: AppColors.surfaceVariant),
        itemBuilder: (context, idx) {
          final item = checklist[idx];
          DocumentModel? matchingDoc;
          try {
            matchingDoc = uploadedDocs.firstWhere((d) => d.documentType == item.documentType);
          } catch (_) {
            matchingDoc = null;
          }

          return InkWell(
            onTap: activeCase == null ? null : () => _showStatusDialog(context, activeCase.id, item),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    item.status == 'validated'
                        ? Icons.check_circle
                        : (item.status == 'rejected' ? Icons.cancel : Icons.pending_actions),
                    color: item.status == 'validated'
                        ? Colors.green
                        : (item.status == 'rejected' ? Colors.red : Colors.orange),
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.documentType.toUpperCase().replaceAll('_', ' '),
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.personalizedDescription,
                          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.onSurface),
                        ),
                        if (matchingDoc?.driveViewLink != null) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse(matchingDoc!.driveViewLink!);
                              try {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open file link.')),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'View File on Drive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, size: 16, color: AppColors.outline),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showStatusDialog(BuildContext context, String caseId, ChecklistItemModel item) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update ${item.documentType.toUpperCase().replaceAll('_', ' ')}'),
        content: const Text('Verify or change the validation status for this document checklist item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'rejected'),
            child: const Text('REJECT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'pending'),
            child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'validated'),
            child: const Text('VALIDATE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );

        await CasesApi().updateChecklistItem(caseId, item.id, {'status': result});
        
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          context.read<AdminStudentBloc>().add(AdminLoadLeadDetailsRequested(widget.student));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document status updated to ${result.toUpperCase()}!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildStaticTimelineTab() {
    return Column(
      children: [
        _infoCard('Timeline History', Icons.history, [
          const _InfoRow(label: 'Case Created', value: 'Generated system visa checklist -- 2 hours ago'),
          const _InfoRow(label: 'Student Registered', value: 'Added user profile -- 2 hours ago', isLast: true),
        ]),
      ],
    );
  }

  Widget _buildStaticCommsTab() {
    return Column(
      children: [
        _infoCard('WhatsApp Outreach', Icons.message, [
          const _InfoRow(label: 'Auto Outreach', value: 'WhatsApp onboarding invite successfully transmitted.', isLast: true),
        ]),
      ],
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> rows) {
    return Container(
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
