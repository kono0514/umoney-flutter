import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:umoney_flutter/models/app.dart';
import 'package:umoney_flutter/models/card.dart';
import 'package:umoney_flutter/models/transaction.dart';
import 'package:umoney_flutter/widgets/slideFadeIn.dart';
import 'package:umoney_flutter/widgets/transactionListItem.dart';
import 'package:umoney_flutter/widgets/welcomeNfcInstruction.dart';

class ContentContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, value, child) {
        if (value.showInstructions) {
          return WelcomeNfcInstruction();
        }
        return Selector<CardModel, List<Transaction>>(
            selector: (_, model) => model.transactions,
            builder: (context, transactions, child) {
              if (transactions.length == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 45),
                  child: CircularProgressIndicator(
                    value: null,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Text(
                      "Гүйлгээний түүх",
                      style: GoogleFonts.nunito(
                        textStyle: TextStyle(
                          color: const Color(0xff212131),
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  Expanded(
                    child: SlideFadeIn(
                      duration: const Duration(seconds: 1),
                      child: ListView.separated(
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: const Color(0xffE9E9E9),
                        ),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) => TransactionListItem(
                          transaction: transactions[index],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            });
      },
    );
  }
}
