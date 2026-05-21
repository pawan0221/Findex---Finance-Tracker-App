import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../main.dart';
import '../widgets/app_transitions.dart';
import 'add_transaction_sheet.dart';
import 'transactions_page.dart';
import 'budgets_page.dart';
import 'reports_page.dart';
import 'account_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedFilter = "This Week";
  int _currentNavIndex = 0;

  final Map<String, Map<String, dynamic>> financeData = {
    "This Week": {
      "balance": "₹42,500", "income": "₹20,000", "expenses": "₹7,500", "savings": "₹12,000",
      "chart": [
        {"color": Colors.teal, "value": 50, "title": "Groceries"},
        {"color": Colors.deepPurple, "value": 25, "title": "Bills"},
        {"color": Colors.amber, "value": 25, "title": "Leisure"},
      ],
      "transactions": [
        {"title": "Coffee (Cafe)", "date": "Today", "amount": "-300", "isExpense": true},
        {"title": "Freelance Payment", "date": "Yesterday", "amount": "+8,000", "isExpense": false},
        {"title": "Movie Night", "date": "2 days ago", "amount": "-800", "isExpense": true},
      ]
    },
    "This Month": {
      "balance": "₹75,200", "income": "₹1,20,000", "expenses": "₹44,800", "savings": "₹30,000",
      "chart": [
        {"color": Colors.orange, "value": 40, "title": "Food"},
        {"color": Colors.blue, "value": 30, "title": "Travel"},
        {"color": Colors.purple, "value": 30, "title": "Bills"},
      ],
      "transactions": [
        {"title": "Electricity Bill", "date": "2 Oct", "amount": "-1,200", "isExpense": true},
        {"title": "Salary (Work)", "date": "1 Oct", "amount": "+50,000", "isExpense": false},
        {"title": "Online Shopping", "date": "29 Sep", "amount": "-2,500", "isExpense": true},
      ]
    },
    "Last Month": {
      "balance": "₹64,300", "income": "₹1,10,000", "expenses": "₹45,700", "savings": "₹24,000",
      "chart": [
        {"color": Colors.teal, "value": 35, "title": "Groceries"},
        {"color": Colors.deepPurple, "value": 40, "title": "Bills"},
        {"color": Colors.amber, "value": 25, "title": "Entertainment"},
      ],
      "transactions": [
        {"title": "Gym Membership", "date": "15 Sep", "amount": "-1,800", "isExpense": true},
        {"title": "Bonus (Work)", "date": "10 Sep", "amount": "+10,000", "isExpense": false},
        {"title": "Restaurant", "date": "5 Sep", "amount": "-2,000", "isExpense": true},
      ]
    },
    "Last 3 Months": {
      "balance": "₹2,10,800", "income": "₹3,40,000", "expenses": "₹1,29,200", "savings": "₹85,000",
      "chart": [
        {"color": Colors.pinkAccent, "value": 30, "title": "Bills"},
        {"color": Colors.lightBlueAccent, "value": 25, "title": "Travel"},
        {"color": Colors.greenAccent, "value": 45, "title": "Investments"},
      ],
      "transactions": [
        {"title": "Stock Purchase", "date": "10 Aug", "amount": "-15,000", "isExpense": true},
        {"title": "Freelance Project", "date": "5 Aug", "amount": "+25,000", "isExpense": false},
        {"title": "Vacation", "date": "20 Jul", "amount": "-8,000", "isExpense": true},
      ]
    },
  };

  @override
  Widget build(BuildContext context) {
    final data = financeData[selectedFilter]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1628),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, SlidePageRoute(page: const AccountPage())),
                        child: const CircleAvatar(radius: 20, backgroundColor: Color(0xFF8B6AFF), child: Icon(Icons.person, color: Colors.white, size: 22)),
                      ),
                      const SizedBox(width: 10),
                      Text("Welcome Back, ${FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'User'}!", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                  Row(children: [
                    const Icon(Icons.notifications_none, color: Colors.white70),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => themeNotifier.value =
                          themeNotifier.value == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                      child: ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (_, mode, __) => Icon(
                          mode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 25),

              // FILTER BUTTONS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterButton(title: "This Week",     isActive: selectedFilter == "This Week",     onTap: () => setState(() => selectedFilter = "This Week")),
                    const SizedBox(width: 10),
                    FilterButton(title: "This Month",    isActive: selectedFilter == "This Month",    onTap: () => setState(() => selectedFilter = "This Month")),
                    const SizedBox(width: 10),
                    FilterButton(title: "Last Month",    isActive: selectedFilter == "Last Month",    onTap: () => setState(() => selectedFilter = "Last Month")),
                    const SizedBox(width: 10),
                    FilterButton(title: "Last 3 Months", isActive: selectedFilter == "Last 3 Months", onTap: () => setState(() => selectedFilter = "Last 3 Months")),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // FINANCIAL OVERVIEW CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF1E2A47), Color(0xFF4B3C93)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Financial Overview", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(data["balance"], style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Total Balance", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statItem("Income", data["income"], Colors.greenAccent),
                        _statItem("Expenses", data["expenses"], Colors.redAccent),
                        _statItem("Savings", data["savings"], Colors.cyanAccent),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // PIE CHART
              Text("Visual Insights", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1C2235), borderRadius: BorderRadius.circular(20)),
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        for (var item in data["chart"])
                          PieChartSectionData(
                            color: item["color"],
                            value: item["value"].toDouble(),
                            title: item["title"],
                            radius: 45,
                            titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // RECENT TRANSACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Transactions", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, SlidePageRoute(page: const TransactionsPage())),
                    child: Text("See All", style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF8B6AFF), fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              for (var tx in data["transactions"])
                TransactionTile(title: tx["title"], date: tx["date"], amount: tx["amount"], isExpense: tx["isExpense"]),
            ],
          ),
        ),
      ),

      // BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1C2235),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavIcon(icon: Icons.dashboard,        label: "Overview",     isActive: _currentNavIndex == 0, onTap: () => setState(() => _currentNavIndex = 0)),
            BottomNavIcon(icon: Icons.swap_horiz,       label: "Transactions", isActive: _currentNavIndex == 1, onTap: () {
              setState(() => _currentNavIndex = 1);
              Navigator.push(context, SlidePageRoute(page: const TransactionsPage()));
            }),
            const SizedBox(width: 48),
            BottomNavIcon(icon: Icons.pie_chart_outline, label: "Budgets",    isActive: _currentNavIndex == 2, onTap: () {
              setState(() => _currentNavIndex = 2);
              Navigator.push(context, SlidePageRoute(page: const BudgetsPage()));
            }),
            BottomNavIcon(icon: Icons.bar_chart_outlined, label: "Reports",   isActive: _currentNavIndex == 3, onTap: () {
              setState(() => _currentNavIndex = 3);
              Navigator.push(context, SlidePageRoute(page: const ReportsPage()));
            }),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B6AFF),
        onPressed: () => showAddTransactionSheet(context, onAdded: () => setState(() {})),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _statItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

// ── FILTER BUTTON ──
class FilterButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  const FilterButton({required this.title, required this.isActive, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B6AFF).withOpacity(0.25) : const Color(0xFF1C2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF8B6AFF) : Colors.white24),
        ),
        child: Text(title, style: GoogleFonts.poppins(color: isActive ? const Color(0xFFBCA9FF) : Colors.white70, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ── TRANSACTION TILE ──
class TransactionTile extends StatelessWidget {
  final String title, date, amount;
  final bool isExpense;
  const TransactionTile({required this.title, required this.date, required this.amount, required this.isExpense, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isExpense ? Colors.redAccent : Colors.greenAccent),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.white)),
      subtitle: Text(date, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
      trailing: Text(amount, style: GoogleFonts.poppins(color: isExpense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.w600)),
    );
  }
}

// ── BOTTOM NAV ICON ──
class BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const BottomNavIcon({required this.icon, required this.label, required this.isActive, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF8B6AFF) : Colors.white70),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, color: isActive ? const Color(0xFF8B6AFF) : Colors.white60)),
          ],
        ),
      ),
    );
  }
}