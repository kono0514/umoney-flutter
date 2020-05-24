import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:umoney_flutter/tlv/tlv_util.dart';
import 'package:umoney_flutter/widgets/busCard.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:convert/convert.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _defaultBalance = "₮ ----";
  final String _defaultCardNumber = "**** **** **** ****";

  String _balance;
  String _cardNumber;

  void _resetCard() {
    setState(() {
      _balance = _defaultBalance;
      _cardNumber = _defaultCardNumber;
    });
  }

  void _changeCard(String balance, String cardNumber) {
    setState(() {
      _balance = balance;
      _cardNumber = cardNumber;
    });
  }

  @override
  void initState() {
    super.initState();

    _balance = _defaultBalance;
    _cardNumber = _defaultCardNumber;

    NfcManager.instance.isAvailable().then((value) {
      print('Availalble');
      print(value);
    });

    NfcManager.instance.startTagSession(
      pollingOptions: Set.from([
        TagPollingOption.iso14443,
      ]),
      onDiscovered: (NfcTag tag) async {
        _resetCard();

        // Manipulating tag
        IsoDep isoDep = IsoDep.fromTag(tag);

        var aid = 'd4100000030001';
        var aidBytes = hex.decode(aid);
        var selectFileCommand = Uint8List.fromList([
          0x00,
          0xa4,
          0x04,
          0x00,
          aidBytes.length,
          ...aidBytes,
          0x00,
        ]);

        Uint8List fci = await isoDep.transceive(selectFileCommand);
        var purseInfo = TlvUtil().findBERTLVString(fci, 'b0', false);
        var cardNumber = "";

        if (purseInfo != null) {
          cardNumber = TlvUtil().getHexString(purseInfo, 4, 8);
          cardNumber = cardNumber.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ");
        }

        var balanceCommand = Uint8List.fromList([
          0x90,
          0x4c,
          0x00,
          0x00,
          0x04,
        ]);
        Uint8List balanceRecv = await isoDep.transceive(balanceCommand);
        // balanceRecv[balanceRecv.length - 2] = "status"
        // 0x90 = "STATUS_OK"
        var balanceReal = balanceRecv.take(balanceRecv.length - 2).toList();
        var balance = int.parse(hex.encode(balanceReal), radix: 16);
        var balanceFormatted = NumberFormat.simpleCurrency(locale: 'mn', decimalDigits: 1).format(balance);

        _changeCard(balanceFormatted, cardNumber);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Stack(
        children: <Widget>[
          ClipPath(
            clipper: MyCustomClipper(),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    const Color(0xff0052D4),
                    const Color(0xff4364F7),
                    const Color(0xff6FB1FC),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                SizedBox(height: 30),
                Center(
                  child: BusCard(
                    width: MediaQuery.of(context).size.width - 60,
                    balance: _balance,
                    cardNumber: _cardNumber,
                  ),
                ),
                SizedBox(height: 80),
                Text(
                  'You have pushed the button this many times:',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double height = 200.0;
    double radius = 60.0;
    var path = Path();
    path.lineTo(0.0, height);
    var leftCornerControlPoint = Offset(0, height - radius);
    var leftCornerEndPoint = Offset(radius, height - radius);
    path.quadraticBezierTo(leftCornerControlPoint.dx, leftCornerControlPoint.dy,
        leftCornerEndPoint.dx, leftCornerEndPoint.dy);
    path.lineTo(size.width - radius, height - radius);
    var rightCornerControlPoint = Offset(size.width, height - radius);
    var rightCornerEndPoint = Offset(size.width, height);
    path.quadraticBezierTo(
        rightCornerControlPoint.dx,
        rightCornerControlPoint.dy,
        rightCornerEndPoint.dx,
        rightCornerEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
