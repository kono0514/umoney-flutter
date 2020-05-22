import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusCard extends StatefulWidget {
  const BusCard({Key key, this.width}) : super(key: key);

  final double width;

  @override
  _BusCardState createState() => _BusCardState();
}

class _BusCardState extends State<BusCard> {
  String balance = "----";
  String cardNumber = "**** **** **** ****";

  void _resetDefault() {
    setState(() {
      balance = "----";
      cardNumber = "**** **** **** ****";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: (widget.width * 0.628).roundToDouble(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xff0D5590),
            const Color(0xff4484BA),
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(0x80, 0x17, 0x5B, 0x94),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 20,
            top: 20,
            child: Text(
              'ҮЛДЭГДЭЛ',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  color: const Color(0xffF4F4F4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 50,
            child: Text(
              '₮ $balance',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Text(
              '$cardNumber',
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  color: const Color(0xffF4F4F4), 
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.0,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Image(
              width: 38,
              image: AssetImage('assets/images/umoney.png'),
            ),
          ),
        ],
      ),
    );
  }
}
