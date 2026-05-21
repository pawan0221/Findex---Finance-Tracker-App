class Transaction {
  final String id;
  final String title;
  final double amount;
  final bool isExpense;
  final String category;
  final DateTime date;
  final String? note;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.date,
    this.note,
  });
}

// Shared in-memory store — all pages read/write from here
class TransactionStore {
  static final List<Transaction> _items = [
    Transaction(id: '1', title: 'Salary', amount: 50000, isExpense: false, category: 'Income', date: DateTime.now().subtract(const Duration(days: 1))),
    Transaction(id: '2', title: 'Coffee (Cafe)', amount: 300, isExpense: true, category: 'Food & Dining', date: DateTime.now()),
    Transaction(id: '3', title: 'Electricity Bill', amount: 1200, isExpense: true, category: 'Bills', date: DateTime.now().subtract(const Duration(days: 2))),
    Transaction(id: '4', title: 'Freelance Payment', amount: 8000, isExpense: false, category: 'Income', date: DateTime.now().subtract(const Duration(days: 3))),
    Transaction(id: '5', title: 'Online Shopping', amount: 2500, isExpense: true, category: 'Shopping', date: DateTime.now().subtract(const Duration(days: 4))),
    Transaction(id: '6', title: 'Movie Night', amount: 800, isExpense: true, category: 'Leisure', date: DateTime.now().subtract(const Duration(days: 5))),
    Transaction(id: '7', title: 'Gym Membership', amount: 1800, isExpense: true, category: 'Health', date: DateTime.now().subtract(const Duration(days: 6))),
    Transaction(id: '8', title: 'Bonus', amount: 10000, isExpense: false, category: 'Income', date: DateTime.now().subtract(const Duration(days: 7))),
  ];

  static List<Transaction> get all => List.unmodifiable(_items);

  static void add(Transaction t) => _items.insert(0, t);

  static double get totalIncome => _items.where((t) => !t.isExpense).fold(0, (sum, t) => sum + t.amount);
  static double get totalExpense => _items.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amount);
  static double get balance => totalIncome - totalExpense;
}

const List<String> expenseCategories = [
  'Food & Dining', 'Travel', 'Bills', 'Shopping', 'Health', 'Leisure', 'Education', 'Others',
];

const List<String> incomeCategories = [
  'Income', 'Freelance', 'Investment', 'Gift', 'Others',
];