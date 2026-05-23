import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show Blob, Url, AnchorElement;
import '../models/transaction.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  String _period = 'This Month';
  bool _exporting = false;
  String? _message;

  final _periods = ['This Month', 'Last Month', '3 Months', '6 Months', 'All Time'];

  List<Transaction> get _filtered {
    final now = DateTime.now();
    final txs = TransactionStore.all;
    return txs.where((t) {
      switch (_period) {
        case 'This Month':  return t.date.month == now.month && t.date.year == now.year;
        case 'Last Month':
          final last = DateTime(now.year, now.month - 1);
          return t.date.month == last.month && t.date.year == last.year;
        case '3 Months':  return t.date.isAfter(now.subtract(const Duration(days: 90)));
        case '6 Months':  return t.date.isAfter(now.subtract(const Duration(days: 180)));
        default: return true;
      }
    }).toList();
  }

  void _exportCSV() {
    setState(() { _exporting = true; _message = null; });
    try {
      final txs = _filtered;
      final income  = txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
      final expense = txs.where((t) =>  t.isExpense).fold(0.0, (s, t) => s + t.amount);

      final buf = StringBuffer();
      // Header
      buf.writeln('FINDEX FINANCIAL REPORT - $_period');
      buf.writeln('Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
      buf.writeln('');
      buf.writeln('SUMMARY');
      buf.writeln('Total Income,₹${income.toStringAsFixed(2)}');
      buf.writeln('Total Expense,₹${expense.toStringAsFixed(2)}');
      buf.writeln('Net Savings,₹${(income - expense).toStringAsFixed(2)}');
      buf.writeln('Savings Rate,${income > 0 ? ((income - expense) / income * 100).toStringAsFixed(1) : 0}%');
      buf.writeln('');
      buf.writeln('TRANSACTIONS');
      buf.writeln('Date,Title,Category,Type,Amount');
      for (final tx in txs) {
        buf.writeln('${tx.date.day}/${tx.date.month}/${tx.date.year},'
            '"${tx.title}","${tx.category}",'
            '${tx.isExpense ? "Expense" : "Income"},'
            '₹${tx.amount.toStringAsFixed(2)}');
      }
      buf.writeln('');
      buf.writeln('CATEGORY BREAKDOWN');
      buf.writeln('Category,Total Spent');
      final cats = <String, double>{};
      for (final t in txs.where((t) => t.isExpense)) {
        cats[t.category] = (cats[t.category] ?? 0) + t.amount;
      }
      final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buf.writeln('"${e.key}",₹${e.value.toStringAsFixed(2)}');
      }

      final bytes  = utf8.encode(buf.toString());
      final blob   = html.Blob([bytes], 'text/csv');
      final url    = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'findex_report_${_period.replaceAll(' ', '_').toLowerCase()}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      setState(() { _message = '✅ CSV exported successfully!'; _exporting = false; });
    } catch (e) {
      setState(() { _message = '❌ Export failed: $e'; _exporting = false; });
    }
  }

  void _exportHTML() {
    setState(() { _exporting = true; _message = null; });
    try {
      final txs     = _filtered;
      final income  = txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
      final expense = txs.where((t) =>  t.isExpense).fold(0.0, (s, t) => s + t.amount);
      final savings = income - expense;
      final cats    = <String, double>{};
      for (final t in txs.where((t) => t.isExpense)) {
        cats[t.category] = (cats[t.category] ?? 0) + t.amount;
      }
      final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      final rows = txs.map((t) => '''
        <tr style="border-bottom:1px solid #eee">
          <td style="padding:8px">${t.date.day}/${t.date.month}/${t.date.year}</td>
          <td style="padding:8px">${t.title}</td>
          <td style="padding:8px">${t.category}</td>
          <td style="padding:8px;color:${t.isExpense ? '#e53935' : '#43a047'};font-weight:600">
            ${t.isExpense ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}
          </td>
        </tr>''').join('');

      final catRows = sorted.map((e) => '''
        <tr>
          <td style="padding:6px 12px">${e.key}</td>
          <td style="padding:6px 12px;font-weight:600">₹${e.value.toStringAsFixed(0)}</td>
          <td style="padding:6px 12px">
            <div style="background:#eee;border-radius:4px;height:8px;width:100%">
              <div style="background:#8B6AFF;border-radius:4px;height:8px;width:${expense > 0 ? (e.value / expense * 100).clamp(0, 100).toStringAsFixed(0) : 0}%"></div>
            </div>
          </td>
        </tr>''').join('');

      final html2 = '''<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>Findex Report - $_period</title>
<style>
  body{font-family:Arial,sans-serif;background:#f5f5f5;margin:0;padding:20px}
  .card{background:white;border-radius:12px;padding:24px;margin-bottom:20px;box-shadow:0 2px 8px rgba(0,0,0,.08)}
  h1{color:#8B6AFF;margin:0} h2{color:#333;font-size:16px}
  .stat{display:inline-block;margin-right:32px;text-align:center}
  .stat .val{font-size:24px;font-weight:bold}
  .stat .lbl{font-size:12px;color:#888}
  table{width:100%;border-collapse:collapse} th{text-align:left;padding:10px;background:#f0f0f0;color:#555}
</style></head>
<body>
<div class="card">
  <h1>💰 Findex Report</h1>
  <p style="color:#888">Period: $_period &nbsp;|&nbsp; Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>
  <div>
    <div class="stat"><div class="val" style="color:#43a047">₹${income.toStringAsFixed(0)}</div><div class="lbl">Income</div></div>
    <div class="stat"><div class="val" style="color:#e53935">₹${expense.toStringAsFixed(0)}</div><div class="lbl">Expense</div></div>
    <div class="stat"><div class="val" style="color:#8B6AFF">₹${savings.toStringAsFixed(0)}</div><div class="lbl">Savings</div></div>
    <div class="stat"><div class="val" style="color:#FB8C00">${income > 0 ? (savings / income * 100).toStringAsFixed(1) : 0}%</div><div class="lbl">Savings Rate</div></div>
  </div>
</div>
<div class="card"><h2>📊 Category Breakdown</h2><table><tr><th>Category</th><th>Amount</th><th>% of Expenses</th></tr>$catRows</table></div>
<div class="card"><h2>📋 Transactions (${txs.length})</h2>
  <table><tr><th>Date</th><th>Title</th><th>Category</th><th>Amount</th></tr>$rows</table></div>
<p style="text-align:center;color:#ccc;font-size:12px">Generated by Findex — Your Personal Finance Tracker</p>
</body></html>''';

      final bytes  = utf8.encode(html2);
      final blob   = html.Blob([bytes], 'text/html');
      final url    = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'findex_report_${_period.replaceAll(' ', '_').toLowerCase()}.html')
        ..click();
      html.Url.revokeObjectUrl(url);

      setState(() { _message = '✅ PDF-ready report exported!'; _exporting = false; });
    } catch (e) {
      setState(() { _message = '❌ Export failed: $e'; _exporting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs     = _filtered;
    final income  = txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final expense = txs.where((t) =>  t.isExpense).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: Text('Export Report', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Period selector
        Text('Select Period', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _periods.map((p) {
          final active = p == _period;
          return GestureDetector(
            onTap: () => setState(() => _period = p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF8B6AFF).withOpacity(0.22) : const Color(0xFF1C2235),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? const Color(0xFF8B6AFF) : Colors.white24),
              ),
              child: Text(p, style: GoogleFonts.poppins(color: active ? const Color(0xFFBCA9FF) : Colors.white54, fontSize: 13)),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),

        // Preview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: [
            Text('Report Preview — $_period', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _StatCol('Income',  '₹${_fmt(income)}',  const Color(0xFF00E676)),
              _StatCol('Expense', '₹${_fmt(expense)}', const Color(0xFFFF5252)),
              _StatCol('Savings', '₹${_fmt(income - expense)}', const Color(0xFFBCA9FF)),
            ]),
            const SizedBox(height: 12),
            Text('${txs.length} transactions', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 24),

        Text('Export Format', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),

        // CSV Export
        _ExportOption(
          icon: Icons.table_chart_outlined,
          title: 'Export as CSV',
          subtitle: 'Open in Excel, Google Sheets',
          color: const Color(0xFF00E676),
          onTap: _exporting ? null : _exportCSV,
        ),
        const SizedBox(height: 10),

        // HTML/PDF Export
        _ExportOption(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Export as Report (HTML)',
          subtitle: 'Open in browser → Print as PDF',
          color: const Color(0xFFFF5252),
          onTap: _exporting ? null : _exportHTML,
        ),

        if (_message != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _message!.startsWith('✅') ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _message!.startsWith('✅') ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
            ),
            child: Text(_message!, style: GoogleFonts.poppins(color: _message!.startsWith('✅') ? Colors.greenAccent : Colors.redAccent, fontSize: 13)),
          ),
        ],

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 How to get PDF', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Text('1. Export as HTML Report\n2. Open the downloaded file in Chrome\n3. Press Ctrl+P → Save as PDF',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, height: 1.6)),
          ]),
        ),
      ]),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCol extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCol(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
  ]);
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _ExportOption({required this.icon, required this.title, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
        ])),
        Icon(Icons.download_rounded, color: color, size: 22),
      ]),
    ),
  );
}