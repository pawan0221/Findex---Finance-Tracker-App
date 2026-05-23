import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../widgets/findex_ai_logo.dart'; // ← NEW

// ── MESSAGE MODEL ──
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final MessageType type;
  final List<String>? suggestions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.type = MessageType.text,
    this.suggestions,
  });
}

enum MessageType { text, insight, report, suggestion, loading }

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});
  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage>
    with SingleTickerProviderStateMixin {
  final _ctrl        = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping     = false;
  bool _isListening  = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final List<String> _quickSuggestions = [
    '📊 Analyze my spending',
    '💰 How can I save more?',
    '🎯 Set a budget for me',
    '📈 Generate monthly report',
    '⚠️ Where am I overspending?',
    '💡 Investment tips',
    '🏠 Help me save for a house',
    '📱 Reduce my bills',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final income  = TransactionStore.totalIncome;
    final expense = TransactionStore.totalExpense;
    final txCount = TransactionStore.all.length;

    _messages.add(ChatMessage(
      id: '0',
      text: '👋 Hi! I\'m your **AI Financial Assistant**.\n\nI can see you have **$txCount transactions** recorded.\n• Income: ₹${_fmt(income)}\n• Expenses: ₹${_fmt(expense)}\n• Savings: ₹${_fmt(income - expense)}\n\nAsk me anything about your finances!',
      isUser: false,
      time: DateTime.now(),
      type: MessageType.text,
      suggestions: ['Analyze my spending', 'Save more tips', 'Generate report'],
    ));
  }

  String _buildContext() {
    final txs     = TransactionStore.all;
    final income  = TransactionStore.totalIncome;
    final expense = TransactionStore.totalExpense;
    final savings = income - expense;
    final rate    = income > 0 ? (savings / income * 100).toStringAsFixed(1) : '0';

    final cats = <String, double>{};
    for (final t in txs.where((t) => t.isExpense)) {
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    }
    final topCats = (cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5).map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}').join(', ');

    final recentTxs = txs.take(5).map((t) =>
        '${t.isExpense ? '-' : '+'}₹${t.amount} (${t.category}) on ${t.date.day}/${t.date.month}').join(', ');

    return '''
User Financial Data (Indian Rupees):
- Total Income: ₹${income.toStringAsFixed(0)}
- Total Expenses: ₹${expense.toStringAsFixed(0)}  
- Net Savings: ₹${savings.toStringAsFixed(0)}
- Savings Rate: $rate%
- Total Transactions: ${txs.length}
- Top Spending Categories: $topCats
- Recent Transactions: $recentTxs
- Currency: Indian Rupees (₹)
''';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    final loadingId = 'loading_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _messages.add(ChatMessage(
      id: loadingId, text: '', isUser: false,
      time: DateTime.now(), type: MessageType.loading,
    )));
    _scrollToBottom();

    try {
      final context = _buildContext();
      final systemPrompt = '''You are a friendly, expert AI financial advisor for Indian users.
You have access to the user's real financial data below. Use it to give personalized advice.

$context

Guidelines:
- Always use ₹ for Indian Rupees
- Be specific with numbers from their data
- Give actionable, practical advice
- Keep responses concise but helpful (max 200 words)
- Use emojis to make responses friendly
- If asked for a report, structure it clearly with sections
- For budget recommendations, use the 50/30/20 rule as baseline
- Suggest Indian-specific savings like PPF, ELSS, FD, RD when relevant
- Format important numbers in bold using **number**''';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'system': systemPrompt,
          'messages': [
            ..._messages
                .where((m) => m.type != MessageType.loading && m.id != loadingId)
                .toList()
                .reversed
                .take(6)
                .toList()
                .reversed
                .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                }),
            {'role': 'user', 'content': text},
          ],
        }),
      );

      setState(() => _messages.removeWhere((m) => m.id == loadingId));

      if (response.statusCode == 200) {
        final data  = jsonDecode(response.body);
        final reply = data['content'][0]['text'] as String;

        MessageType msgType = MessageType.text;
        List<String>? suggestions;

        if (text.toLowerCase().contains('report') || reply.toLowerCase().contains('report')) {
          msgType = MessageType.report;
        } else if (text.toLowerCase().contains('tip') || text.toLowerCase().contains('advice')) {
          msgType = MessageType.insight;
          suggestions = ['Tell me more', 'What about savings?', 'Show me my spending'];
        } else if (reply.length > 200) {
          suggestions = ['Explain further', 'Give me specific tips', 'What should I do first?'];
        }

        setState(() {
          _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: reply,
            isUser: false,
            time: DateTime.now(),
            type: msgType,
            suggestions: suggestions,
          ));
          _isTyping = false;
        });
      } else {
        _addErrorMessage('API error. Please try again.');
      }
    } catch (e) {
      setState(() => _messages.removeWhere((m) => m.id == loadingId));
      _addFallbackResponse(text);
    }
    _scrollToBottom();
  }

  void _addFallbackResponse(String question) {
    final income  = TransactionStore.totalIncome;
    final expense = TransactionStore.totalExpense;
    final savings = income - expense;
    final rate    = income > 0 ? (savings / income * 100) : 0;

    String reply;
    if (question.toLowerCase().contains('save') || question.toLowerCase().contains('saving')) {
      reply = '💰 **Savings Tips for You:**\n\n'
          'Your current savings rate is **${rate.toStringAsFixed(1)}%**.\n\n'
          '📌 Target: Save at least **20%** of income\n'
          '• You need to save ₹${_fmt(income * 0.2 - savings)} more monthly\n'
          '• Cut top expense category first\n'
          '• Try the 50/30/20 rule:\n'
          '  - 50% needs: ₹${_fmt(income * 0.5)}\n'
          '  - 30% wants: ₹${_fmt(income * 0.3)}\n'
          '  - 20% savings: ₹${_fmt(income * 0.2)}';
    } else if (question.toLowerCase().contains('report')) {
      reply = '📊 **Monthly Financial Report**\n\n'
          '**Income:** ₹${_fmt(income)}\n'
          '**Expenses:** ₹${_fmt(expense)}\n'
          '**Savings:** ₹${_fmt(savings)}\n'
          '**Savings Rate:** ${rate.toStringAsFixed(1)}%\n\n'
          '${rate >= 20 ? '✅ Great savings rate!' : '⚠️ Try to improve savings rate to 20%+'}\n\n'
          '💡 Connect internet for detailed AI analysis.';
    } else {
      reply = '💡 Based on your data:\n\n'
          '• Income: ₹${_fmt(income)}\n'
          '• Expenses: ₹${_fmt(expense)}\n'
          '• Savings: ₹${_fmt(savings)} (${rate.toStringAsFixed(1)}%)\n\n'
          'Connect to internet for personalized AI advice! 🌐';
    }

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: reply,
        isUser: false,
        time: DateTime.now(),
        type: MessageType.insight,
      ));
      _isTyping = false;
    });
  }

  void _addErrorMessage(String msg) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '❌ $msg',
        isUser: false,
        time: DateTime.now(),
      ));
      _isTyping = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() { _messages.clear(); _addWelcomeMessage(); });
  }

  List<TextSpan> _parseBoldText(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        spans.add(TextSpan(text: parts[i], style: base));
      } else {
        spans.add(TextSpan(text: parts[i], style: base.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFBCA9FF))));
      }
    }
    return spans;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── AI AVATAR widget (reused in 3 places) ──
  Widget _aiAvatar({double size = 36}) => FindexAILogo(size: size);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2235),
        elevation: 0,
        title: Row(children: [
          // ✅ HEADER LOGO — animated hexagon
          _aiAvatar(size: 40),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Assistant', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
            Text('Powered by Claude AI', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white38)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(children: [

        // Quick suggestions
        if (_messages.length <= 1)
          Container(
            color: const Color(0xFF1C2235),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Quick Actions', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              ),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickSuggestions.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _sendMessage(_quickSuggestions[i].replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim()),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B6AFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.3)),
                      ),
                      child: Text(_quickSuggestions[i], style: GoogleFonts.poppins(color: const Color(0xFFBCA9FF), fontSize: 12)),
                    ),
                  ),
                ),
              ),
            ]),
          ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _buildMessage(_messages[i]),
          ),
        ),

        // Typing indicator
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(children: [
              // ✅ TYPING INDICATOR LOGO
              _aiAvatar(size: 32),
              const SizedBox(width: 8),
              _TypingIndicator(),
            ]),
          ),

        _buildInputBar(),
      ]),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    if (msg.type == MessageType.loading) return _buildLoadingBubble();

    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                // ✅ CHAT BUBBLE LOGO
                _aiAvatar(size: 32),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied!', style: GoogleFonts.poppins()),
                        backgroundColor: const Color(0xFF8B6AFF),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF8B6AFF)
                          : msg.type == MessageType.report
                              ? const Color(0xFF1E2A47)
                              : msg.type == MessageType.insight
                                  ? const Color(0xFF1A2E1A)
                                  : const Color(0xFF1C2235),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: msg.type == MessageType.report
                          ? Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.3))
                          : msg.type == MessageType.insight
                              ? Border.all(color: Colors.greenAccent.withOpacity(0.2))
                              : null,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (msg.type == MessageType.report) ...[
                        Row(children: [
                          const Icon(Icons.analytics_outlined, color: Color(0xFF8B6AFF), size: 14),
                          const SizedBox(width: 4),
                          Text('Financial Report', style: GoogleFonts.poppins(color: const Color(0xFF8B6AFF), fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 6),
                      ],
                      if (msg.type == MessageType.insight) ...[
                        Row(children: [
                          const Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
                          Text('AI Insight', style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 6),
                      ],
                      RichText(
                        text: TextSpan(
                          children: _parseBoldText(
                            msg.text,
                            GoogleFonts.poppins(
                              color: isUser ? Colors.white : Colors.white70,
                              fontSize: 14, height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(
                          color: isUser ? Colors.white54 : Colors.white24, fontSize: 10),
                      ),
                    ]),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF8B6AFF).withOpacity(0.2),
                  child: const Icon(Icons.person, color: Color(0xFF8B6AFF), size: 16),
                ),
              ],
            ],
          ),

          // Suggestion chips
          if (msg.suggestions != null && !isUser) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: msg.suggestions!.map((s) => GestureDetector(
                  onTap: () => _sendMessage(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B6AFF).withOpacity(0.5)),
                    ),
                    child: Text(s, style: GoogleFonts.poppins(color: const Color(0xFFBCA9FF), fontSize: 12)),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // ✅ LOADING BUBBLE LOGO
        _aiAvatar(size: 32),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1C2235),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
            ),
          ),
          child: _TypingIndicator(),
        ),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2235),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _isListening ? _pulseAnim.value : 1.0,
            child: GestureDetector(
              onTap: () {
                setState(() => _isListening = !_isListening);
                if (_isListening) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎤 Voice input coming soon! Type your question for now.', style: GoogleFonts.poppins()),
                      backgroundColor: const Color(0xFF8B6AFF),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Future.delayed(const Duration(seconds: 2), () => setState(() => _isListening = false));
                }
              },
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.redAccent : const Color(0xFF8B6AFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_isListening ? Icons.mic : Icons.mic_outlined,
                    color: _isListening ? Colors.white : const Color(0xFF8B6AFF), size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            maxLines: 3,
            minLines: 1,
            onSubmitted: _sendMessage,
            decoration: InputDecoration(
              hintText: 'Ask about your finances...',
              hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _sendMessage(_ctrl.text),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF8B6AFF).withOpacity(0.3), blurRadius: 8)],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Animated typing dots ──
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay   = i * 0.2;
        final value   = (_ctrl.value - delay).clamp(0.0, 1.0);
        final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.2, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF8B6AFF).withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      }),
    ),
  );
}