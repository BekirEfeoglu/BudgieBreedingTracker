import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/export/excel_export_service.dart';

void main() {
  late ExcelExportService service;

  setUp(() {
    service = ExcelExportService();
  });

  group('ExcelExportService.sanitize', () {
    group('formula injection prevention', () {
      test('prefixes = with single quote', () {
        expect(service.sanitize('=CMD()'), "'=CMD()");
      });

      test('prefixes + with single quote', () {
        expect(service.sanitize('+1234'), "'+1234");
      });

      test('prefixes @ with single quote', () {
        expect(service.sanitize('@SUM(A1)'), "'@SUM(A1)");
      });

      test('prefixes | with single quote', () {
        expect(service.sanitize('|calc'), "'|calc");
      });

      test('prefixes tab with single quote', () {
        expect(service.sanitize('\tdata'), "'\tdata");
      });

      test('prefixes carriage return with single quote', () {
        expect(service.sanitize('\rdata'), "'\rdata");
      });

      test('prefixes newline with single quote', () {
        expect(service.sanitize('\ndata'), "'\ndata");
      });

      test('prefixes - followed by letter with single quote', () {
        expect(service.sanitize('-CMD'), "'-CMD");
      });

      test('prefixes - alone with single quote', () {
        expect(service.sanitize('-'), "'-");
      });
    });

    group('negative numbers pass through', () {
      test('allows negative integer', () {
        expect(service.sanitize('-5'), '-5');
      });

      test('allows negative decimal', () {
        expect(service.sanitize('-5.2'), '-5.2');
      });

      test('allows negative with leading dot', () {
        expect(service.sanitize('-.5'), '-.5');
      });

      test('allows negative zero', () {
        expect(service.sanitize('-0'), '-0');
      });

      test('allows negative large number', () {
        expect(service.sanitize('-12345.678'), '-12345.678');
      });
    });

    group('normal values pass through', () {
      test('returns empty string unchanged', () {
        expect(service.sanitize(''), '');
      });

      test('returns normal text unchanged', () {
        expect(service.sanitize('Mavi'), 'Mavi');
      });

      test('returns text with spaces unchanged', () {
        expect(service.sanitize('Muhabbet Kuşu'), 'Muhabbet Kuşu');
      });

      test('returns numeric string unchanged', () {
        expect(service.sanitize('42'), '42');
      });

      test('returns date string unchanged', () {
        expect(service.sanitize('2026-03-31'), '2026-03-31');
      });

      test('returns text with internal special chars unchanged', () {
        expect(service.sanitize('bird=male'), 'bird=male');
      });
    });
  });
}
