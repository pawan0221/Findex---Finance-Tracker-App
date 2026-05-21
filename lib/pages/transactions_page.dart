import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../models/transaction_service.dart';
import 'add_transaction_sheet.dart';



class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _filter = 'All';
  String _search = '';
  final _filters = ['All', 'Income', 'Expense'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Transactions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B6AFF),
        onPressed: () => showAddTransactionSheet(context, onAdded: () => setState(() {})),
        child: const Icon(Icons.add, size: 28),
      ),
      body: StreamBuilder<List<TransactionWithId>>(
        stream: TransactionService.stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8B6AFF)));
          }

          final all = snapshot.data ?? [];

          // Apply filters
          final filtered = all.where((item) {
            final tx = item.tx;
            final matchFilter = _filter == 'All' ||
                (_filter == 'Income' && !tx.isExpense) ||
                (_filter == 'Expense' && tx.isExpense);
            final matchSearch = _search.isEmpty ||
                tx.title.toLowerCase().contains(_search.toLowerCase()) ||
                tx.category.toLowerCase().contains(_search.toLowerCase());
            return matchFilter && matchSearch;
          }).toList();

          final totalIncome  = all.where((i) => !i.tx.isExpense).fold(0.0, (s, i) => s + i.tx.amount);
          final totalExpense = all.where((i) =>  i.tx.isExpense).fold(0.0, (s, i) => s + i.tx.amount);
          final balance      = totalIncome - totalExpense;

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1C2235),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: _filters.map((f) {
                    final active = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF8B6AFF).withOpacity(0.22) : const Color(0xFF1C2235),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? const Color(0xFF8B6AFF) : Colors.white24),
                          ),
                          child: Text(f, style: GoogleFonts.poppins(
                              color: active ? const Color(0xFFBCA9FF) : Colors.white54,
                              fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Summary
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _MiniStat('Balance', '₹${_fmt(balance)}',      const Color(0xFFBCA9FF)),
                    const SizedBox(width: 10),
                    _MiniStat('In',      '₹${_fmt(totalIncome)}',  const Color(0xFF00E676)),
                    const SizedBox(width: 10),
                    _MiniStat('Out',     '₹${_fmt(totalExpense)}', const Color(0xFFFF5252)),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('No transactions found',
                        style: GoogleFonts.poppins(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return Dismissible(
                            key: Key(item.docId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            ),
                            onDismissed: (_) => TransactionService.delete(item.docId),
                            child: _TxCard(tx: item.tx),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Transaction tx;
  const _TxCard({required this.tx});

  static const _categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Travel':        Icons.flight,
    'Bills':         Icons.receipt_long,
    'Shopping':      Icons.shopping_bag,
    'Health':        Icons.health_and_safety,
    'Leisure':       Icons.movie,
    'Education':     Icons.school,
    'Income':        Icons.account_balance_wallet,
    'Freelance':     Icons.work,
    'Investment':    Icons.trending_up,
    'Gift':          Icons.card_giftcard,
    'Others':        Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final icon     = _categoryIcons[tx.category] ?? Icons.attach_money;
    final color    = tx.isExpense ? const Color(0xFFFF5252) : const Color(0xFF00E676);
    final amountStr = tx.isExpense ? '-₹${tx.amount.toStringAsFixed(0)}' : '+₹${tx.amount.toStringAsFixed(0)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 14)),
                Text('${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(tx.note!, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white24), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(amountStr, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}