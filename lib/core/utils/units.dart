import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/providers/settings_provider.dart';
import 'package:fit_track/core/utils/unit_conversions.dart';

/// Everything is stored in kg; this converts for display and input.
class WeightUnit {
  final bool pounds;
  const WeightUnit(this.pounds);

  String get label => pounds ? 'lb' : 'kg';

  double fromKg(double kg) => pounds ? UnitConversions.kgToLb(kg) : kg;
  double toKg(double value) => pounds ? UnitConversions.lbToKg(value) : value;

  /// Number only, e.g. "72.5".
  String number(double kg, {int decimals = 1}) {
    final s = fromKg(kg).toStringAsFixed(decimals);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  /// Number with unit, e.g. "72.5 kg".
  String format(double kg, {int decimals = 1}) => '${number(kg, decimals: decimals)} $label';

  /// Parses user input in the current unit and returns kg (null if invalid).
  double? parse(String input) {
    final v = double.tryParse(input.trim().replaceAll(',', '.'));
    return v == null ? null : toKg(v);
  }
}

final weightUnitProvider = Provider<WeightUnit>((ref) {
  return WeightUnit(ref.watch(settingsProvider).weightUnit == 'lb');
});
