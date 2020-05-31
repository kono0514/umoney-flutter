import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ScannerBottomSheet extends StatefulWidget {
  ScannerBottomSheet({Key key}) : super(key: key);

  @override
  ScannerBottomSheetState createState() => ScannerBottomSheetState();
}

class ScannerBottomSheetState extends State<ScannerBottomSheet> {
  String _value = "";
  double _fontSize = 60;
  Color _color = const Color(0xff444444);

  void setBalance(String balance) {
    setState(() {
      _value = NumberFormat.simpleCurrency(locale: 'mn', decimalDigits: 0)
          .format(int.tryParse(balance) ?? 0);
      _fontSize = 60;
      _color = const Color(0xff30ba37);
    });
  }

  void setError(String errorMsg) {
    setState(() {
      _value = errorMsg;
      _fontSize = 20;
      _color = const Color(0xff85292e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 20),
              child: Text(
                "Үлдэгдэл",
                style: TextStyle(
                  color: const Color(0xff404040),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 5),
              height: 6,
              width: 46,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xffe0e0e0),
              ),
            )
          ],
        ),
        Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 40),
          child: _value == ""
              ? CircularProgressIndicator(value: null)
              : Text(
                  _value,
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      color: _color,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        )
      ],
    );
  }
}
