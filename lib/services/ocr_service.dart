import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/logger.dart';

class OcrResult {
  final String rawText;
  final double? probableAmount;
  final DateTime? probableDate;
  final String? probableTitle;
  final bool isReceipt;

  OcrResult({
    required this.rawText,
    this.probableAmount,
    this.probableDate,
    this.probableTitle,
    this.isReceipt = false,
  });

  /// Formats a concise summary of what was found by OCR
  String get summary {
    final parts = <String>[];
    if (probableAmount != null) {
      parts.add('Amount: ${probableAmount!.toStringAsFixed(2)}');
    }
    if (probableDate != null) {
      parts.add('Due: ${probableDate!.day}/${probableDate!.month}/${probableDate!.year}');
    }
    if (probableTitle != null && probableTitle!.isNotEmpty) {
      parts.add('($probableTitle)');
    }
    return parts.isEmpty ? 'Details captured' : parts.join(' • ');
  }
}

class OcrService {
  static final _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Process an image file and extract potential data
  /// [isDocument] helps prioritize future dates for expiry
  static Future<OcrResult> processImage(
    File imageFile, {
    bool isDocument = false,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final String fullText = recognizedText.text;
      return parseRecognizedText(fullText, isDocument: isDocument);
    } catch (e, stack) {
      logger.e('OCR Error', error: e, stackTrace: stack);
      return OcrResult(rawText: '');
    }
  }

  /// Parses recognized raw OCR text to extract structured fields
  static OcrResult parseRecognizedText(
    String fullText, {
    bool isDocument = false,
  }) {
    final isReceipt = !isDocument && _detectReceipt(fullText);
    final amount = isDocument ? null : _extractAmount(fullText);
    final date = _extractDate(
      fullText,
      preferFuture: isDocument,
      isReceipt: isReceipt,
    );
    final title = _extractTitle(fullText);

    return OcrResult(
      rawText: fullText,
      probableAmount: amount,
      probableDate: date,
      probableTitle: title,
      isReceipt: isReceipt,
    );
  }

  /// Closes the recognizer when no longer needed
  static void dispose() {
    _textRecognizer.close();
  }

  static bool _detectReceipt(String text) {
    final upper = text.toUpperCase();
    const receiptKeywords = [
      // English (US, UK, Global)
      'RECEIPT',
      'TAX INVOICE',
      'CASH RECEIPT',
      'SALES RECEIPT',
      'CUSTOMER COPY',
      'STORE #',
      'STORE NO',
      'TILL #',
      'REG #',
      'REGISTER #',
      'CARD TENDER',
      'CHANGE DUE',
      'CASHIER',
      'SUBTOTAL',
      'MERCHANT ID',

      // German (DE, AT, CH)
      'KASSENBON',
      'KASSENZETTEL',
      'BARBELEG',
      'QUITTUNG',
      'BELEG',
      'MWST',

      // French (FR, BE, CA)
      'TICKET DE CAISSE',
      'FACTURETTE',
      'RECU',
      'TICKET CLIENT',

      // Spanish (ES, LATAM)
      'TICKET DE COMPRA',
      'COMPROBANTE DE PAGO',
      'BOLETA DE VENTA',

      // Italian (IT)
      'SCONTRINO FISCALE',
      'RICEVUTA FISCALE',

      // Romanian (RO, MD)
      'BON FISCAL',
      'CASA DE MARCAT',
      'CHITANTA',
      'BON NR',
      'BF:',
      'NUMERAR',
      'SCHIMB',
      'TVA',
    ];
    for (final kw in receiptKeywords) {
      if (upper.contains(kw)) return true;
    }
    return false;
  }

  static double? _parseAmountString(String str) {
    try {
      // Remove any currency symbols, letters, spaces except digits, dots and commas
      var cleaned = str.replaceAll(RegExp(r'[^0-9.,]'), '').trim();
      if (cleaned.contains('.') && cleaned.contains(',')) {
        if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
          // European style: 1.250,50 -> 1250.50
          cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // US/UK style: 1,250.50 -> 1250.50
          cleaned = cleaned.replaceAll(',', '');
        }
      } else if (cleaned.contains(',')) {
        // e.g. 145,50 -> 145.50
        cleaned = cleaned.replaceAll(',', '.');
      }
      final val = double.tryParse(cleaned);
      if (val != null && val > 0 && val < 5000000) {
        return val;
      }
    } catch (_) {}
    return null;
  }

  static double? _extractAmount(String text) {
    final lines = text.split('\n');

    // Priority keywords across US, UK, German, French, Spanish, Italian, Romanian
    const priorityKeywords = [
      // English (US, UK, International)
      'TOTAL AMOUNT DUE',
      'TOTAL AMOUNT PAYABLE',
      'AMOUNT DUE',
      'AMOUNT PAYABLE',
      'TOTAL DUE',
      'BALANCE DUE',
      'NEW BALANCE',
      'CURRENT CHARGES DUE',
      'PAYMENT DUE',
      'INVOICE TOTAL',
      'STATEMENT TOTAL',
      'ACCOUNT BALANCE',
      'GRAND TOTAL',
      'TOTAL PAYABLE',
      'TOTAL CHARGES',

      // German
      'GESAMTBETRAG',
      'ZU ZAHLEN',
      'FAELLIGER BETRAG',
      'RECHNUNGSBETRAG',
      'ENDSUMME',
      'ZAHLBETRAG',

      // French
      'TOTAL A PAYER',
      'NET A PAYER',
      'MONTANT TOTAL',
      'TOTAL TTC',
      'SOLDE DU',
      'SOMME DUE',
      'MONTANT DU',

      // Spanish
      'TOTAL A PAGAR',
      'IMPORTE TOTAL',
      'IMPORTE A PAGAR',
      'TOTAL FACTURA',
      'SALDO TOTAL',

      // Italian
      'TOTALE DA PAGARE',
      'TOTALE FATTURA',
      'IMPORTO DOVUTO',
      'IMPORTO TOTALE',

      // Romanian
      'TOTAL DE PLATA',
      'TOTAL PLATA',
      'REST DE PLATA',
      'SUMA DE PLATA',
      'VALOARE TOTALA',
      'NET DE PLATA',
      'DE PLATA',

      // General fallback
      'TOTAL',
    ];

    // Matches formatted currencies: e.g. $129.99, £45.50, € 1.250,50, 148.50 LEI/RON/USD
    final RegExp amountPattern = RegExp(
      r'(?:[\$£€]\s*)?(\d{1,3}(?:[.,]\d{3})*|\d+)[.,](\d{2})(?:\s*(?:USD|GBP|EUR|RON|LEI|CAD|AUD|CHF))?',
      caseSensitive: false,
    );

    // 1. Check lines matching priority keywords first
    for (final kw in priorityKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final upperLine = lines[i].toUpperCase();
        if (upperLine.contains(kw)) {
          // Ignore lines that are explicitly SUB-TOTAL when searching for TOTAL
          if (kw == 'TOTAL' &&
              (upperLine.contains('SUBTOTAL') ||
               upperLine.contains('SUB TOTAL') ||
               upperLine.contains('SUB-TOTAL') ||
               upperLine.contains('SOUS-TOTAL') ||
               upperLine.contains('ZWISCHENSUMME'))) {
            continue;
          }

          // Look on this line
          final matchOnLine = amountPattern.firstMatch(lines[i]);
          if (matchOnLine != null) {
            final parsed = _parseAmountString(matchOnLine.group(0)!);
            if (parsed != null) return parsed;
          }
          // Look on immediately following line
          if (i + 1 < lines.length) {
            final matchNextLine = amountPattern.firstMatch(lines[i + 1]);
            if (matchNextLine != null) {
              final parsed = _parseAmountString(matchNextLine.group(0)!);
              if (parsed != null) return parsed;
            }
          }
        }
      }
    }

    // 2. Fallback: collect all valid amount patterns and pick the largest one
    final List<double> allAmounts = [];
    final allMatches = amountPattern.allMatches(text);
    for (final match in allMatches) {
      final parsed = _parseAmountString(match.group(0)!);
      if (parsed != null) {
        allAmounts.add(parsed);
      }
    }

    if (allAmounts.isEmpty) return null;
    allAmounts.sort();
    return allAmounts.last;
  }

  static DateTime? _extractDate(
    String text, {
    bool preferFuture = false,
    bool isReceipt = false,
  }) {
    final lines = text.split('\n');
    final upperText = text.toUpperCase();

    // Check if document has US context ($ symbol or US phone/state hints)
    final bool isUsContext = upperText.contains(r'$') ||
        upperText.contains('USA') ||
        upperText.contains('UNITED STATES');

    // Multilingual textual month map (English, German, French, Spanish, Italian, Romanian)
    const monthMap = {
      'JAN': 1, 'JANUARY': 1, 'IAN': 1, 'IANUARIE': 1, 'JANUAR': 1, 'JANVIER': 1, 'ENERO': 1, 'GENNAIO': 1,
      'FEB': 2, 'FEBRUARY': 2, 'FEBRUARIE': 2, 'FEBRUAR': 2, 'FEVRIER': 2, 'FEBRERO': 2, 'FEBBRAIO': 2,
      'MAR': 3, 'MARCH': 3, 'MARTIE': 3, 'MAERZ': 3, 'MARS': 3, 'MARZO': 3,
      'APR': 4, 'APRIL': 4, 'APRILIE': 4, 'AVRIL': 4, 'ABRIL': 4, 'APRILE': 4,
      'MAY': 5, 'MAI': 5, 'MAIO': 5, 'MAYO': 5, 'MAGGIO': 5,
      'JUN': 6, 'JUNE': 6, 'IUNIE': 6, 'IUN': 6, 'JUNI': 6, 'JUIN': 6, 'JUNIO': 6, 'GIUGNO': 6,
      'JUL': 7, 'JULY': 7, 'IULIE': 7, 'IUL': 7, 'JULI': 7, 'JUILLET': 7, 'JULIO': 7, 'LUGLIO': 7,
      'AUG': 8, 'AUGUST': 8, 'AOUT': 8, 'AGOSTO': 8,
      'SEP': 9, 'SEPT': 9, 'SEPTEMBER': 9, 'SEPTEMBRIE': 9, 'SETIEMBRE': 9, 'SETTEMBRE': 9,
      'OCT': 10, 'OCTOBER': 10, 'OCTOMBRIE': 10, 'OKTOBER': 10, 'OCTOBRE': 10, 'OCTUBRE': 10, 'OTTOBRE': 10,
      'NOV': 11, 'NOVEMBER': 11, 'NOIEMBRIE': 11, 'NOVEMBRE': 11, 'NOVIEMBRE': 11,
      'DEC': 12, 'DECEMBER': 12, 'DECEMBRIE': 12, 'DEZEMBER': 12, 'DECEMBRE': 12, 'DICIEMBRE': 12, 'DICEMBRE': 12,
    };

    // Format 1: DD.MM.YYYY, DD/MM/YYYY, MM/DD/YYYY
    final RegExp numericDatePattern = RegExp(
      r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b',
    );
    // Format 2: ISO YYYY-MM-DD
    final RegExp isoDatePattern = RegExp(
      r'\b(\d{4})[./-](\d{1,2})[./-](\d{1,2})\b',
    );
    // Format 3: Textual "15 Oct 2026" or "15-Oct-2026"
    final RegExp dayMonthNamePattern = RegExp(
      r'\b(\d{1,2})[\s,./-]+([A-Za-z]{3,10})[\s,./-]+(\d{2,4})\b',
    );
    // Format 4: Textual "Oct 15, 2026" or "October 15, 2026"
    final RegExp monthNameDayPattern = RegExp(
      r'\b([A-Za-z]{3,10})[\s,./-]+(\d{1,2})(?:st|nd|rd|th)?[\s,./-]+(\d{2,4})\b',
    );

    DateTime? parseDateString(String str) {
      // 1. Textual Month First: "Oct 15, 2026"
      final mndMatch = monthNameDayPattern.firstMatch(str);
      if (mndMatch != null) {
        final monthKey = mndMatch.group(1)!.toUpperCase();
        final month = monthMap[monthKey];
        if (month != null) {
          final day = int.tryParse(mndMatch.group(2)!);
          final rawYear = int.tryParse(mndMatch.group(3)!);
          if (day != null && rawYear != null) {
            final year = rawYear < 100 ? rawYear + 2000 : rawYear;
            if (day >= 1 && day <= 31 && year >= 2000 && year <= 2099) {
              return DateTime(year, month, day);
            }
          }
        }
      }

      // 2. Textual Day First: "15 Oct 2026"
      final dmnMatch = dayMonthNamePattern.firstMatch(str);
      if (dmnMatch != null) {
        final monthKey = dmnMatch.group(2)!.toUpperCase();
        final month = monthMap[monthKey];
        if (month != null) {
          final day = int.tryParse(dmnMatch.group(1)!);
          final rawYear = int.tryParse(dmnMatch.group(3)!);
          if (day != null && rawYear != null) {
            final year = rawYear < 100 ? rawYear + 2000 : rawYear;
            if (day >= 1 && day <= 31 && year >= 2000 && year <= 2099) {
              return DateTime(year, month, day);
            }
          }
        }
      }

      // 3. ISO format: YYYY-MM-DD
      final isoMatch = isoDatePattern.firstMatch(str);
      if (isoMatch != null) {
        try {
          final year = int.parse(isoMatch.group(1)!);
          final month = int.parse(isoMatch.group(2)!);
          final day = int.parse(isoMatch.group(3)!);
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 2000 && year <= 2099) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }

      // 4. Numeric format: DD/MM/YYYY vs MM/DD/YYYY (US)
      final numMatch = numericDatePattern.firstMatch(str);
      if (numMatch != null) {
        try {
          final p1 = int.parse(numMatch.group(1)!);
          final p2 = int.parse(numMatch.group(2)!);
          final rawYear = int.parse(numMatch.group(3)!);
          final year = rawYear < 100 ? rawYear + 2000 : rawYear;

          int day;
          int month;

          if (p1 <= 12 && p2 > 12) {
            // Unmistakably US: MM/DD/YYYY (e.g. 10/25/2026)
            month = p1;
            day = p2;
          } else if (p1 > 12 && p2 <= 12) {
            // Unmistakably European: DD/MM/YYYY (e.g. 25/10/2026)
            day = p1;
            month = p2;
          } else {
            // Ambiguous (both <= 12): rely on context
            if (isUsContext) {
              month = p1;
              day = p2;
            } else {
              day = p1;
              month = p2;
            }
          }

          if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 2000 && year <= 2099) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }

      return null;
    }

    // Multilingual Due Date / Expiry Keywords
    const dueDateKeywords = [
      // English (US, UK, Global)
      'PAYMENT DUE DATE',
      'PAYMENT DUE',
      'DUE DATE',
      'PAY BY DATE',
      'PAY BY',
      'DUE BY',
      'PAY BEFORE',
      'DUE ON',
      'EXPIRATION DATE',
      'EXPIRY DATE',
      'EXPIRES ON',
      'VALID UNTIL',
      'VALID THRU',
      'VALID THROUGH',
      'RENEWAL DATE',

      // German
      'FAELLIG AM',
      'FAELLIGKEITSDATUM',
      'ZAHLBAR BIS',
      'ZAHLUNGSZIEL',
      'GUELTIG BIS',
      'ABLAUFDATUM',

      // French
      'DATE LIMITE DE PAIEMENT',
      'DATE D\'ECHEANCE',
      'ECHEANCE',
      'A PAYER AVANT LE',
      'DATE D\'EXPIRATION',
      'VALABLE JUSQU\'AU',

      // Spanish
      'FECHA DE VENCIMIENTO',
      'FECHA LIMITE DE PAGO',
      'PAGAR ANTES DE',
      'FECHA DE CADUCIDAD',
      'VENCE EL',
      'VENCE',

      // Italian
      'DATA DI SCADENZA',
      'SCADENZA FATTURA',
      'PAGARE ENTRO IL',
      'PAGARE ENTRO',
      'SCADENZA',

      // Romanian
      'DATA SCADENTA',
      'DATA SCADENTEI',
      'SCADENT LA',
      'TERMEN LIMITA',
      'TERMEN DE PLATA',
      'DATA LIMITA',
    ];

    // 1. Check lines matching due date keywords first
    for (final kw in dueDateKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final upperLine = lines[i].toUpperCase();
        if (upperLine.contains(kw)) {
          final d = parseDateString(lines[i]) ??
              (i + 1 < lines.length ? parseDateString(lines[i + 1]) : null);
          if (d != null) return d;
        }
      }
    }

    // 2. Collect all dates found in text
    final List<DateTime> dates = [];
    for (final line in lines) {
      final d = parseDateString(line);
      if (d != null) dates.add(d);
    }

    if (dates.isEmpty) return null;

    final now = DateTime.now();

    if (preferFuture) {
      final futureDates = dates.where((d) => d.isAfter(now)).toList();
      if (futureDates.isNotEmpty) {
        futureDates.sort();
        return futureDates.last;
      }
    }

    if (isReceipt) {
      // For receipts, use the receipt transaction date (most recent or today)
      dates.sort();
      return dates.last;
    }

    // Default: find future date if available, else most recent
    final futureDates = dates.where((d) => d.isAfter(now.subtract(const Duration(days: 1)))).toList();
    if (futureDates.isNotEmpty) {
      futureDates.sort();
      return futureDates.first; // nearest upcoming due date
    }

    dates.sort();
    return dates.last;
  }

  static String? _extractTitle(String text) {
    final upperText = text.toUpperCase();

    // Global, US, UK, European, and Regional utilities, services, retailers
    final Map<String, List<String>> keywords = {
      // US Utilities & Telecoms
      'AT&T': ['AT&T', 'ATT BILL'],
      'Verizon': ['VERIZON'],
      'T-Mobile': ['T-MOBILE', 'TMOBILE'],
      'Xfinity / Comcast': ['COMCAST', 'XFINITY'],
      'Spectrum / Charter': ['SPECTRUM', 'CHARTER COMMUNICATIONS'],
      'Cox': ['COX COMMUNICATIONS'],
      'ConEdison': ['CONEDISON', 'CON EDISON'],
      'PG&E': ['PG&E', 'PACIFIC GAS AND ELECTRIC'],
      'Duke Energy': ['DUKE ENERGY'],
      'FPL': ['FLORIDA POWER & LIGHT', 'FPL'],
      'National Grid': ['NATIONAL GRID'],
      'Southern California Edison': ['SOUTHERN CALIFORNIA EDISON', 'SCE'],

      // UK Utilities & Telecoms
      'British Gas': ['BRITISH GAS'],
      'EDF Energy': ['EDF ENERGY'],
      'Octopus Energy': ['OCTOPUS ENERGY'],
      'BT': ['BRITISH TELECOM', 'BT GROUP'],
      'EE': ['EE LIMITED', 'EVERYTHING EVERYWHERE'],
      'O2': ['O2 UK', 'TELEFONICA UK'],
      'Three': ['THREE UK', 'HUTCHISON 3G'],
      'Sky': ['SKY UK', 'SKY BROADBAND'],
      'Virgin Media': ['VIRGIN MEDIA', 'VIRGIN BROADBAND'],
      'Thames Water': ['THAMES WATER'],
      'Scottish Power': ['SCOTTISH POWER', 'SCOTTISHPOWER'],
      'Council Tax': ['COUNCIL TAX'],

      // US & UK Major Retailers
      'Walmart': ['WALMART', 'WAL-MART'],
      'Target': ['TARGET STORES'],
      'Costco': ['COSTCO WHOLESALE', 'COSTCO'],
      'Amazon': ['AMAZON.COM', 'AMAZON.CO.UK', 'AMAZON EU', 'AMAZON PRIME'],
      'Home Depot': ['HOME DEPOT'],
      'Best Buy': ['BEST BUY'],
      'CVS': ['CVS PHARMACY', 'CVS/PHARMACY'],
      'Walgreens': ['WALGREENS'],
      'Tesco': ['TESCO STORES', 'TESCO'],
      'Sainsbury\'s': ['SAINSBURY', 'SAINSBURY\'S'],
      'Asda': ['ASDA STORES', 'ASDA'],
      'Morrisons': ['MORRISONS'],
      'Marks & Spencer': ['MARKS & SPENCER', 'M&S'],
      'Waitrose': ['WAITROSE'],
      'Aldi': ['ALDI STORES', 'ALDI'],
      'Boots': ['BOOTS UK', 'BOOTS THE CHEMIST'],
      'Argos': ['ARGOS'],
      'Currys': ['CURRYS', 'PC WORLD'],

      // European Retailers & Utilities
      'Carrefour': ['CARREFOUR'],
      'Lidl': ['LIDL'],
      'Mercadona': ['MERCADONA'],
      'E.Leclerc': ['E.LECLERC', 'LECLERC'],
      'MediaMarkt': ['MEDIAMARKT', 'MEDIA MARKT', 'SATURN'],
      'Fnac': ['FNAC'],
      'El Corte Ingles': ['EL CORTE INGLES'],
      'Ikea': ['IKEA'],
      'Decathlon': ['DECATHLON'],
      'Leroy Merlin': ['LEROY MERLIN'],
      'Hornbach': ['HORNBACH'],
      'Bauhaus': ['BAUHAUS'],
      'Rewe': ['REWE'],
      'Edeka': ['EDEKA'],

      // Romanian Utilities & Telecoms
      'Hidroelectrica': ['HIDROELECTRICA'],
      'Electrica Furnizare': ['ELECTRICA FURNIZARE', 'ELECTRICA'],
      'Enel / PPC': ['ENEL', 'PPC ENERGY'],
      'E.ON': ['E.ON', 'EON ENERGIE'],
      'Engie': ['ENGIE'],
      'Digi (RCS & RDS)': ['DIGI', 'RCS & RDS', 'RCS-RDS'],
      'Orange': ['ORANGE ROMANIA', 'ORANGE'],
      'Vodafone': ['VODAFONE ROMANIA', 'VODAFONE'],
      'Telekom': ['TELEKOM'],
      'Apa Nova': ['APA NOVA'],
      'Apavital': ['APAVITAL'],
      'Raja': ['RAJA'],

      // Romanian Retail & Gas
      'Kaufland': ['KAUFLAND'],
      'Mega Image': ['MEGA IMAGE'],
      'Auchan': ['AUCHAN'],
      'Profi': ['PROFI'],
      'Penny': ['PENNY'],
      'Altex': ['ALTEX', 'MEDIA GALAXY'],
      'eMAG': ['EMAG', 'DANTE INTERNATIONAL'],
      'Dedeman': ['DEDEMAN'],
      'OMV': ['OMV'],
      'Petrom': ['PETROM'],
      'Rompetrol': ['ROMPETROL'],
      'Mol': ['MOL ROMANIA'],

      // Global Digital Subscriptions
      'Netflix': ['NETFLIX'],
      'Spotify': ['SPOTIFY'],
      'Apple': ['APPLE.COM/BILL', 'ITUNES.COM/BILL', 'APPLE SERVICES'],
      'Google': ['GOOGLE PLAY', 'GOOGLE STORAGE', 'GOOGLE WORKSPACE', 'YOUTUBE PREMIUM'],
      'Microsoft': ['MICROSOFT 365', 'MICROSOFT*STORE', 'XBOX'],
      'Disney+': ['DISNEY PLUS', 'DISNEY+'],
      'Adobe': ['ADOBE SYSTEMS', 'ADOBE CREATIVE'],
      'ChatGPT / OpenAI': ['OPENAI', 'CHATGPT'],
      'Uber': ['UBER TRIP', 'UBER EATS', 'UBER *'],

      // Documents (Multilingual)
      'Passport': ['PASAPORT', 'PASSPORT', 'REPUBLICA ROMANIA', 'PASSEPORT', 'REISEPASS', 'PASAPORTE'],
      'ID Card': ['CARTE IDENTITATE', 'IDENTITY CARD', 'NATIONAL ID', 'CITIZEN CARD', 'PERSONALAUSWEIS', 'CARTE NATIONALE D\'IDENTITE', 'DOCUMENTO NACIONAL DE IDENTIDAD', 'CNP', 'BULLETIN'],
      'Driver License': ['PERMIS CONDUCERE', 'DRIVING LICENCE', 'DRIVER LICENSE', 'FUEHRERSCHEIN', 'PERMIS DE CONDUIRE', 'PERMISO DE CONDUCCION'],
      'Health Card': ['CARD SANATATE', 'HEALTH CARD', 'HEALTH INSURANCE', 'CARTE VITALE', 'KRANKENKASSE', 'TARJETA SANITARIA'],
      'Vehicle Registration': ['CERTIFICAT INMATRICULARE', 'TALON AUTO', 'V5C', 'FAHRZEUGSCHEIN', 'CARTE GRISE', 'PERMISO DE CIRCULACION'],
      'Insurance Policy': ['POLITA ASIGURARE', 'INSURANCE POLICY', 'VERSICHERUNGSSCHEIN', 'POLIZZA', 'POLIZA DE SEGURO'],
      'Contract': ['CONTRACT', 'CONVENTIE', 'AGREEMENT', 'VERTRAG'],
    };

    for (var entry in keywords.entries) {
      for (var word in entry.value) {
        if (upperText.contains(word)) {
          return entry.key;
        }
      }
    }

    return null;
  }
}
