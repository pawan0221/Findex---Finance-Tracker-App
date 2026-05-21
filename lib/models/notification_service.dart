import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction.dart';

// Only import on non-web platforms
// ignore: avoid_web_libraries_in_flutter
import 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_web.dart';

class NotificationService {
  static Future<void> init() async {
    if (kIsWeb) return; // notifications not supported on web
    await initMobile();
  }

  static Future<void> transactionAdded(Transaction tx) async {
    if (kIsWeb) return;
    await showMobileNotification(
      id: 1,
      title: tx.isExpense ? '💸 Expense Recorded' : '💰 Income Recorded',
      body: '${tx.title}: ₹${tx.amount.toStringAsFixed(0)} in ${tx.category}',
    );
  }

  static Future<void> budgetAlert(String category, double spent, double budget) async {
    if (kIsWeb) return;
    final ratio = spent / budget;
    if (ratio >= 1.0) {
      await showMobileNotification(
        id: 100,
        title: '🚨 Budget Exceeded!',
        body: '$category: spent ₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)}',
      );
    } else if (ratio >= 0.8) {
      await showMobileNotification(
        id: 101,
        title: '⚠️ Budget Warning',
        body: '$category: ${(ratio * 100).toInt()}% of budget used',
      );
    }
  }
}