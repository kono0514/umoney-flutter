import 'package:test/test.dart';
import 'package:umoney_flutter/models/transaction.dart';
import 'package:umoney_flutter/util.dart';

void main() {
  test('Unknown transaction types are assigned correctly', () {
    List<Transaction> _transactions = [
      Transaction(139, TransactionType.UNKNOWN, 1600, 0, null, null, null),
      Transaction(
          138, TransactionType.ENTER_BUS_CHARGE, 1600, 500, null, null, null),
      Transaction(137, TransactionType.UNKNOWN, 2100, 0, null, null, null),
      Transaction(136, TransactionType.UNKNOWN, 2100, 0, null, null, null),
      Transaction(135, TransactionType.TOPUP, 2100, 2000, null, null, null),
      Transaction(134, TransactionType.UNKNOWN, 100, 0, null, null, null),
      Transaction(
          133, TransactionType.ENTER_BUS_CHARGE, 100, 500, null, null, null),
      Transaction(132, TransactionType.UNKNOWN, 600, 0, null, null, null),
      Transaction(
          131, TransactionType.ENTER_BUS_CHARGE, 600, 500, null, null, null),
      Transaction(
          130, TransactionType.ENTER_BUS_CHARGE, 1100, 500, null, null, null),
    ];
    _transactions = Util.assignUnknownTransactiontypes(_transactions);

    List<TransactionType> _expected = [
      TransactionType.EXIT_BUS,
      TransactionType.ENTER_BUS_CHARGE,
      TransactionType.EXIT_BUS,
      TransactionType.ENTER_BUS_TRANSFER,
      TransactionType.TOPUP,
      TransactionType.EXIT_BUS,
      TransactionType.ENTER_BUS_CHARGE,
      TransactionType.EXIT_BUS,
      TransactionType.ENTER_BUS_CHARGE,
      TransactionType.ENTER_BUS_CHARGE,
    ];

    expect(_transactions.map((e) => e.type), _expected);
  });
}
