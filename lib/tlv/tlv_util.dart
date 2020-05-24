import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';

// Converted from https://github.com/metrodroid/metrodroid/blob/v3.0.0/src/commonMain/kotlin/au/id/micolous/metrodroid/card/iso7816/ISO7816TLV.kt

class TlvUtil {
  static const MAX_TLV_FIELD_LENGTH = 0xffff;

  static final TlvUtil _tlvUtil = TlvUtil._internal();

  factory TlvUtil() {
    return _tlvUtil;
  }

  TlvUtil._internal();

  int getTLVIDLen(Uint8List buf, int p) {
    if (buf[p].toInt() & 0x1f != 0x1f) {
      return 1;
    }

    var len = 1;
    while (buf[p + len++].toInt() & 0x80 != 0) {
      ;
    }
    return len;
  }

  Map decodeTLVLen(Uint8List buf, int p) {
    var headByte = buf[p].toInt() & 0xff;
    if (headByte >> 7 == 0) {
      return {
        'first': 1,
        'second': headByte & 0x7f,
        'third': 0,
      };
    }

    var numfollowingbytes = headByte & 0x7f;

    var length = byteArrayToInt(buf, p + 1, numfollowingbytes);

    if (length > MAX_TLV_FIELD_LENGTH) {
      // 64 KiB field length is enough for anyone(tm). :)
      print('Definite long form at $p of > $MAX_TLV_FIELD_LENGTH bytes ($length)');
      return null;
    } else if (length < 0) {
      // Shouldn't get negative values either.
      print('Definite log form at $p has negative value? ($length)');
      return null;
    }

    return {
      'first': 1 + numfollowingbytes,
      'second': length,
      'third': 0,
    };
  }

  List<Map> berTlvIterate(Uint8List buf) {
    var list = <Map>[];

    // Skip null bytes at start:
    // "Before, between, or after TLV-coded data objects, '00' bytes without any meaning may
    // occur (for example, due to erased or modified TLV-coded data objects)."
    var p = buf.indexWhere((element) => element != 0x00);

    if (p == -1) {
      // No non-null bytes
      return list;
    }

    // Skip ID
    p = getTLVIDLen(buf, 0);
    var decodedTLVLen = decodeTLVLen(buf, p);
    if (decodedTLVLen == null) {
      return list;
    }
    var startoffset = decodedTLVLen['first'];
    var alldatalen = decodedTLVLen['second'];
    var alleoclen = decodedTLVLen['third'];
    if (p < 0 || startoffset < 0 || alldatalen < 0 || alleoclen < 0) {
      print('Invalid TLV reading header: p=$p, startoffset=$startoffset, alldatalen=$alldatalen, alleoclen=$alleoclen');
      return list;
    }

    p += startoffset;
    var fulllen = p + alldatalen;

    while (p < fulllen) {
      // Skip null bytes
      if (buf[p] == 0x00) {
        p++;
        continue;
      }

      var idlen = getTLVIDLen(buf, p);

      if (p + idlen >= buf.length) break; // EOF
      var id = sliceArraySafe(buf, p, idlen);
      if (id == null) {
        print('Invalid TLV ID data at $p: out of bounds');
        break;
      }

      // Log.d(TAG, "($p) id=${id.getHexString()}")

      decodedTLVLen = decodeTLVLen(buf, p + idlen);
      if (decodedTLVLen == null) {
        break;
      }
      var hlen = decodedTLVLen['first'];
      var datalen = decodedTLVLen['second'];
      var eoclen = decodedTLVLen['third'];

      if (idlen < 0 || hlen < 0 || datalen < 0 || eoclen < 0) {
        // Invalid lengths, abort!
        print('Invalid TLV data at $p (<0): idlen=$idlen, hlen=$hlen, datalen=$datalen, eoclen=$eoclen');
        break;
      }

      var header = sliceArraySafe(buf, p, idlen + hlen);
      var data = sliceArraySafe(buf, p + idlen + hlen, datalen);

      if (header == null || data == null) {
        // Invalid ranges, abort!
        print('Invalid TLV data at $p: out of bounds');
        break;
      }

      if ((id.every((element) => element == 0x00) || id.isEmpty) && (header.isEmpty || header.every((element) => element == 0x00)) && data.isEmpty) {
        // Skip empty tag
        continue;
      }

      // Log.d(TAG, "($p) id=${id.toHexString()}, header=${header.getHexString()}, " +
      //         "data=${data.getHexString()}")
      list.add({
        'first': id,
        'second': header,
        'third': data,
      });
      p += idlen + hlen + datalen + eoclen;
    }

    return list;
  }

  Uint8List findBERTLVString(Uint8List buf, String target, bool keepHeader) {
    return findBERTLV(buf, hex.decode(target), keepHeader);
  }

  Uint8List findBERTLV(Uint8List buf, Uint8List target, bool keepHeader) {
    var result = berTlvIterate(buf).firstWhere((element) => hex.encode(element['first']) == hex.encode(target), orElse: () => null);

    if (result == null) {
      return null;
    }

    if (keepHeader) {
      return result['first'] + result['second'];
    }
    return result['third'];
  }

  Uint8List sliceArraySafe(Uint8List buf, int off, int len) {
    if (off < 0 || len < 0 || off >= buf.length) {
      return null;
    }
    return buf.sublist(off, (off + min(len, buf.length - off)));
  }

  int byteArrayToInt(Uint8List b, int offset, int length) {
    if (b.length < offset + length) {
      throw Exception('offset + length must be less than or equal to b.length');
    }

    var value = 0;
    for (var i = 0; i < length; i++) {
      var shift = (length - 1 - i) * 8;
      value += (b[i + offset] & 0xFF) << shift;
    }

    return value;
  }

  String getHexString(Uint8List buf, int offset, int length) {
    var result = '';
    for (var i = offset; i < offset + length; i++) {
      result += ((buf[i].toInt() & 0xff) | 0x100).toRadixString(16).substring(1);
    }
    return result;
  }

}