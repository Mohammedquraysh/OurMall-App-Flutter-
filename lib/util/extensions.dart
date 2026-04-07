// lib/util/extensions.dart
import 'package:intl/intl.dart';

extension PriceFormat on double {
  String get formatPrice {
    final fmt = NumberFormat('#,##0', 'en_NG');
    return '₦${fmt.format(this)}';
  }
}

extension CountdownFormat on int {
  String get formatCountdown {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    final s = this % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
