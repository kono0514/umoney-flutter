import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:umoney_flutter/utils/util.dart';

enum TransactionType {
  UNKNOWN,
  ENTER_BUS_CHARGE,
  ENTER_BUS_TRANSFER,
  EXIT_BUS,
  TOPUP,
}

class Transaction {
  int id;
  TransactionType type;
  int newBalance;
  int amount;
  String terminalId;
  String terminalTransactionNumber;
  DateTime timestamp;

  Transaction(this.id, this.type, this.newBalance, this.amount, this.terminalId,
      this.terminalTransactionNumber, this.timestamp);

  String get newBalanceFormatted =>
      "₮" +
      NumberFormat.simpleCurrency(locale: 'mn', decimalDigits: 0, name: "")
          .format(newBalance)
          .trim();

  String get amountFormatted =>
      "₮" +
      NumberFormat.simpleCurrency(locale: 'mn', decimalDigits: 0, name: "")
          .format(amount)
          .trim();

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) => other is Transaction && other.id == id;

  static Transaction fromByteArray(Uint8List bArr) {
    var typeInt = bArr[0];
    int amount = Util.getIntegerFromByteArray(bArr, 10, 14);

    var datetimeString = Util.getHexStringFromByteArray(bArr, 26, 33);
    DateTime datetime = DateTime.tryParse(
        datetimeString.substring(0, 8) + "T" + datetimeString.substring(8));

    var type;
    if (typeInt == 1) {
      if (amount == 0) {
        // EXIT_BUS or ENTER_BUS_TRANSFER ???
        type = TransactionType.UNKNOWN;
      } else {
        type = TransactionType.ENTER_BUS_CHARGE;
      }
    } else {
      type = TransactionType.TOPUP;
    }

    return Transaction(
      Util.getIntegerFromByteArray(bArr, 6, 10),
      type,
      Util.getIntegerFromByteArray(bArr, 2, 6),
      amount,
      Util.getHexStringFromByteArray(bArr, 14, 22),
      Util.getHexStringFromByteArray(bArr, 22, 26),
      datetime,
    );
  }

  Map toJson() => {
        'id': id,
        'type': type,
        'newBalance': newBalance,
        'amount': amount,
        'terminalId': terminalId,
        'terminalTransactionNumber': terminalTransactionNumber,
        'timestamp': timestamp?.toIso8601String() ?? 'ffffffffffffff',
      };
}
