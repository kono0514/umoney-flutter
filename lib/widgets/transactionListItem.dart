import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:umoney_flutter/models/transaction.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    Key key,
    this.transaction,
  }) : super(key: key);

  final Transaction transaction;

  Widget getBalanceTextWidget(BuildContext context) {
    Color color;
    String text;
    if (transaction.type == TransactionType.ENTER_BUS_CHARGE) {
      text = "- ${transaction.amountFormatted}";
      color = Color(0xffFC4545);
    } else if (transaction.type == TransactionType.TOPUP) {
      text = "+ ${transaction.amountFormatted}";
      color = Color(0xff1CCA61);
    } else {
      text = transaction.amountFormatted;
      color = Theme.of(context).textTheme.headline4.color;
    }

    return Text(
      text,
      style: GoogleFonts.montserrat(
        textStyle: TextStyle(
          color: color,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget getIcon() {
    Color backgroundColor;
    String iconName;
    double iconWidth = 24;

    switch (transaction.type) {
      case TransactionType.ENTER_BUS_CHARGE:
        backgroundColor = Color(0xffEBEFFF);
        iconName = "charge.png";
        break;
      case TransactionType.EXIT_BUS:
        backgroundColor = Color(0xffF3F3F3);
        iconName = "getoff.png";
        break;
      case TransactionType.ENTER_BUS_TRANSFER:
        backgroundColor = Color(0xffFAEBFF);
        iconName = "switch.png";
        break;
      case TransactionType.TOPUP:
        backgroundColor = Color(0xffFFF4EB);
        iconName = "topup.png";
        iconWidth = 32;
        break;
      default:
        backgroundColor = Color(0xffE7E7E7);
        iconName = "unknown.png";
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: backgroundColor,
      child: Image(
        width: iconWidth,
        image: AssetImage("assets/images/$iconName"),
      ),
    );
  }

  String getTransactionTypeText() {
    if (transaction.type == TransactionType.ENTER_BUS_CHARGE) {
      return 'Зорчсон';
    } else if (transaction.type == TransactionType.TOPUP) {
      return 'Цэнэглэлт';
    } else if (transaction.type == TransactionType.ENTER_BUS_TRANSFER) {
      return 'Дамжин суусан';
    } else if (transaction.type == TransactionType.EXIT_BUS) {
      return 'Буусан';
    }
    return 'UNKNOWN';
  }

  String getTimestampText() {
    if (transaction.timestamp != null) {
      return DateFormat('HH:mm (y/M/d)').format(transaction.timestamp);
    }
    return 'XX:XX XXXX/XX/XX';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => {},
      contentPadding: EdgeInsets.only(left: 20, right: 20, top: 7, bottom: 7),
      leading: getIcon(),
      title: Text(
        getTransactionTypeText().toUpperCase(),
        style: GoogleFonts.nunito(
          textStyle: TextStyle(
            color: Theme.of(context).textTheme.headline6.color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      subtitle: Text(
        '#${transaction.id} ${getTimestampText()}',
        style: GoogleFonts.nunito(
          textStyle: TextStyle(
            color: Theme.of(context).textTheme.headline2.color,
            fontSize: 13,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          getBalanceTextWidget(context),
          Text(
            transaction.newBalanceFormatted,
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(
                color: Theme.of(context).textTheme.headline3.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
