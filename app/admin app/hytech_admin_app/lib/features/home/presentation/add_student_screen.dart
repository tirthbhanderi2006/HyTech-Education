import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

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
        title: const Text('VisaFlow', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.surfaceVariant, height: 2),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // Progress Header
                    const Text('Personal Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
                    const SizedBox(height: 8),
                    const Text('STEP 1 OF 3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.outline, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(5)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.33,
                        child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5))),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Form Area
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
                          const _InputLabel(label: 'Full Name (as per passport)'),
                          const _CustomInput(hint: 'e.g. Rahul Sharma', icon: Icons.badge),
                          const SizedBox(height: 16),
                          const _InputLabel(label: 'Phone Number'),
                          const _CustomInput(hint: '+91 98765 43210', icon: Icons.call, keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          const _InputLabel(label: 'Email Address'),
                          const _CustomInput(hint: 'rahul@example.com', icon: Icons.mail, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          const _InputLabel(label: 'Date of Birth'),
                          const _CustomInput(hint: 'YYYY-MM-DD', icon: Icons.calendar_month),
                          const SizedBox(height: 16),
                          const _InputLabel(label: 'Passport Number'),
                          const _CustomInput(hint: 'e.g. Z1234567', icon: Icons.travel_explore),
                          const SizedBox(height: 16),
                          const _InputLabel(label: 'Nationality'),
                          const _CustomDropdown(hint: 'Select Country', icon: Icons.public),
                          const SizedBox(height: 24),
                          // AI Assistant Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4D9FF), // tertiary-fixed
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD99BFF), width: 2), // tertiary-container
                              boxShadow: const [BoxShadow(color: Color(0xFFD99BFF), offset: Offset(0, 3))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle),
                                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('AI Verification Active', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF691B99))),
                                      SizedBox(height: 4),
                                      Text("We'll cross-check this info with your uploaded documents in the next step to catch any typos automatically.", style: TextStyle(fontSize: 14, color: Color(0xFF6A1C9A))),
                                    ],
                                  ),
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
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('SAVE & CONTINUE', style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: AppColors.onPrimary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.surfaceVariant, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Text('SAVE DRAFT', style: TextStyle(color: AppColors.outline, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.onSurface)),
    );
  }
}

class _CustomInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _CustomInput({required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant, width: 2),
        boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 3))],
      ),
      child: TextField(
        keyboardType: keyboardType,
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
}

class _CustomDropdown extends StatelessWidget {
  final String hint;
  final IconData icon;

  const _CustomDropdown({required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
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
                hint: Text(hint, style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.5))),
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: AppColors.outline),
                items: const [], // Placeholder items
                onChanged: (value) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
