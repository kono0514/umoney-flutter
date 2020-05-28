import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:umoney_flutter/models/transaction.dart';

class CardModel extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  int _balance = -1;
  String _cardNumber = "*" * 16;

  List<Transaction> get transactions => List.from(_transactions);

  int get balance => _balance;
  String get balanceFormatted => _balance == -1
      ? "₮ ----"
      : NumberFormat.simpleCurrency(locale: 'mn', decimalDigits: 0)
          .format(_balance);
  String get cardNumber => _cardNumber.replaceAllMapped(
      RegExp(r".{4}"), (match) => "${match.group(0)} ");

  set balance(int amount) {
    if (amount != _balance) {
      _balance = amount;
      notifyListeners();
    }
  }

  set cardNumber(String value) {
    if (value != _cardNumber) {
      _cardNumber = value;
      notifyListeners();
    }
  }

  void addTransaction(Transaction item) {
    _transactions.add(item);
    notifyListeners();
  }

  void addTransactions(List<Transaction> items) {
    _transactions.addAll(items);
    notifyListeners();
  }

  void reset() {
    _transactions.clear();
    _balance = -1;
    _cardNumber = "*" * 16;
    notifyListeners();
  }
}
