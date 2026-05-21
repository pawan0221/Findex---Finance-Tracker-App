import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class _ReportData {
  final String income;
  final String expense;
  final String savings;
  final double savingsRate;
  final String savingsDelta;
  final String expenseDelta;
  final String topCategory;
  final List<_BarEntry> weeklyIncome;
  final List<_BarEntry> weeklyExpense;
  final List<_CategorySlice> slices;
  final List<_BudgetItem> budgets;

  const _ReportData({
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingsRate,
    required this.savingsDelta,
    required this.expenseDelta,
    required this.topCategory,
    required this.weeklyIncome,
    required this.weeklyExpense,
    required this.slices,
    required this.budgets,
  });
}

class _BarEntry {
  final String label;
  final double value;
  const _BarEntry(this.label, this.value);
}

class _CategorySlice {
  final String title;
  final double pct;
  final Color color;
  const _CategorySlice(this.title, this.pct, this.color);
}

class _BudgetItem {
  final String label;
  final double spent;
  final double limit;
  final Color color;
  const _BudgetItem(this.label, this.spent, this.limit, this.color);
}

const _purple = Color(0xFF8B6AFF);
const _green  = Color(0xFF00E676);
const _red    = Color(0xFFFF5252);
const _amber  = Color(0xFFFFB300);
const _blue   = Color(0xFF64B5F6);

final Map<String, _ReportData> _allData = {
  'This Month': _ReportData(
    income: '₹1,20,000', expense: '₹44,800', savings: '₹30,000',
    savingsRate: 37, savingsDelta: '↑ 18%', expenseDelta: '↑ 8%', topCategory: 'Food',
    weeklyIncome: const [_BarEntry('W1', 52000), _BarEntry('W2', 68000), _BarEntry('W3', 44000), _BarEntry('W4', 76000)],
    weeklyExpense: const [_BarEntry('W1', 9800), _BarEntry('W2', 14200), _BarEntry('W3', 8400), _BarEntry('W4', 12400)],
    slices: const [_CategorySlice('Food & Dining', 40, _purple), _CategorySlice('Travel', 24, _green), _CategorySlice('Bills', 15, _red), _CategorySlice('Shopping', 11, _amber), _CategorySlice('Others', 10, _blue)],
    budgets: const [_BudgetItem('Food & Dining', 17920, 20000, _purple), _BudgetItem('Travel', 8500, 15000, _green), _BudgetItem('Bills', 6800, 6000, _red), _BudgetItem('Shopping', 4900, 8000, _amber)],
  ),
  '3 Months': _ReportData(
    income: '₹3,40,000', expense: '₹1,29,200', savings: '₹85,000',
    savingsRate: 33, savingsDelta: '↑ 12%', expenseDelta: '↑ 5%', topCategory: 'Bills',
    weeklyIncome: const [_BarEntry('Aug', 1100000), _BarEntry('Sep', 1100000), _BarEntry('Oct', 1200000)],
    weeklyExpense: const [_BarEntry('Aug', 430000), _BarEntry('Sep', 450000), _BarEntry('Oct', 412000)],
    slices: const [_CategorySlice('Bills', 30, _red), _CategorySlice('Travel', 25, _blue), _CategorySlice('Investments', 25, _green), _CategorySlice('Food', 20, _purple)],
    budgets: const [_BudgetItem('Bills', 38760, 36000, _red), _BudgetItem('Travel', 32300, 45000, _blue), _BudgetItem('Investments', 32300, 30000, _green), _BudgetItem('Food', 25840, 30000, _purple)],
  ),
  '6 Months': _ReportData(
    income: '₹6,80,000', expense: '₹2,50,400', savings: '₹1,70,000',
    savingsRate: 35, savingsDelta: '↑ 9%', expenseDelta: '↓ 3%', topCategory: 'Travel',
    weeklyIncome: const [_BarEntry('May', 1050000), _BarEntry('Jun', 1100000), _BarEntry('Jul', 1100000), _BarEntry('Aug', 1100000), _BarEntry('Sep', 1100000), _BarEntry('Oct', 1200000)],
    weeklyExpense: const [_BarEntry('May', 410000), _BarEntry('Jun', 430000), _BarEntry('Jul', 440000), _BarEntry('Aug', 420000), _BarEntry('Sep', 440000), _BarEntry('Oct', 412000)],
    slices: const [_CategorySlice('Travel', 32, _blue), _CategorySlice('Food', 26, _purple), _CategorySlice('Bills', 22, _red), _CategorySlice('Shopping', 20, _amber)],
    budgets: const [_BudgetItem('Travel', 80128, 90000, _blue), _BudgetItem('Food', 65104, 72000, _purple), _BudgetItem('Bills', 55088, 54000, _red), _BudgetItem('Shopping', 50080, 60000, _amber)],
  ),
  'This Year': _ReportData(
    income: '₹14,40,000', expense: '₹5,28,000', savings: '₹3,60,000',
    savingsRate: 38, savingsDelta: '↑ 22%', expenseDelta: '↑ 11%', topCategory: 'Food',
    weeklyIncome: const [_BarEntry('Q1', 3300000), _BarEntry('Q2', 3500000), _BarEntry('Q3', 3600000), _BarEntry('Q4', 4000000)],
    weeklyExpense: const [_BarEntry('Q1', 1220000), _BarEntry('Q2', 1310000), _BarEntry('Q3', 1350000), _BarEntry('Q4', 1400000)],
    slices: const [_CategorySlice('Food', 35, _purple), _CategorySlice('Bills', 28, _red), _CategorySlice('Travel', 20, _blue), _CategorySlice('Shopping', 17, _amber)],
    budgets: const [_BudgetItem('Food', 184800, 200000, _purple), _BudgetItem('Bills', 147840, 160000, _red), _BudgetItem('Travel', 105600, 120000, _blue), _BudgetItem('Shopping', 89760, 80000, _amber)],
  ),
};

// ── PAGE ──
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selected = 'This Month';
  final List<String> _filters = ['This Month', '3 Months', '6 Months', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final data = _allData[_selected]!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Reports & Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined, color: Colors.white70),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export report (demo)'))),
            tooltip: 'Export',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _FilterRow(filters: _filters, selected: _selected, onTap: (f) => setState(() => _selected = f)),
          const SizedBox(height: 16),
          _SummaryRow(data: data),
          const SizedBox(height: 20),
          _SectionTitle('Monthly Cash Flow'),
          const SizedBox(height: 10),
          _BarChartCard(data: data),
          const SizedBox(height: 20),
          _SectionTitle('Spending by Category'),
          const SizedBox(height: 10),
          _DonutCard(data: data),
          const SizedBox(height: 20),
          _SectionTitle('Budget Progress'),
          const SizedBox(height: 10),
          _BudgetCard(data: data),
          const SizedBox(height: 20),
          _SectionTitle('Key Insights'),
          const SizedBox(height: 10),
          _InsightsGrid(data: data),
        ],
      ),
    );
  }
}

// ── FILTER ROW ──
class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onTap;
  const _FilterRow({required this.filters, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = f == selected;
          return GestureDetector(
            onTap: () => onTap(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF8B6AFF).withOpacity(0.22) : const Color(0xFF1C2235),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? const Color(0xFF8B6AFF) : Colors.white.withOpacity(0.12)),
              ),
              child: Text(f, style: GoogleFonts.poppins(fontSize: 13, color: active ? const Color(0xFFBCA9FF) : Colors.white.withOpacity(0.55), fontWeight: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }
}

// ── SUMMARY ROW ──
class _SummaryRow extends StatelessWidget {
  final _ReportData data;
  const _SummaryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip('Income', data.income, const Color(0xFF00E676)),
        const SizedBox(width: 10),
        _StatChip('Expense', data.expense, const Color(0xFFFF5252)),
        const SizedBox(width: 10),
        _StatChip('Savings', data.savings, const Color(0xFFBCA9FF)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── SECTION TITLE ──
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white));
}

// ── BAR CHART CARD ──
class _BarChartCard extends StatelessWidget {
  final _ReportData data;
  const _BarChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final allValues = [...data.weeklyIncome.map((e) => e.value), ...data.weeklyExpense.map((e) => e.value)];
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.2;

    // FIX: use entry.key and entry.value.value (the _BarEntry's double)
    final incomeGroups = data.weeklyIncome.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key * 2,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: const Color(0xFF8B6AFF),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    final expenseGroups = data.weeklyExpense.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key * 2 + 1,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: const Color(0xFFFF5252),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: [...incomeGroups, ...expenseGroups],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white12, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() % 2 != 0) return const SizedBox();
                        final idx = val.toInt() ~/ 2;
                        if (idx >= data.weeklyIncome.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(data.weeklyIncome[idx].label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54)),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(color: const Color(0xFF8B6AFF), label: 'Income'),
              const SizedBox(width: 20),
              _Legend(color: const Color(0xFFFF5252), label: 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

// ── DONUT CARD ──
class _DonutCard extends StatelessWidget {
  final _ReportData data;
  const _DonutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 34,
                sections: data.slices.map((s) => PieChartSectionData(color: s.color, value: s.pct, title: '', radius: 36)).toList(),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.slices.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                    Text('${s.pct.toInt()}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BUDGET CARD ──
class _BudgetCard extends StatelessWidget {
  final _ReportData data;
  const _BudgetCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(16)),
      child: Column(children: data.budgets.map((b) => _BudgetRow(item: b)).toList()),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final _BudgetItem item;
  const _BudgetRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final ratio = (item.spent / item.limit).clamp(0.0, 1.0);
    final overBudget = item.spent > item.limit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
              Row(
                children: [
                  Text('${_fmt(item.spent)} / ${_fmt(item.limit)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: overBudget ? const Color(0xFFFF5252) : item.color)),
                  if (overBudget) ...[const SizedBox(width: 4), const Icon(Icons.warning_rounded, color: Color(0xFFFF5252), size: 14)],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(overBudget ? const Color(0xFFFF5252) : item.color),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ── INSIGHTS GRID ──
class _InsightsGrid extends StatelessWidget {
  final _ReportData data;
  const _InsightsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InsightItem(label: 'Saved this period', value: data.savings,            badge: data.savingsDelta,          positive: data.savingsDelta.startsWith('↑')),
      _InsightItem(label: 'Savings rate',       value: '${data.savingsRate.toInt()}%', badge: '${data.savingsDelta} vs last', positive: data.savingsDelta.startsWith('↑')),
      _InsightItem(label: 'Total spent',        value: data.expense,            badge: data.expenseDelta,          positive: data.expenseDelta.startsWith('↓')),
      _InsightItem(label: 'Top category',       value: data.topCategory,        badge: 'Most spend',               positive: false),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: items.map((item) => _InsightCard(item: item)).toList(),
    );
  }
}

class _InsightItem {
  final String label, value, badge;
  final bool positive;
  const _InsightItem({required this.label, required this.value, required this.badge, required this.positive});
}

class _InsightCard extends StatelessWidget {
  final _InsightItem item;
  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final badgeColor = item.positive ? const Color(0xFF00E676).withOpacity(0.15) : const Color(0xFFFF5252).withOpacity(0.15);
    final textColor  = item.positive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(item.label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
            child: Text(item.badge, style: GoogleFonts.poppins(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
} 