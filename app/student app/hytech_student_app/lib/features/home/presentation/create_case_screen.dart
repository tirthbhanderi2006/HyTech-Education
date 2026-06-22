import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/cases_bloc.dart';

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  final _purposeCtrl = TextEditingController();
  String _destinationCountry = 'US';
  String _visaType = 'student';
  DateTime? _travelDate;
  bool _isLoading = false;

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
    {'code': 'family', 'name': 'Family Reunification Visa'},
  ];

  @override
  void dispose() {
    _purposeCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final purpose = _purposeCtrl.text.trim();
    if (purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please state the purpose of your travel')),
      );
      return;
    }

    String? travelDateStr;
    if (_travelDate != null) {
      travelDateStr = DateFormat('yyyy-MM-dd').format(_travelDate!);
    }

    context.read<CasesBloc>().add(
          CaseCreateRequested(
            destinationCountry: _destinationCountry,
            visaType: _visaType,
            purpose: purpose,
            intendedTravelDate: travelDateStr,
          ),
        );
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
          'Start Application',
          style: GoogleFonts.nunito(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<CasesBloc, CasesState>(
        listener: (context, state) {
          if (state is CasesLoading) {
            setState(() => _isLoading = true);
          } else if (state is CaseCreated) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Visa case initialized! Checklist generated.')),
            );
            // Refresh main cases list
            context.read<CasesBloc>().add(CasesLoadRequested());
            Navigator.pop(context);
          } else if (state is CasesError) {
            setState(() => _isLoading = false);
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Steps indicator
                      Text(
                        'Visa Setup Wizard',
                        style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'STEP 1 OF 1',
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1.0,
                          child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Container(
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
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
                            _buildInput(
                              controller: _purposeCtrl,
                              hint: 'e.g. Masters in CS at New York University',
                              icon: Icons.assignment_outlined,
                            ),
                            const SizedBox(height: 16),
                            _label('Intended Travel Date'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickTravelDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.surfaceVariant, width: 2),
                                  boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, color: AppColors.outline),
                                    const SizedBox(width: 12),
                                    Text(
                                      _travelDate == null
                                          ? 'Select Date'
                                          : DateFormat('d MMMM yyyy').format(_travelDate!),
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w600,
                                        color: _travelDate == null
                                            ? AppColors.onSurfaceVariant.withAlpha(120)
                                            : AppColors.onSurface,
                                      ),
                                    ),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.surfaceVariant, width: 2)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _onSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'GENERATE MY VISA CHECKLIST',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTravelDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _travelDate = picked);
    }
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.onSurface),
      );

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
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
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: AppColors.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: AppColors.onSurfaceVariant.withAlpha(120)),
          prefixIcon: Icon(icon, color: AppColors.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
