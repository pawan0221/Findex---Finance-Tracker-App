import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});
  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  bool _loading = false;
  List<_InsightCard> _insights = [];
  String? _summary;
  String? _error;
  final _questionCtrl = TextEditingController();
  String? _answer;
  bool _askingQuestion = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  String _buildContext() {
    final txs = TransactionStore.all;
    final income  = txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final expense = txs.where((t) =>  t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final cats    = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    }
    final topCats = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final catStr  = topCats.take(5).map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}').join(', ');
    return 'Total income: ₹${income.toStringAsFixed(0)}, Total expenses: ₹${expense.toStringAsFixed(0)}, '
        'Savings: ₹${(income - expense).toStringAsFixed(0)}, '
        'Savings rate: ${income > 0 ? ((income - expense) / income * 100).toStringAsFixed(1) : 0}%, '
        'Top spending categories: $catStr, '
        'Total transactions: ${txs.length}';
  }

  Future<void> _generateInsights() async {
    setState(() { _loading = true; _error = null; _insights = []; _summary = null; });

    final context = _buildContext();

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': [{
            'role': 'user',
            'content': '''You are a personal finance advisor for an Indian user. 
Analyze this spending data and give exactly 4 short actionable insights.
Data: $context

Respond ONLY with a JSON array (no markdown, no extra text):
[
  {"title": "...", "insight": "...", "type": "warning|tip|positive|alert", "emoji": "..."},
  ...
]
Keep each insight under 20 words. Use ₹ for amounts. Be specific and actionable.'''
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final list = jsonDecode(cleaned) as List;
        setState(() {
          _insights = list.map((i) => _InsightCard(
            title:   i['title'],
            insight: i['insight'],
            type:    i['type'],
            emoji:   i['emoji'],
          )).toList();
          _summary = 'Based on ${TransactionStore.all.length} transactions';
          _loading = false;
        });
      } else {
        _useFallback();
      }
    } catch (e) {
      _useFallback();
    }
  }

  void _useFallback() {
    final txs = TransactionStore.all;
    final income  = txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final expense = txs.where((t) =>  t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final rate    = income > 0 ? (income - expense) / income * 100 : 0;
    final cats    = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    }
    final top = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _insights = [
        _InsightCard(title: 'Savings Rate', insight: 'You\'re saving ${rate.toStringAsFixed(1)}% of income. ${rate >= 20 ? 'Great job!' : 'Aim for 20%+'}', type: rate >= 20 ? 'positive' : 'warning', emoji: '💰'),
        if (top.isNotEmpty) _InsightCard(title: 'Top Spending', insight: '${top[0].key} is your biggest expense at ₹${top[0].value.toStringAsFixed(0)}', type: 'alert', emoji: '📊'),
        _InsightCard(title: 'Balance Check', insight: 'Net balance is ₹${(income - expense).toStringAsFixed(0)} this period', type: income > expense ? 'positive' : 'warning', emoji: income > expense ? '✅' : '⚠️'),
        _InsightCard(title: 'Transactions', insight: 'You have ${txs.length} transactions recorded. Keep tracking!', type: 'tip', emoji: '📝'),
      ];
      _summary = 'Offline analysis • Connect internet for AI insights';
      _loading = false;
    });
  }

  Future<void> _askQuestion() async {
    final q = _questionCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _askingQuestion = true; _answer = null; });

    final context = _buildContext();
    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json', 'anthropic-version': '2023-06-01'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 300,
          'messages': [{
            'role': 'user',
            'content': 'Finance data: $context\n\nQuestion: $q\n\nAnswer in 2-3 sentences, use ₹ for amounts, be specific and helpful.',
          }]
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() { _answer = data['content'][0]['text']; _askingQuestion = false; });
      } else {
        setState(() { _answer = 'Could not get answer. Please try again.'; _askingQuestion = false; });
      }
    } catch (_) {
      setState(() { _answer = 'No internet connection. Please try again.'; _askingQuestion = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: Text('AI Insights', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Your AI Finance Advisor', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Get personalized insights based on your spending', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loading ? null : _generateInsights,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Analyze My Spending', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ),

        if (_summary != null) ...[
          const SizedBox(height: 8),
          Center(child: Text(_summary!, style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11))),
        ],

        if (_insights.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Key Insights', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          ..._insights.map((card) => _InsightCardWidget(card: card)),
        ],

        const SizedBox(height: 24),

        // Ask a question
        Text('Ask a Question', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Ask anything about your finances', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
        const SizedBox(height: 12),

        // Quick questions
        Wrap(spacing: 8, runSpacing: 8, children: [
          'How can I save more?', 'Am I overspending?', 'Where does my money go?', 'How to budget better?',
        ].map((q) => GestureDetector(
          onTap: () { _questionCtrl.text = q; _askQuestion(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.3))),
            child: Text(q, style: GoogleFonts.poppins(color: const Color(0xFFBCA9FF), fontSize: 12)),
          ),
        )).toList()),

        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _questionCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask about your finances...',
                hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                filled: true, fillColor: const Color(0xFF1C2235),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _askingQuestion ? null : _askQuestion,
            child: Container(width: 48, height: 48,
              decoration: BoxDecoration(color: const Color(0xFF8B6AFF), borderRadius: BorderRadius.circular(14)),
              child: _askingQuestion
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22)),
          ),
        ]),

        if (_answer != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2235),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🤖', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('AI Answer', style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(_answer!, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5)),
            ]),
          ),
        ],

        const SizedBox(height: 24),
      ]),
    );
  }
}

class _InsightCard {
  final String title, insight, type, emoji;
  const _InsightCard({required this.title, required this.insight, required this.type, required this.emoji});
}

class _InsightCardWidget extends StatelessWidget {
  final _InsightCard card;
  const _InsightCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'warning':  [const Color(0xFFFFB300), const Color(0xFFFFB300).withOpacity(0.1)],
      'tip':      [const Color(0xFF64B5F6), const Color(0xFF64B5F6).withOpacity(0.1)],
      'positive': [const Color(0xFF00E676), const Color(0xFF00E676).withOpacity(0.1)],
      'alert':    [const Color(0xFFFF5252), const Color(0xFFFF5252).withOpacity(0.1)],
    };
    final c = colors[card.type] ?? colors['tip']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c[1], borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c[0].withOpacity(0.3))),
      child: Row(children: [
        Text(card.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(card.title, style: GoogleFonts.poppins(color: c[0], fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(card.insight, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }
}