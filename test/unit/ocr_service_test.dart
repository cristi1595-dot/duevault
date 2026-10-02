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

    test('extracts US utility bill (AT&T) with textual date and dollar amount', () {
      const rawText = '''
AT&T BILLING STATEMENT
Account Number: 123-456-7890
Billing Date: Oct 20, 2026
Payment Due Date: Nov 18, 2026
Monthly Charges: \$85.00
Taxes & Fees: \$12.50
TOTAL AMOUNT DUE: \$97.50
Pay online at att.com
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'AT&T');
      expect(result.probableAmount, 97.50);
      expect(result.probableDate, DateTime(2026, 11, 18));
      expect(result.isReceipt, false);
    });

    test('extracts UK utility bill (British Gas) with GBP currency and Pay By date', () {
      const rawText = '''
British Gas
Customer Reference: 600123456
Electricity & Gas Statement
Bill Date: 01 Oct 2026
Pay by: 24 Oct 2026
Energy charges: £75.00
VAT @ 5%: £3.75
Total amount payable: £78.75
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'British Gas');
      expect(result.probableAmount, 78.75);
      expect(result.probableDate, DateTime(2026, 10, 24));
      expect(result.isReceipt, false);
    });

    test('extracts US retailer receipt (Walmart) with Store # and CASHIER', () {
      const rawText = '''
Walmart Supercenter
Store # 2210
Manager: John Smith
REG # 04   TR # 09812
GROCERY ITEMS        12.99
HOUSEHOLD GOODS      24.50
SUBTOTAL             37.49
TAX                   2.99
TOTAL                40.48
CASH TENDER          50.00
CHANGE DUE            9.52
Date: 10/12/2026  15:45
THANK YOU FOR SHOPPING AT WALMART
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'Walmart');
      expect(result.probableAmount, 40.48);
      expect(result.isReceipt, true);
    });

    test('extracts German invoice with GESAMTBETRAG and FAELLIG AM', () {
      const rawText = '''
E.ON Energie Deutschland GmbH
Rechnung Nr. RE-2026-9912
Rechnungsdatum: 01.11.2026
Faellig am: 20.11.2026
Stromverbrauch: 110,00 EUR
Mehrwertsteuer: 20,90 EUR
GESAMTBETRAG: 130,90 EUR
Bitte ueberweisen Sie den Betrag fristgerecht.
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'E.ON');
      expect(result.probableAmount, 130.90);
      expect(result.probableDate, DateTime(2026, 11, 20));
      expect(result.isReceipt, false);
    });

    test('extracts French invoice with TOTAL A PAYER and DATE D\'ECHEANCE', () {
      const rawText = '''
EDF Energy
Facture Electricite
Date d'echeance: 15/12/2026
Abonnement: 25,00 EUR
Consommation: 45,50 EUR
TOTAL A PAYER: 70,50 EUR
''';

      final result = OcrService.parseRecognizedText(rawText);

      expect(result.probableTitle, 'EDF Energy');
      expect(result.probableAmount, 70.50);
      expect(result.probableDate, DateTime(2026, 12, 15));
      expect(result.isReceipt, false);
    });
  });
}
