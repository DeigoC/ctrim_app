import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ctrim_app/utility/uk_postcode_lookup.dart';

void main() {
  group('UkPostcodeLookup.classify', () {
    test('detects full postcodes and outcodes', () {
      expect(UkPostcodeLookup.classify('bt9 6ab'), UkPostcodeKind.full);
      expect(UkPostcodeLookup.classify('BT96AB'), UkPostcodeKind.full);
      expect(UkPostcodeLookup.classify('G1 1AA'), UkPostcodeKind.full);
      expect(UkPostcodeLookup.classify('BT9'), UkPostcodeKind.outcode);
      expect(UkPostcodeLookup.classify('BT37'), UkPostcodeKind.outcode);
      expect(UkPostcodeLookup.classify('bt12'), UkPostcodeKind.outcode);
      expect(UkPostcodeLookup.classify('East Side'), UkPostcodeKind.none);
      expect(UkPostcodeLookup.classify(''), UkPostcodeKind.none);
    });
  });

  group('UkPostcodeLookup.normalize', () {
    test('inserts the inward-code space', () {
      expect(UkPostcodeLookup.normalizeFull('bt96ab'), 'BT9 6AB');
      expect(UkPostcodeLookup.normalizeFull('BT9'), isNull);
      expect(UkPostcodeLookup.normalizeOutcode('bt9'), 'BT9');
      expect(UkPostcodeLookup.normalizeOutcode('BT9 6AB'), isNull);
      expect(UkPostcodeLookup.normalize('bt37'), 'BT37');
      expect(UkPostcodeLookup.normalize('bt37 0ab'), 'BT37 0AB');
    });
  });

  group('UkPostcodeLookup.lookup', () {
    test('requests the full postcode endpoint', () async {
      late Uri requested;
      final lookup = UkPostcodeLookup(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'status': 200,
              'result': {
                'postcode': 'BT9 6AB',
                'latitude': 54.58,
                'longitude': -5.93,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final geo = await lookup.lookup('bt96ab', allowOutcode: false);
      expect(requested.origin, 'https://api.postcodes.io');
      expect(requested.path, '/postcodes/BT9%206AB');
      expect(geo.label, 'BT9 6AB');
      expect(geo.latitude, 54.58);
      expect(geo.longitude, -5.93);
    });

    test('requests the outcode endpoint', () async {
      late Uri requested;
      final lookup = UkPostcodeLookup(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'status': 200,
              'result': {
                'outcode': 'BT9',
                'latitude': 54.58,
                'longitude': -5.93,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final geo = await lookup.lookup('BT9');
      expect(requested.path, '/outcodes/BT9');
      expect(geo.label, 'BT9');
    });

    test('rejects outcodes when allowOutcode is false', () async {
      final lookup = UkPostcodeLookup(
        client: MockClient((_) async => fail('should not hit the network')),
      );
      expect(
        () => lookup.lookup('BT9', allowOutcode: false),
        throwsA(isA<UkPostcodeLookupException>()
            .having((e) => e.isInvalid, 'isInvalid', isTrue)),
      );
    });

    test('maps 404 to invalid', () async {
      final lookup = UkPostcodeLookup(
        client: MockClient(
          (_) async => http.Response('{"status":404}', 404),
        ),
      );
      expect(
        () => lookup.lookup('BT9 6ZZ'),
        throwsA(isA<UkPostcodeLookupException>().having(
          (e) => e.failure,
          'failure',
          UkPostcodeLookupFailure.invalid,
        )),
      );
    });

    test('maps other statuses to failed', () async {
      final lookup = UkPostcodeLookup(
        client: MockClient(
          (_) async => http.Response('nope', 500),
        ),
      );
      expect(
        () => lookup.lookup('BT9 6AB'),
        throwsA(isA<UkPostcodeLookupException>().having(
          (e) => e.failure,
          'failure',
          UkPostcodeLookupFailure.failed,
        )),
      );
    });
  });

  group('UkPostcodeLookup.extractFromAddress', () {
    test('takes the last full postcode, otherwise the last outcode', () {
      expect(
        UkPostcodeLookup.extractFromAddress(
          '123 Somewhere Road\nBelfast\nbt9 6ab',
        ).postcode,
        'BT9 6AB',
      );
      expect(
        UkPostcodeLookup.extractFromAddress('Near BT37').postcode,
        'BT37',
      );
      expect(
        UkPostcodeLookup.extractFromAddress('BT1 1AA then BT9 6AB').postcode,
        'BT9 6AB',
      );
      expect(
        UkPostcodeLookup.extractFromAddress('BT37 and BT9').postcode,
        'BT9',
      );
      expect(
        UkPostcodeLookup.extractFromAddress('was BT9 6AB, now BT37').postcode,
        'BT9 6AB',
      );
      final empty = UkPostcodeLookup.extractFromAddress('Belfast');
      expect(empty.postcode, isNull);
      expect(empty.pending, isFalse);
    });

    test('waits while the inward code is unfinished', () {
      final partial = UkPostcodeLookup.extractFromAddress('High Street\nBT9 6');
      expect(partial.pending, isTrue);
      expect(partial.postcode, isNull);
      expect(
        UkPostcodeLookup.extractFromAddress('BT9 6AB').pending,
        isFalse,
      );
    });
  });
}
