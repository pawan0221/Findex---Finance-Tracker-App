import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction.dart' as app; // alias to avoid conflict with firebase Transaction

class TransactionService {
  static FirebaseDatabase get _db => FirebaseDatabase.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _ref {
    if (_uid == null) return null;
    return _db.ref('users/$_uid/transactions');
  }

  // Add a transaction
  static Future<void> add(app.Transaction tx) async {
    await _ref?.push().set({
      'id':        tx.id,
      'title':     tx.title,
      'amount':    tx.amount,
      'isExpense': tx.isExpense,
      'category':  tx.category,
      'date':      tx.date.toIso8601String(),
      'note':      tx.note ?? '',
    });
  }

  // Delete a transaction by key
  static Future<void> delete(String key) async {
    await _ref?.child(key).remove();
  }

  // Real-time stream of all transactions
  static Stream<List<TransactionWithId>> stream() {
    if (_ref == null) return const Stream.empty();

    return _ref!.orderByChild('date').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final map = Map<String, dynamic>.from(data as Map);

      final list = map.entries.map((entry) {
        final val = Map<String, dynamic>.from(entry.value as Map);
        return TransactionWithId(
          docId: entry.key,
          tx: app.Transaction(
            id:        val['id'] ?? entry.key,
            title:     val['title'] ?? '',
            amount:    (val['amount'] as num).toDouble(),
            isExpense: val['isExpense'] ?? true,
            category:  val['category'] ?? 'Others',
            date:      DateTime.parse(val['date']),
            note:      val['note']?.toString(),
          ),
        );
      }).toList();

      // Newest first
      list.sort((a, b) => b.tx.date.compareTo(a.tx.date));
      return list;
    });
  }
}

class TransactionWithId {
  final String docId;
  final app.Transaction tx;
  const TransactionWithId({required this.docId, required this.tx});
}