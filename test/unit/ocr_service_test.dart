import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/services/ocr_service.dart';

void main() {
  group('OcrService.parseRecognizedText', () {
    test('extracts electricity bill (Hidroelectrica) with due date and total de plata', () {
      const rawText = '''
S.P.E.E.H. HIDROELECTRICA S.A.
FACTURA FISCALA SERIA HDX NR 123456
DATA EMITERII: 01.10.2026
DATA SCADENTA: 25.10.2026
CONSUM: 185.00 kWh
TOTAL DE PLATA: 148.50 LEI
Va multumim!
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'Hidroelectrica');
      expect(result.probableAmount, 148.50);
      expect(result.probableDate, DateTime(2026, 10, 25));
      expect(result.isReceipt, false);
      expect(result.summary, contains('148.50'));
    });

    test('extracts supermarket receipt (Lidl) and detects receipt flag', () {
      const rawText = '''
LIDL DISCOUNT SRL
STR. BUCURESTI NR. 10
BON FISCAL
CASA DE MARCAT 01
LAPTE PROASPAT 1L        7.99 A
PAINE INTEGRALA          5.50 A
DETERGENT                29.90 B
TOTAL                   43.39
NUMERAR                 50.00
REST                     6.61
DATA: 15.09.2026 14:30
BF: 0045
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'Lidl');
      expect(result.probableAmount, 43.39);
      expect(result.isReceipt, true);
    });

    test('extracts telecom invoice (Digi) with English/Romanian mixed patterns', () {
      const rawText = '''
RCS & RDS S.A.
DIGI COMMUNICATIONS
Cod client: 987654321
Factura seria DIGI nr. 998877
Data facturii: 05.10.2026
Data scadenta: 20.10.2026
Abonament Internet Fiberlink: 40.00
Abonament TV Digital: 30.00
TOTAL DE PLATA: 70.00 RON
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'Digi (RCS & RDS)');
      expect(result.probableAmount, 70.00);
      expect(result.probableDate, DateTime(2026, 10, 20));
      expect(result.isReceipt, false);
    });

    test('handles document mode (prioritizes future expiry date)', () {
      const rawText = '''
REPUBLICA ROMANIA
PASAPORT / PASSPORT
EMIS LA: 10.05.2020
EXPIRY DATE: 10.05.2030
CNP: 1950101123456
''';

      final result = OcrService.parseRecognizedText(rawText, isDocument: true);

      expect(result.probableTitle, 'Passport');
      expect(result.probableAmount, isNull);
      expect(result.probableDate, DateTime(2030, 5, 10));
      expect(result.isReceipt, false);
    });
  });
}
