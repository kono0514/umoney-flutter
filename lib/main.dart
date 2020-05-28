import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:provider/provider.dart';
import 'package:umoney_flutter/contentContainer.dart';
import 'package:umoney_flutter/models/app.dart';
import 'package:umoney_flutter/models/card.dart';
import 'package:umoney_flutter/models/transaction.dart';
import 'package:umoney_flutter/tlv/tlv_util.dart';
import 'package:umoney_flutter/util.dart';
import 'package:umoney_flutter/widgets/busCard.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:convert/convert.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CardModel()),
          ChangeNotifierProvider(create: (context) => AppModel()),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _errorScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    NfcManager.instance.startTagSession(
      pollingOptions: Set.from([
        TagPollingOption.iso14443,
      ]),
      onDiscovered: (NfcTag tag) async {
        var cardModel = Provider.of<CardModel>(context, listen: false);
        var appModel = Provider.of<AppModel>(context, listen: false);

        appModel.showInstructions = false;
        cardModel.reset();

        IsoDep isoDep = IsoDep.fromTag(tag);

        if (isoDep == null) {
          // Cardiin format tohirsongui
          print('Wrong card');
          _errorScaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text('Картын формат тохирсонгүй...'),
              duration: const Duration(seconds: 5),
            ),
          );
          appModel.showInstructions = true;
          return;
        }

        // TMoney, UMoney specific AID
        var aid = 'd4100000030001';
        var aidBytes = hex.decode(aid);
        // Prepare select command
        var selectFileCommand = Uint8List.fromList([
          0x00,
          0xa4,
          0x04,
          0x00,
          aidBytes.length,
          ...aidBytes,
          0x00,
        ]);
        // Prepare get balance command
        var balanceCommand = Uint8List.fromList([
          0x90,
          0x4c,
          0x00,
          0x00,
          0x04,
        ]);

        Uint8List fci, balanceRecv;
        try {
          // Selecting AID returns FCI (6f) with purseInfo on 'b0' tag
          fci = await isoDep.transceive(selectFileCommand);
          balanceRecv = await isoDep.transceive(balanceCommand);
        } catch (ex) {
          print('Card moved too fast');
          print(ex);
          _errorScaffoldKey.currentState.showSnackBar(
            SnackBar(
              content: Text(
                  'Карт уншигдсангүй... Уншуулахдаа бага зэрэг удаан бариарай'),
              duration: const Duration(seconds: 5),
            ),
          );
          appModel.showInstructions = true;
          // Card moved too fast?
          return;
        }
        // TODO: verify its umoney card from the FCI first.

        var balance = Util.getIntegerFromByteArray(
            balanceRecv, 0, balanceRecv.length - 2);

        // Extract the card number from the Purse info.
        Uint8List purseInfo = TlvUtil().findBERTLVString(fci, 'b0', false);
        var cardNumber = purseInfo == null
            ? ""
            : Util.getHexStringFromByteArray(purseInfo, 4, 12);

        // Get last 20 transactions (stored in order from newest (0 index) -> oldest)
        List<Transaction> transactionRecords = [];
        for (var i = 1; i <= 20; i++) {
          var transactionRecordCommand = Uint8List.fromList([
            0x00,
            0xB2,
            i,
            0x24,
            0x2e,
          ]);

          Uint8List response;
          try {
            response = await isoDep.transceive(transactionRecordCommand);
          } catch (e) {
            _errorScaffoldKey.currentState.showSnackBar(
              SnackBar(
                content: Text(
                    'Карт гүйлгээнүүд дутуу уншигдсан байна... Дахин уншуулна уу'),
                duration: const Duration(seconds: 5),
                elevation: 10,
              ),
            );
            break;
          }

          if (response.length - 2 != 0x2e) {
            // No record on this index
            continue;
          }

          Transaction transaction = Transaction.fromByteArray(response);
          transactionRecords.add(transaction);

          // Provider.of<CardModel>(context, listen: false)
          //     .addTransaction(transaction);

          // var moreInfoCommand = Uint8List.fromList([
          //   0x00,
          //   0xB2,
          //   i,
          //   0x1C,
          //   0x34,
          // ]);
          // var moreResponse = await isoDep.transceive(moreInfoCommand);
          // var moreResponseHex = hex.encode(moreResponse);
          // print(["inOut", moreResponseHex.substring(10, 12)]);
          // print(["stationId", moreResponseHex.substring(12, 12)]);
          // print(
          //     ["routeId", hex.encode(moreResponse.getRange(48, 56).toList())]);
          // print([
          //   "passengers",
          //   hex.encode(moreResponse.getRange(58, 60).toList())
          // ]);
          // print([
          //   "vehicleId",
          //   hex.encode(moreResponse.getRange(68, 72).toList())
          // ]);
          // print([
          //   "routeKey",
          //   int.parse(hex.encode(moreResponse.getRange(48, 56).toList()),
          //       radix: 16)
          // ]);
          // print([
          //   "station",
          //   int.parse(hex.encode(moreResponse.getRange(12, 19).toList()),
          //       radix: 16)
          // ]);
        }

        transactionRecords =
            Util.assignUnknownTransactiontypes(transactionRecords);

        cardModel.cardNumber = cardNumber;
        cardModel.balance = balance;
        if (transactionRecords.length > 0) {
          cardModel.addTransactions(transactionRecords.toList());
        }
      },
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _errorScaffoldKey,
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
                    width: MediaQuery.of(context).size.width - 40,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ContentContainer(),
                  ),
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
