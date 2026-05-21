import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  // Default budgets per category
  final Map<String, double> _budgets = {
    'Food & Dining': 10000,
    'Travel': 15000,
    'Bills': 6000,
    'Shopping': 8000,
    'Health': 5000,
    'Leisure': 4000,
    'Education': 5000,
    'Others': 3000,
  };

  // Calculate actual spending per category from TransactionStore
  Map<String, double> get _spent {
    final map = <String, double>{};
    for (final tx in TransactionStore.all) {
      if (tx.isExpense) {
        map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
      }
    }
    return map;
  }

  double get _totalBudget => _budgets.values.fold(0, (a, b) => a + b);
  double get _totalSpent => _spent.values.fold(0, (a, b) => a + b);

  void _editBudget(String category, double current) {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Budget', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.poppins(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0F1628),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) setState(() => _budgets[category] = val);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spent = _spent;
    final overallRatio = _totalBudget > 0 ? (_totalSpent / _totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Budgets', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall budget card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Budget', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${_fmt(_totalSpent)} spent', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('of ₹${_fmt(_totalBudget)}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallRatio,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overallRatio > 0.9 ? const Color(0xFFFF5252) : const Color(0xFF8B6AFF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(overallRatio * 100).toInt()}% of total budget used',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Category Budgets', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),

          // Per-category budget rows
          ..._budgets.entries.map((entry) {
            final category = entry.key;
            final budget = entry.value;
            final spentAmt = spent[category] ?? 0;
            final ratio = (spentAmt / budget).clamp(0.0, 1.0);
            final over = spentAmt > budget;
            final color = over ? const Color(0xFFFF5252) : _categoryColor(category);

            return GestureDetector(
              onTap: () => _editBudget(category, budget),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_categoryIcon(category), color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              Text('₹${_fmt(spentAmt)} of ₹${_fmt(budget)}',
                                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (over)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFFF5252).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: Text('Over!', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFFF5252), fontWeight: FontWeight.w600)),
                              )
                            else
                              Text('₹${_fmt(budget - spentAmt)} left',
                                  style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            const Icon(Icons.edit_outlined, color: Colors.white24, size: 14),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Center(
            child: Text('Tap any category to edit its budget',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static Color _categoryColor(String cat) {
    const map = {
      'Food & Dining': Color(0xFF8B6AFF),
      'Travel': Color(0xFF64B5F6),
      'Bills': Color(0xFFFF5252),
      'Shopping': Color(0xFFFFB300),
      'Health': Color(0xFF00E676),
      'Leisure': Color(0xFFFF80AB),
      'Education': Color(0xFF40C4FF),
      'Others': Color(0xFF90A4AE),
    };
    return map[cat] ?? const Color(0xFF8B6AFF);
  }

  static IconData _categoryIcon(String cat) {
    const map = {
      'Food & Dining': Icons.restaurant,
      'Travel': Icons.flight,
      'Bills': Icons.receipt_long,
      'Shopping': Icons.shopping_bag,
      'Health': Icons.health_and_safety,
      'Leisure': Icons.movie,
      'Education': Icons.school,
      'Others': Icons.more_horiz,
    };
    return map[cat] ?? Icons.category;
  }
}