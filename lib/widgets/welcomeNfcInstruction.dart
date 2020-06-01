import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platform/platform.dart';
import 'package:android_intent/android_intent.dart';
import 'package:umoney_flutter/services/NfcAvailabilityService.dart';
import 'package:umoney_flutter/widgets/scanInstructionAnimation.dart';

class WelcomeNfcInstruction extends StatelessWidget {
  void _openNfcSettings() {
    if (const LocalPlatform().isAndroid) {
      try {
        AndroidIntent intent =
            AndroidIntent(action: 'android.settings.NFC_SETTINGS');
        intent.launch();
      } catch (ex) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream:
          NfcAvailabilityService().onNfcAvailabilityChanged.asBroadcastStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data == true) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Картаа уншуулна уу",
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: 46),
                ScanInstructionAnimation(),
              ],
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "NFC унтраастай байна.\nNFC-ээ асаана уу",
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      color: const Color(0xffFF0141),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                RaisedButton(
                  child: Text("NFC асаах"),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.only(left: 24, right: 24),
                  onPressed: _openNfcSettings,
                ),
              ],
            );
          }
        }
        return CircularProgressIndicator(
          value: null,
        );
      },
    );
  }
}
