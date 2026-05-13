import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payments & Invoices', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)), bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(color: AppColors.surfaceVariant, height: 2))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total Revenue (MTD)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 4),
                Text('₹4,20,000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Row(children: [Icon(Icons.trending_up, color: Color(0xFF87FE45), size: 16), SizedBox(width: 4), Text('+18% from last month', style: TextStyle(color: Color(0xFF87FE45), fontWeight: FontWeight.bold, fontSize: 13))]),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const _PaymentRow(name: 'Arjun Kapoor', amount: '₹15,000', status: 'Paid', date: '13 May 2026', statusColor: AppColors.primary),
            const _PaymentRow(name: 'Priya Sharma', amount: '₹8,500', status: 'Pending', date: '12 May 2026', statusColor: Color(0xFFF97316)),
            const _PaymentRow(name: 'Vikram Singh', amount: '₹12,000', status: 'Paid', date: '11 May 2026', statusColor: AppColors.primary),
            const _PaymentRow(name: 'Ananya Sharma', amount: '₹9,000', status: 'Overdue', date: '8 May 2026', statusColor: AppColors.error),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String name, amount, status, date;
  final Color statusColor;
  const _PaymentRow({required this.name, required this.amount, required this.status, required this.date, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceVariant, width: 2), boxShadow: const [BoxShadow(color: AppColors.surfaceVariant, offset: Offset(0, 2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(date, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.onSurface)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11))),
          ]),
        ],
      ),
    );
  }
}
