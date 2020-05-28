import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

class NfcAvailabilityService {
  static final NfcAvailabilityService _instance =
      NfcAvailabilityService._internal();

  factory NfcAvailabilityService() {
    return _instance;
  }

  NfcAvailabilityService._internal();

  Stream<bool> get onNfcAvailabilityChanged async* {
    yield await NfcManager.instance.isAvailable();
    yield* Stream.periodic(Duration(seconds: 2))
        .asyncMap((_) => NfcManager.instance.isAvailable());
  }
}
