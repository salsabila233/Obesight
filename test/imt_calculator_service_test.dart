import 'package:flutter_test/flutter_test.dart';
import 'package:obesight/services/imt_calculator_service.dart';

void main() {
  group('ImtCalculatorService Unit Tests', () {
    test('Perhitungan standar: 170 cm dan 65 kg menghasilkan IMT 22.5 (Normal, Risiko Rendah)', () {
      final rawBmi = ImtCalculatorService.calculateBmi(weight: 65, height: 170);
      expect(rawBmi, isNotNull);
      final roundedBmi = ImtCalculatorService.roundBmi(rawBmi!);
      expect(roundedBmi, 22.5);

      final classification = ImtCalculatorService.classifyBmi(roundedBmi);
      expect(classification['category'], 'Normal');
      expect(classification['risk'], 'Rendah');
    });

    test('Input dengan koma desimal ("65,5" kg dan "170,5" cm) berhasil diparsing dan dihitung', () {
      final w = ImtCalculatorService.parseDecimal('65,5');
      final h = ImtCalculatorService.parseDecimal('170,5');

      expect(w, 65.5);
      expect(h, 170.5);

      final rawBmi = ImtCalculatorService.calculateBmi(weight: w, height: h);
      expect(rawBmi, isNotNull);
      final roundedBmi = ImtCalculatorService.roundBmi(rawBmi!);
      expect(roundedBmi, 22.5);

      final classification = ImtCalculatorService.classifyBmi(roundedBmi);
      expect(classification['category'], 'Normal');
      expect(classification['risk'], 'Rendah');
    });

    test('Parsing string dengan titik desimal dan spasi ekstra', () {
      expect(ImtCalculatorService.parseDecimal(' 72.8 '), 72.8);
      expect(ImtCalculatorService.parseDecimal('55'), 55.0);
    });

    group('Tepat di setiap batas kategori IMT', () {
      test('Tepat di bawah batas Kurus (18.4) tergolong Kurus / Rendah', () {
        final res = ImtCalculatorService.classifyBmi(18.4);
        expect(res['category'], 'Kurus');
        expect(res['risk'], 'Rendah');
      });

      test('Tepat di batas bawah Normal (18.5) tergolong Normal / Rendah', () {
        final res = ImtCalculatorService.classifyBmi(18.5);
        expect(res['category'], 'Normal');
        expect(res['risk'], 'Rendah');
      });

      test('Tepat di batas atas Normal (24.9) tergolong Normal / Rendah', () {
        final res = ImtCalculatorService.classifyBmi(24.9);
        expect(res['category'], 'Normal');
        expect(res['risk'], 'Rendah');
      });

      test('Tepat di batas bawah Gemuk (25.0) tergolong Gemuk / Sedang', () {
        final res = ImtCalculatorService.classifyBmi(25.0);
        expect(res['category'], 'Gemuk');
        expect(res['risk'], 'Sedang');
      });

      test('Tepat di batas atas Gemuk (29.9) tergolong Gemuk / Sedang', () {
        final res = ImtCalculatorService.classifyBmi(29.9);
        expect(res['category'], 'Gemuk');
        expect(res['risk'], 'Sedang');
      });

      test('Tepat di batas Obesitas (30.0) tergolong Obesitas / Tinggi', () {
        final res = ImtCalculatorService.classifyBmi(30.0);
        expect(res['category'], 'Obesitas');
        expect(res['risk'], 'Tinggi');
      });

      test('Di atas batas Obesitas (35.5) tergolong Obesitas / Tinggi', () {
        final res = ImtCalculatorService.classifyBmi(35.5);
        expect(res['category'], 'Obesitas');
        expect(res['risk'], 'Tinggi');
      });
    });

    group('Validasi input kosong, nol, negatif, dan rentang tidak wajar', () {
      test('Input kosong (null atau string kosong)', () {
        expect(ImtCalculatorService.parseDecimal(''), isNull);
        expect(ImtCalculatorService.parseDecimal(null), isNull);
        expect(ImtCalculatorService.calculateBmi(weight: null, height: 170), isNull);
        expect(ImtCalculatorService.calculateBmi(weight: 60, height: null), isNull);
        expect(ImtCalculatorService.validateWeight(null), isNotNull);
        expect(ImtCalculatorService.validateHeight(null), isNotNull);
      });

      test('Input bernilai nol (0)', () {
        expect(ImtCalculatorService.calculateBmi(weight: 0, height: 170), isNull);
        expect(ImtCalculatorService.calculateBmi(weight: 60, height: 0), isNull);
        expect(ImtCalculatorService.validateWeight(0), isNotNull);
        expect(ImtCalculatorService.validateHeight(0), isNotNull);
      });

      test('Input bernilai negatif (-60, -170)', () {
        expect(ImtCalculatorService.calculateBmi(weight: -60, height: 170), isNull);
        expect(ImtCalculatorService.calculateBmi(weight: 60, height: -170), isNull);
        expect(ImtCalculatorService.validateWeight(-60), isNotNull);
        expect(ImtCalculatorService.validateHeight(-170), isNotNull);
      });

      test('Input di luar rentang wajar (weight < 20 atau > 350, height < 50 atau > 260)', () {
        expect(ImtCalculatorService.validateWeight(19.9), isNotNull);
        expect(ImtCalculatorService.validateWeight(350.1), isNotNull);
        expect(ImtCalculatorService.validateHeight(49.9), isNotNull);
        expect(ImtCalculatorService.validateHeight(260.1), isNotNull);

        // Rentang valid tidak mengembalikan error
        expect(ImtCalculatorService.validateWeight(20.0), isNull);
        expect(ImtCalculatorService.validateWeight(65.0), isNull);
        expect(ImtCalculatorService.validateWeight(350.0), isNull);

        expect(ImtCalculatorService.validateHeight(50.0), isNull);
        expect(ImtCalculatorService.validateHeight(170.0), isNull);
        expect(ImtCalculatorService.validateHeight(260.0), isNull);
      });
    });
  });
}
