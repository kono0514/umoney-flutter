import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:umoney_flutter/models/transaction.dart';

class Util {
  static String getHexStringFromByteArray(Uint8List bArr,
      [int start = 0, int end = 0]) {
    if (start == 0 && end == 0) {
      return hex.encode(bArr);
    }
    return hex.encode(bArr.getRange(start, end).toList());
  }

  static int getIntegerFromByteArray(Uint8List bArr, int start, int end) {
    return int.parse(hex.encode(bArr.getRange(start, end).toList()), radix: 16);
  }

  /*
    Calculate unknown TransactionType by looking at the previous transaction(s)
    UNKNOWN = (amount == 0) = (EXIT_BUS? or TRANSFER_BUS?)

    1 Suuh 500 - CHARGE
    2 Buuh 0   - PREV WAS CHARGE OR TRANSFER SO THIS IS EXIT
    3 Suuh 0   - PREV WAS EXIT SO THIS IS TRANSFER
    4 Buuh 0   - PREV WAS CHARGE OR TRANSFER SO THIS IS EXIT
    5 Suuh 500 - CHARGE
    6 Buuh 0   - PREV WAS CHARGE OR TRANSFER SO THIS IS EXIT
  */
  static List<Transaction> assignUnknownTransactiontypes(
      List<Transaction> transactions) {
    List<Transaction> _transactions = List.from(transactions);
    for (var i = transactions.length - 1; i >= 0; i--) {
      Transaction transaction = transactions[i];

      // TransactionType was already known and assigned
      if (transaction.type != TransactionType.UNKNOWN) {
        continue;
      }

      Transaction previousTransaction = transactions
          .getRange(i, transactions.length)
          .firstWhere(
              (element) =>
                  element.type != TransactionType.TOPUP &&
                  element.type != TransactionType.UNKNOWN,
              orElse: () => null);

      if (previousTransaction != null) {
        if (previousTransaction.type == TransactionType.ENTER_BUS_CHARGE ||
            previousTransaction.type == TransactionType.ENTER_BUS_TRANSFER) {
          transaction.type = TransactionType.EXIT_BUS;
        } else if (previousTransaction.type == TransactionType.EXIT_BUS) {
          transaction.type = TransactionType.ENTER_BUS_TRANSFER;
        }
      }
    }
    return _transactions;
  }
}
