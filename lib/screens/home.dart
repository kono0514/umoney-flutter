import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:provider/provider.dart';
import 'package:umoney_flutter/contentContainer.dart';
import 'package:umoney_flutter/models/app.dart';
import 'package:umoney_flutter/models/card.dart';
import 'package:umoney_flutter/models/transaction.dart';
import 'package:umoney_flutter/utils/util.dart';
import 'package:umoney_flutter/utils/tlv_util.dart';
import 'package:umoney_flutter/widgets/busCard.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _errorScaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> onTagDicovered(NfcTag tag) async {
    var cardModel = Provider.of<CardModel>(context, listen: false);
    var appModel = Provider.of<AppModel>(context, listen: false);

    appModel.showInstructions = false;
    cardModel.reset();

    IsoDep isoDep = IsoDep.fromTag(tag);

    if (isoDep == null) {
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
      _errorScaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(
              'Карт уншигдсангүй... Уншуулахдаа бага зэрэг удаан бариарай'),
          duration: const Duration(seconds: 5),
        ),
      );
      appModel.showInstructions = true;
      return;
    }
    // TODO: verify its umoney card from the FCI first.

    var balance =
        Util.getIntegerFromByteArray(balanceRecv, 0, balanceRecv.length - 2);

    // Extract the card number from the Purse info.
    Uint8List purseInfo = TlvUtil().findBERTLVString(fci, 'b0', false);
    var cardNumber = purseInfo == null
        ? ""
        : Util.getHexStringFromByteArray(purseInfo, 4, 12);

    // Get the last 20 transactions (stored in order from newest (0 index) -> oldest)
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

      try {
        Transaction transaction = Transaction.fromByteArray(response);
        transactionRecords.add(transaction);
      } catch (e) {
        _errorScaffoldKey.currentState.showSnackBar(
          SnackBar(
            content: Text(
                'Карт гүйлгээний мэдээлэл уншихад алдаа гарлаа. Хөгжүүлэгчид мэдэгдэнэ үү.'),
            duration: const Duration(seconds: 5),
            elevation: 10,
          ),
        );
        break;
      }
    }

    transactionRecords = Util.assignUnknownTransactiontypes(transactionRecords);

    cardModel.cardNumber = cardNumber;
    cardModel.balance = balance;
    if (transactionRecords.length > 0) {
      cardModel.addTransactions(transactionRecords.toList());
    }
  }

  @override
  void initState() {
    super.initState();

    NfcManager.instance.startTagSession(
      pollingOptions: Set.from([
        TagPollingOption.iso14443,
      ]),
      onDiscovered: onTagDicovered,
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
