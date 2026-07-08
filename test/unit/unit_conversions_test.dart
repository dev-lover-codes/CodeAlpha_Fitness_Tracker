import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/core/utils/unit_conversions.dart';

void main() {
  group('UnitConversions', () {
    test('converts kg to lb correctly', () {
      expect(UnitConversions.kgToLb(100), closeTo(220.462, 0.001));
    });
    test('converts lb to kg correctly', () {
      expect(UnitConversions.lbToKg(220.462), closeTo(100, 0.001));
    });
    test('converts cm to inches correctly', () {
      expect(UnitConversions.cmToInches(100), closeTo(39.3701, 0.001));
    });
    test('converts inches to cm correctly', () {
      expect(UnitConversions.inchesToCm(39.3701), closeTo(100, 0.001));
    });
  });
}
