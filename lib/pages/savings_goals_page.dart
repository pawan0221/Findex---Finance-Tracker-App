import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SavingsGoal {
  final String id;
  final String title;
  final String emoji;
  final double target;
  final double saved;
  final DateTime deadline;
  final Color color;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.deadline,
    required this.color,
  });

  double get progress => (saved / target).clamp(0.0, 1.0);
  bool get isCompleted => saved >= target;
  int get daysLeft => deadline.difference(DateTime.now()).inDays;
}

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  List<SavingsGoal> _goals = [];
  bool _loading = true;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  static DatabaseReference? get _ref => _uid == null
      ? null
      : FirebaseDatabase.instance.ref('users/$_uid/goals');

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    _ref?.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        setState(() { _goals = []; _loading = false; });
        return;
      }
      final map = Map<String, dynamic>.from(data as Map);
      setState(() {
        _goals = map.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          return SavingsGoal(
            id:       e.key,
            title:    v['title'] ?? '',
            emoji:    v['emoji'] ?? '🎯',
            target:   (v['target'] as num).toDouble(),
            saved:    (v['saved'] as num).toDouble(),
            deadline: DateTime.parse(v['deadline']),
            color:    Color(int.parse(v['color'] ?? '0xFF8B6AFF')),
          );
        }).toList();
        _loading = false;
      });
    });
  }

  Future<void> _addGoal(SavingsGoal goal) async {
    await _ref?.child(goal.id).set({
      'title':    goal.title,
      'emoji':    goal.emoji,
      'target':   goal.target,
      'saved':    goal.saved,
      'deadline': goal.deadline.toIso8601String(),
      'color':    goal.color.value.toString(),
    });
  }

  Future<void> _addMoney(SavingsGoal goal, double amount) async {
    final newSaved = (goal.saved + amount).clamp(0.0, goal.target);
    await _ref?.child(goal.id).update({'saved': newSaved});
  }

  Future<void> _deleteGoal(String id) async {
    await _ref?.child(id).remove();
  }

  void _showAddGoalSheet() {
    final titleCtrl    = TextEditingController();
    final targetCtrl   = TextEditingController();
    String selectedEmoji = '🎯';
    DateTime deadline    = DateTime.now().add(const Duration(days: 90));
    Color selectedColor  = const Color(0xFF8B6AFF);

    final emojis = ['🎯','🏠','🚗','✈️','📱','💍','🎓','💻','🏖️','🎮','👶','🏋️'];
    final colors = [
      const Color(0xFF8B6AFF), const Color(0xFF00E676),
      const Color(0xFFFF5252), const Color(0xFFFFB300),
      const Color(0xFF64B5F6), const Color(0xFFFF80AB),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1628),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('New Savings Goal', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 20),

                // Emoji picker
                Text('Icon', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: emojis.map((e) => GestureDetector(
                    onTap: () => setSheetState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? const Color(0xFF8B6AFF).withOpacity(0.3) : const Color(0xFF1C2235),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedEmoji == e ? const Color(0xFF8B6AFF) : Colors.transparent),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Title
                Text('Goal Name', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. New iPhone, Vacation...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true, fillColor: const Color(0xFF1C2235),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Target amount
                Text('Target Amount (₹)', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true, fillColor: const Color(0xFF1C2235),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Color
                Text('Color', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: selectedColor == c ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Deadline
                Text('Deadline', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF8B6AFF), surface: Color(0xFF1C2235))),
                        child: child!,
                      ),
                    );
                    if (picked != null) setSheetState(() => deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Text('${deadline.day}/${deadline.month}/${deadline.year}',
                            style: GoogleFonts.poppins(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Save
                GestureDetector(
                  onTap: () {
                    final title  = titleCtrl.text.trim();
                    final target = double.tryParse(targetCtrl.text.trim());
                    if (title.isEmpty || target == null || target <= 0) return;
                    final goal = SavingsGoal(
                      id:       DateTime.now().millisecondsSinceEpoch.toString(),
                      title:    title,
                      emoji:    selectedEmoji,
                      target:   target,
                      saved:    0,
                      deadline: deadline,
                      color:    selectedColor,
                    );
                    _addGoal(goal);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5E5DF0), Color(0xFFFB466B)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text('Create Goal',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMoneyDialog(SavingsGoal goal) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Money to ${goal.title}',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Amount (₹)',
            hintStyle: GoogleFonts.poppins(color: Colors.white38),
            filled: true, fillColor: const Color(0xFF0F1628),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            prefixText: '₹ ',
            prefixStyle: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text.trim());
              if (amt != null && amt > 0) _addMoney(goal, amt);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6AFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Add', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTarget = _goals.fold(0.0, (s, g) => s + g.target);
    final totalSaved  = _goals.fold(0.0, (s, g) => s + g.saved);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Savings Goals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B6AFF),
        onPressed: _showAddGoalSheet,
        child: const Icon(Icons.add, size: 28),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B6AFF)))
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text('No savings goals yet',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tap + to create your first goal',
                          style: GoogleFonts.poppins(color: Colors.white24, fontSize: 13)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Overall progress
                    if (_goals.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Overall Progress', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₹${_fmt(totalSaved)} saved',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('of ₹${_fmt(totalTarget)}',
                                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: totalTarget > 0 ? totalSaved / totalTarget : 0,
                                minHeight: 10,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B6AFF)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${_goals.where((g) => g.isCompleted).length} of ${_goals.length} goals completed',
                                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Goals list
                    ..._goals.map((goal) => Dismissible(
                      key: Key(goal.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                      onDismissed: (_) => _deleteGoal(goal.id),
                      child: GestureDetector(
                        onTap: () => _showAddMoneyDialog(goal),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2235),
                            borderRadius: BorderRadius.circular(18),
                            border: goal.isCompleted
                                ? Border.all(color: const Color(0xFF00E676), width: 1.5)
                                : null,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: goal.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(child: Text(goal.emoji, style: const TextStyle(fontSize: 24))),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(goal.title,
                                                style: GoogleFonts.poppins(color: Colors.white,
                                                    fontWeight: FontWeight.w600, fontSize: 15)),
                                            if (goal.isCompleted) ...[
                                              const SizedBox(width: 6),
                                              const Text('✅', style: TextStyle(fontSize: 14)),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          goal.daysLeft > 0
                                              ? '${goal.daysLeft} days left'
                                              : goal.isCompleted ? 'Goal achieved!' : 'Deadline passed',
                                          style: GoogleFonts.poppins(
                                              color: goal.daysLeft < 7
                                                  ? Colors.redAccent
                                                  : Colors.white38,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${_fmt(goal.saved)}',
                                          style: GoogleFonts.poppins(
                                              color: goal.color,
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('of ₹${_fmt(goal.target)}',
                                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: goal.progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.white.withOpacity(0.08),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            goal.isCompleted ? const Color(0xFF00E676) : goal.color),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('${(goal.progress * 100).toInt()}%',
                                      style: GoogleFonts.poppins(
                                          color: goal.color, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Tap to add money • Swipe left to delete',
                                  style: GoogleFonts.poppins(color: Colors.white12, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}