import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/utils/category_matcher.dart';

void main() {
  group('CategoryMatcher Tests', () {
    test('detectCategory returns null for empty or whitespace titles', () {
      expect(CategoryMatcher.detectCategory(''), isNull);
      expect(CategoryMatcher.detectCategory('   '), isNull);
    });

    test('detectCategory correctly identifies Utilities', () {
      expect(CategoryMatcher.detectCategory('Factura Enel Energie'), equals('Utilities'));
      expect(CategoryMatcher.detectCategory('Plata Hidroelectrica'), equals('Utilities'));
      expect(CategoryMatcher.detectCategory('Consum Gaz E.ON'), equals('Utilities'));
      expect(CategoryMatcher.detectCategory('Factura Apa Nova'), equals('Utilities'));
      expect(CategoryMatcher.detectCategory('Salubritate sector 3'), equals('Utilities'));
      expect(CategoryMatcher.detectCategory('Termoenergetica incalzire'), equals('Utilities'));
    });

    test('detectCategory correctly identifies Telecom', () {
      expect(CategoryMatcher.detectCategory('Factura Digi RDS'), equals('Telecom'));
      expect(CategoryMatcher.detectCategory('Abonament Vodafone'), equals('Telecom'));
      expect(CategoryMatcher.detectCategory('Orange Romania Communications'), equals('Telecom'));
      expect(CategoryMatcher.detectCategory('Internet Fibra Optica'), equals('Telecom'));
    });

    test('detectCategory correctly identifies Subscriptions', () {
      expect(CategoryMatcher.detectCategory('Netflix Premium Plan'), equals('Subscriptions'));
      expect(CategoryMatcher.detectCategory('Spotify Family'), equals('Subscriptions'));
      expect(CategoryMatcher.detectCategory('YouTube Premium'), equals('Subscriptions'));
      expect(CategoryMatcher.detectCategory('Disney+ Subscription'), equals('Subscriptions'));
      expect(CategoryMatcher.detectCategory('ChatGPT Plus renewal'), equals('Subscriptions'));
      expect(CategoryMatcher.detectCategory('iCloud 200GB storage'), equals('Subscriptions'));
    });

    test('detectCategory correctly identifies Auto', () {
      expect(CategoryMatcher.detectCategory('Polita Asigurare RCA'), equals('Auto'));
      expect(CategoryMatcher.detectCategory('Asigurare CASCO Generali'), equals('Auto'));
      expect(CategoryMatcher.detectCategory('Rovinieta 1 an'), equals('Auto'));
      expect(CategoryMatcher.detectCategory('Alimentare Benzina Petrom'), equals('Auto'));
      expect(CategoryMatcher.detectCategory('Revizie periodica auto'), equals('Auto'));
      expect(CategoryMatcher.detectCategory('Parcare aeroport Otopeni'), equals('Auto'));
    });

    test('detectCategory correctly identifies Housing', () {
      expect(CategoryMatcher.detectCategory('Plata Chirie Garsoniera'), equals('Housing'));
      expect(CategoryMatcher.detectCategory('Intretinere bloc scara A'), equals('Housing'));
      expect(CategoryMatcher.detectCategory('Fond reparatii asociatie'), equals('Housing'));
    });

    test('detectCategory correctly identifies Loans', () {
      expect(CategoryMatcher.detectCategory('Rata credit nevoi personale'), equals('Loans'));
      expect(CategoryMatcher.detectCategory('Imprumut BCR'), equals('Loans'));
      expect(CategoryMatcher.detectCategory('Rata ING Bank'), equals('Loans'));
      expect(CategoryMatcher.detectCategory('Leasing financiar auto'), equals('Loans'));
    });

    test('detectCategory correctly identifies Health', () {
      expect(CategoryMatcher.detectCategory('Control Dentist stomatolog'), equals('Health'));
      expect(CategoryMatcher.detectCategory('Medicamente Farmacie Catena'), equals('Health'));
      expect(CategoryMatcher.detectCategory('Abonament Sanador'), equals('Health'));
      expect(CategoryMatcher.detectCategory('Analize Regina Maria'), equals('Health'));
    });

    test('detectCategory correctly identifies Identity', () {
      expect(CategoryMatcher.detectCategory('Taxa reinnoire Buletin CI'), equals('Identity'));
      expect(CategoryMatcher.detectCategory('Pasaport simplu electronic'), equals('Identity'));
      expect(CategoryMatcher.detectCategory('Reinnoire permis conducere'), equals('Identity'));
      expect(CategoryMatcher.detectCategory('Certificat nastere'), equals('Identity'));
    });

    test('detectCategory correctly identifies Warranty', () {
      expect(CategoryMatcher.detectCategory('Garantie televizor eMAG'), equals('Warranty'));
      expect(CategoryMatcher.detectCategory('Garantie extinsa Altex'), equals('Warranty'));
      expect(CategoryMatcher.detectCategory('Flanco bon garantie'), equals('Warranty'));
    });

    test('detectCategory is case-insensitive', () {
      expect(CategoryMatcher.detectCategory('ENEL ENERGIE'), equals('Utilities'));
      expect(CategoryMatcher.detectCategory('netFLIX'), equals('Subscriptions'));
      expect(CategoryMatcher.detectCategory('rCa'), equals('Auto'));
    });

    test('detectCategory returns null when no matching category is found', () {
      expect(CategoryMatcher.detectCategory('Unkown mystery bill 12345'), isNull);
      expect(CategoryMatcher.detectCategory('Random note'), isNull);
    });
  });
}
