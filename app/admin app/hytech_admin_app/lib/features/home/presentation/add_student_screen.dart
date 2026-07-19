import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/checklist_model.dart';
import '../bloc/admin_student_bloc.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  int _step = 1;
  bool _isSubmitting = false;

  // Step 1 Controllers
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController(text: 'IN');
  final _passwordCtrl = TextEditingController(text: 'student123'); // Default student password

  // Step 2 Controllers & Selections
  final _purposeCtrl = TextEditingController();
  String _destinationCountry = 'US';
  String _visaType = 'student';

  final List<Map<String, String>> _countries = [
    {'code': 'US', 'name': 'United States'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'DE', 'name': 'Germany'},
  ];

  final List<Map<String, String>> _visaTypes = [
    {'code': 'student', 'name': 'Student Visa'},
    {'code': 'work', 'name': 'Work Visa'},
    {'code': 'tourist', 'name': 'Tourist / Visitor Visa'},
  ];

  List<ChecklistItemModel> _generatedChecklist = [];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalityCtrl.dispose();
    _passwordCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  void _onSaveAndContinue() {
    if (_step == 1) {
      final fullName = _fullNameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in name, email, and password')),
        );
        return;
      }
      context.read<AdminStudentBloc>().add(
            AdminRegisterStudentRequested(
              email: email,
              password: password,
              fullName: fullName,
              phone: _phoneCtrl.text.trim(),
              nationality: _nationalityCtrl.text.trim(),
            ),
          );
    } else if (_step == 2) {
      final purpose = _purposeCtrl.text.trim();
      if (purpose.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter target program/purpose of travel')),
        );
        return;
      }
      context.read<AdminStudentBloc>().add(
            AdminCreateStudentCaseRequested(
              destinationCountry: _destinationCountry,
              visaType: _visaType,
              purpose: purpose,
            ),
          );
    } else if (_step == 3) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Onboard Student',
          style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.surfaceVariant, height: 2),
        ),
      ),
      body: BlocListener<AdminStudentBloc, AdminStudentState>(
        listener: (context, state) {
          if (state is AdminStudentLoading) {
            setState(() => _isSubmitting = true);
          } else if (state is AdminStudentRegistered) {
            setState(() {
              _isSubmitting = false;
              _step = 2;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Student profile registered in database!')),
            );
          } else if (state is AdminStudentCaseCreated) {
            setState(() {
              _isSubmitting = false;
              _generatedChecklist = state.checklist;
              _step = 3;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Visa case created and checklist generated!')),
            );
          } else if (state is AdminStudentError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      // Progress Header
                      Text(
                        _step == 1
                            ? 'Personal Info'
                            : (_step == 2 ? 'Visa Details' : 'Verify Checklist'),
                        style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'STEP $_step OF 3',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(5)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _step / 3.0,
                          child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5))),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_step == 1) _buildStep1Form(),
                      if (_step == 2) _buildStep2Form(),
                      if (_step == 3) _buildStep3Form(),
                    ],
                  ),
                ),
              ),
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.surfaceVariant, width: 2)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _onSaveAndContinue,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _step == 3 ? 'COMPLETE ONBOARDING' : 'SAVE & CONTINUE',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Full Name (as per passport) *'),
          _buildInput(controller: _fullNameCtrl, hint: 'e.g. Rahul Sharma', icon: Icons.badge),
          const SizedBox(height: 16),
          _label('Email Address *'),
          _buildInput(controller: _emailCtrl, hint: 'rahul@example.com', icon: Icons.mail, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label('Temporary Account Password *'),
          _buildInput(controller: _passwordCtrl, hint: 'student123', icon: Icons.lock_outline),
          const SizedBox(height: 16),
          _label('Phone Number'),
          _buildInput(controller: _phoneCtrl, hint: '+91 98765 43210', icon: Icons.call, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _label('Nationality (ISO 2-letter)'),
          _buildInput(controller: _nationalityCtrl, hint: 'IN', icon: Icons.public),
        ],
      ),
    );
  }

  Widget _buildStep2Form() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Destination Country'),
          _buildDropdown(
            value: _destinationCountry,
            items: _countries.map((c) {
              return DropdownMenuItem(
                value: c['code'],
                child: Text(c['name']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _destinationCountry = val!),
            icon: Icons.public,
          ),
          const SizedBox(height: 16),
          _label('Visa Category'),
          _buildDropdown(
            value: _visaType,
            items: _visaTypes.map((v) {
              return DropdownMenuItem(
                value: v['code'],
                child: Text(v['name']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _visaType = val!),
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 16),
          _label('Purpose of Travel'),
          _buildInput(
            controller: _purposeCtrl,
            hint: 'e.g. Master of Business Administration at Oxford University',
            icon: Icons.assignment_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12),
          child: Text(
            'Dynamically Generated Required Documents:',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 4))],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _generatedChecklist.length,
            separatorBuilder: (_, __) => const Divider(height: 24, color: AppColors.surfaceVariant),
            itemBuilder: (context, idx) {
              final item = _generatedChecklist[idx];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.description, color: AppColors.primary, size: 20),
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
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(text, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.onSurface)),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.outline),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: AppColors.outline),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
