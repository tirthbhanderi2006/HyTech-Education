import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final user = state.user;
        final names = user.fullName.split(' ');
        final initials = names.length >= 2
            ? '${names[0][0]}${names[1][0]}'.toUpperCase()
            : (names.isNotEmpty ? names[0][0].toUpperCase() : 'U');

        final langScores = user.languageScores ?? {};
        final langType = langScores['type'] ?? 'None';
        final langVal = langScores['score'] ?? 'N/A';

        final finInfo = user.financialInfo ?? {};
        final monthlyIncome = finInfo['monthly_income']?.toString() ?? 'N/A';
        final savings = finInfo['savings']?.toString() ?? 'N/A';
        final sponsor = finInfo['sponsor'] ?? 'Self';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryContainer, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            user.phone ?? 'No phone added',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _showEditBottomSheet(context, user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Personal & Visa Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              _infoCard([
                _InfoRow(label: 'Nationality', value: user.nationality ?? 'N/A'),
                _InfoRow(label: 'Education Level', value: user.educationLevel ?? 'N/A'),
                _InfoRow(label: 'Passport Expiry', value: user.passportExpiry ?? 'N/A', isLast: true),
              ]),
              const SizedBox(height: 20),

              const Text('Language Proficiency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              _infoCard([
                _InfoRow(label: 'Test Type', value: langType.toString().toUpperCase()),
                _InfoRow(label: 'Overall Score', value: langVal.toString(), isLast: true),
              ]),
              const SizedBox(height: 20),

              const Text('Financial Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              _infoCard([
                _InfoRow(label: 'Total Savings', value: savings.startsWith('INR') || savings == 'N/A' ? savings : 'INR $savings'),
                _InfoRow(label: 'Sponsor Details', value: sponsor.toString()),
                _InfoRow(label: 'Monthly Income', value: monthlyIncome.startsWith('INR') || monthlyIncome == 'N/A' ? monthlyIncome : 'INR $monthlyIncome', isLast: true),
              ]),
              const SizedBox(height: 20),

              const Text('Account Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                  icon: const Icon(Icons.logout),
                  label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: Column(children: rows),
    );
  }

  void _showEditBottomSheet(BuildContext context, UserModel user) {
    final fullNameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone);
    final nationalityCtrl = TextEditingController(text: user.nationality);
    final eduCtrl = TextEditingController(text: user.educationLevel);

    final langTypeCtrl = TextEditingController(text: user.languageScores?['type']);
    final langScoreCtrl = TextEditingController(text: user.languageScores?['score']?.toString());

    final savingsCtrl = TextEditingController(text: user.financialInfo?['savings']?.toString());
    final sponsorCtrl = TextEditingController(text: user.financialInfo?['sponsor']);
    final incomeCtrl = TextEditingController(text: user.financialInfo?['monthly_income']?.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(bottomSheetContext).size.height * 0.75,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile Information',
                    style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),

                  _dialogLabel('Full Name'),
                  _dialogInput(fullNameCtrl, 'Full Name'),

                  _dialogLabel('Phone Number'),
                  _dialogInput(phoneCtrl, 'Phone Number', keyboardType: TextInputType.phone),

                  _dialogLabel('Nationality (ISO 2-letter)'),
                  _dialogInput(nationalityCtrl, 'IN'),

                  _dialogLabel('Education Level'),
                  _dialogInput(eduCtrl, 'e.g. Bachelor of Technology'),

                  const Divider(height: 32),
                  Text('Language Test Scores', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  _dialogLabel('Language Test Type (IELTS/TOEFL/Duolingo)'),
                  _dialogInput(langTypeCtrl, 'IELTS'),

                  _dialogLabel('Overall Score'),
                  _dialogInput(langScoreCtrl, '7.5', keyboardType: TextInputType.number),

                  const Divider(height: 32),
                  Text('Financial Capabilities', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  _dialogLabel('Total Savings (INR)'),
                  _dialogInput(savingsCtrl, '1500000', keyboardType: TextInputType.number),

                  _dialogLabel('Monthly Sponsor Name / Relationship'),
                  _dialogInput(sponsorCtrl, 'Parents'),

                  _dialogLabel('Monthly Sponsor Income (INR)'),
                  _dialogInput(incomeCtrl, '80000', keyboardType: TextInputType.number),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final updates = {
                          'full_name': fullNameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          'nationality': nationalityCtrl.text.trim().isNotEmpty ? nationalityCtrl.text.trim() : null,
                          'education_level': eduCtrl.text.trim().isNotEmpty ? eduCtrl.text.trim() : null,
                          'language_scores': {
                            'type': langTypeCtrl.text.trim().isNotEmpty ? langTypeCtrl.text.trim() : null,
                            'score': langScoreCtrl.text.trim().isNotEmpty
                                ? double.tryParse(langScoreCtrl.text.trim()) ?? langScoreCtrl.text.trim()
                                : null,
                          },
                          'financial_info': {
                            'savings': savingsCtrl.text.trim().isNotEmpty ? savingsCtrl.text.trim() : null,
                            'sponsor': sponsorCtrl.text.trim().isNotEmpty ? sponsorCtrl.text.trim() : 'Self',
                            'monthly_income': incomeCtrl.text.trim().isNotEmpty ? incomeCtrl.text.trim() : null,
                          }
                        };
                        context.read<AuthBloc>().add(AuthProfileUpdateRequested(updates));
                        Navigator.pop(bottomSheetContext);
                      },
                      child: const Text(
                        'SAVE PROFILE CHANGES',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onSurface)),
    );
  }

  Widget _dialogInput(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
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
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 15, color: AppColors.onSurface)),
        if (!isLast) ...[const SizedBox(height: 10), const Divider(color: AppColors.surfaceVariant, height: 1), const SizedBox(height: 10)],
      ],
    );
  }
}
