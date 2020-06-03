import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umoney_flutter/widgets/scannerBottomSheet.dart';

class IntentScanner extends StatefulWidget {
  @override
  _IntentScannerState createState() => _IntentScannerState();
}

class _IntentScannerState extends State<IntentScanner> {
  static const platform = const MethodChannel('app.channel.shared.tag');
  final _sheetKey = GlobalKey<ScannerBottomSheetState>();

  getSharedBalance() async {
    Map sharedBalance = await platform.invokeMethod("getSharedBalance");
    if (sharedBalance == null ||
        sharedBalance["state"] == "querying" ||
        _sheetKey.currentState == null) {
      return await Future.delayed(
          const Duration(milliseconds: 500), getSharedBalance);
    }

    if (sharedBalance["state"] == "success") {
      _sheetKey.currentState.setBalance(sharedBalance["value"]);
    } else {
      _sheetKey.currentState.setError(sharedBalance["value"]);
    }
  }

  @override
  void initState() {
    super.initState();

    getSharedBalance();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      showModalBottomSheet(
        context: context,
        barrierColor: Colors.black.withAlpha(1),
        enableDrag: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (_) {
          return ScannerBottomSheet(key: _sheetKey);
        },
      ).then((value) {
        SystemNavigator.pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
    );
  }
}
