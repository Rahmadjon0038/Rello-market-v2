import 'package:flutter/material.dart';

class ColorUtils {
  static Color? tryParseColor(String? input) {
    final raw = (input ?? '').trim();
    if (raw.isEmpty) return null;

    final fromHex = _tryParseHex(raw);
    if (fromHex != null) return fromHex;

    final normalized = _normalize(raw);
    return _namedColor(normalized);
  }

  static String _normalize(String value) {
    var s = value.trim().toLowerCase();
    s = s.replaceAll("’", "'");
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  static Color? _tryParseHex(String value) {
    var s = value.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.toLowerCase().startsWith('0x')) s = s.substring(2);

    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return null;
    if (s.length == 6) {
      final v = int.tryParse('FF$s', radix: 16);
      return v == null ? null : Color(v);
    }
    if (s.length == 8) {
      final v = int.tryParse(s, radix: 16);
      return v == null ? null : Color(v);
    }
    return null;
  }

  static Color? _namedColor(String n) {
    // Uzbek (latin), English, Russian (cyrillic) aliases.
    switch (n) {
      case 'qora':
      case 'black':
      case 'черный':
      case 'чёрный':
        return Colors.black;
      case 'oq':
      case 'white':
      case 'белый':
        return Colors.white;
      case 'qizil':
      case 'red':
      case 'красный':
        return Colors.red;
      case 'yashil':
      case 'green':
      case 'зелёный':
      case 'зеленый':
        return Colors.green;
      case "ko'k":
      case 'kok':
      case 'blue':
      case 'синий':
        return Colors.blue;
      case "to'q ko'k":
      case 'toq kok':
      case 'navy':
      case 'темно-синий':
      case 'тёмно-синий':
        return const Color(0xFF0B3D91);
      case 'sariq':
      case 'yellow':
      case 'желтый':
      case 'жёлтый':
        return Colors.yellow;
      case 'kulrang':
      case 'gray':
      case 'grey':
      case 'серый':
        return Colors.grey;
      case 'jigarrang':
      case 'brown':
      case 'коричневый':
        return Colors.brown;
      case 'pushti':
      case 'pink':
      case 'розовый':
        return Colors.pink;
      case 'binafsha':
      case 'purple':
      case 'фиолетовый':
        return Colors.purple;
      case 'to‘q sariq':
      case "to'q sariq":
      case 'orange':
      case 'оранжевый':
        return Colors.orange;
      case 'havorang':
      case 'sky':
      case 'light blue':
      case 'голубой':
        return Colors.lightBlue;
    }
    return null;
  }
}

