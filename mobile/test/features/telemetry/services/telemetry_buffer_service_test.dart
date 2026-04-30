import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ruedaseguro/features/telemetry/services/telemetry_buffer_service.dart';

void main() {
  setUpAll(() {
    // Use the FFI SQLite implementation so tests run without native plugins.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Reset buffer state before each test.
    await TelemetryBufferService.instance.init();
    await TelemetryBufferService.instance.clear();
  });

  // ─── Empty buffer ─────────────────────────────────────────────────

  group('empty buffer', () {
    test('sampleCount is 0', () async {
      expect(await TelemetryBufferService.instance.sampleCount, 0);
    });

    test('getWindow returns empty list', () async {
      final samples = await TelemetryBufferService.instance.getWindow();
      expect(samples, isEmpty);
    });

    test('peakGForce returns null', () async {
      expect(await TelemetryBufferService.instance.peakGForce, isNull);
    });

    test('pruneOlderThan on empty buffer does not throw', () async {
      await expectLater(
        TelemetryBufferService.instance.pruneOlderThan(
          const Duration(minutes: 15),
        ),
        completes,
      );
    });
  });

  // ─── Insert ───────────────────────────────────────────────────────

  group('insert', () {
    test('sampleCount increments after each insert', () async {
      await TelemetryBufferService.instance.insertSample(gForce: 1.0);
      expect(await TelemetryBufferService.instance.sampleCount, 1);

      await TelemetryBufferService.instance.insertSample(gForce: 2.0);
      expect(await TelemetryBufferService.instance.sampleCount, 2);
    });

    test('getWindow returns inserted samples', () async {
      await TelemetryBufferService.instance.insertSample(
        gForce: 1.5,
        latitude: 10.0,
        longitude: -67.0,
        speedKmh: 40.0,
      );

      final samples = await TelemetryBufferService.instance.getWindow(
        const Duration(minutes: 15),
      );

      expect(samples, hasLength(1));
      expect(samples.first.gForce, 1.5);
      expect(samples.first.latitude, 10.0);
      expect(samples.first.longitude, -67.0);
      expect(samples.first.speedKmh, 40.0);
    });

    test(
      'samples with null fields are stored and retrieved correctly',
      () async {
        await TelemetryBufferService.instance.insertSample();
        final samples = await TelemetryBufferService.instance.getWindow();

        expect(samples, hasLength(1));
        expect(samples.first.gForce, isNull);
        expect(samples.first.latitude, isNull);
      },
    );

    test('samples are returned in ascending recordedAt order', () async {
      for (int i = 0; i < 5; i++) {
        await TelemetryBufferService.instance.insertSample(
          gForce: i.toDouble(),
        );
        // Small delay to ensure distinct timestamps.
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      final samples = await TelemetryBufferService.instance.getWindow();
      expect(samples, hasLength(5));

      for (int i = 0; i < samples.length - 1; i++) {
        expect(
          samples[i].recordedAt.isBefore(samples[i + 1].recordedAt) ||
              samples[i].recordedAt.isAtSameMomentAs(samples[i + 1].recordedAt),
          isTrue,
          reason: 'Samples must be sorted by recordedAt ASC',
        );
      }
    });
  });

  // ─── peakGForce ───────────────────────────────────────────────────

  group('peakGForce', () {
    test('returns the maximum G-force across all samples', () async {
      await TelemetryBufferService.instance.insertSample(gForce: 1.2);
      await TelemetryBufferService.instance.insertSample(gForce: 4.8);
      await TelemetryBufferService.instance.insertSample(gForce: 3.1);

      expect(
        await TelemetryBufferService.instance.peakGForce,
        closeTo(4.8, 0.001),
      );
    });

    test('ignores samples with null gForce', () async {
      await TelemetryBufferService.instance.insertSample(gForce: null);
      await TelemetryBufferService.instance.insertSample(gForce: 2.5);

      expect(
        await TelemetryBufferService.instance.peakGForce,
        closeTo(2.5, 0.001),
      );
    });

    test('returns null when all gForce values are null', () async {
      await TelemetryBufferService.instance.insertSample(gForce: null);
      await TelemetryBufferService.instance.insertSample(gForce: null);

      expect(await TelemetryBufferService.instance.peakGForce, isNull);
    });
  });

  // ─── getWindow ────────────────────────────────────────────────────

  group('getWindow', () {
    test(
      'a very short window excludes samples inserted slightly before',
      () async {
        await TelemetryBufferService.instance.insertSample(gForce: 1.0);
        // Sleep so the sample's recordedAt is now in the "past" relative to cutoff.
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // 1 ms window — only samples within the last millisecond qualify.
        final samples = await TelemetryBufferService.instance.getWindow(
          const Duration(milliseconds: 1),
        );

        expect(samples, isEmpty);
      },
    );

    test('a wide window includes all samples', () async {
      for (int i = 0; i < 3; i++) {
        await TelemetryBufferService.instance.insertSample(
          gForce: i.toDouble(),
        );
      }

      final samples = await TelemetryBufferService.instance.getWindow(
        const Duration(days: 365),
      );

      expect(samples, hasLength(3));
    });
  });

  // ─── pruneOlderThan ───────────────────────────────────────────────

  group('pruneOlderThan', () {
    test('does not prune recent samples', () async {
      await TelemetryBufferService.instance.insertSample(gForce: 1.0);
      await TelemetryBufferService.instance.insertSample(gForce: 2.0);

      // Prune only things older than 1 year — nothing should go.
      await TelemetryBufferService.instance.pruneOlderThan(
        const Duration(days: 365),
      );

      expect(await TelemetryBufferService.instance.sampleCount, 2);
    });

    test('prunes samples older than the given window', () async {
      await TelemetryBufferService.instance.insertSample(gForce: 1.0);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // 1 ms max age — the sample (30 ms old) must be pruned.
      await TelemetryBufferService.instance.pruneOlderThan(
        const Duration(milliseconds: 1),
      );

      expect(await TelemetryBufferService.instance.sampleCount, 0);
    });
  });

  // ─── clear ───────────────────────────────────────────────────────

  group('clear', () {
    test('empties the buffer completely', () async {
      await TelemetryBufferService.instance.insertSample(gForce: 1.0);
      await TelemetryBufferService.instance.insertSample(gForce: 2.0);
      await TelemetryBufferService.instance.insertSample(gForce: 3.0);

      await TelemetryBufferService.instance.clear();

      expect(await TelemetryBufferService.instance.sampleCount, 0);
      expect(await TelemetryBufferService.instance.getWindow(), isEmpty);
      expect(await TelemetryBufferService.instance.peakGForce, isNull);
    });

    test('allows fresh inserts after clearing', () async {
      await TelemetryBufferService.instance.insertSample(gForce: 9.9);
      await TelemetryBufferService.instance.clear();
      await TelemetryBufferService.instance.insertSample(gForce: 0.5);

      expect(await TelemetryBufferService.instance.sampleCount, 1);
      expect(
        await TelemetryBufferService.instance.peakGForce,
        closeTo(0.5, 0.001),
      );
    });
  });

  // ─── TelemetrySample serialization ───────────────────────────────

  group('TelemetrySample.fromMap', () {
    test('roundtrips all fields through toMap/fromMap', () {
      final original = TelemetrySample(
        id: 42,
        recordedAt: DateTime.utc(2026, 3, 29, 12, 0, 0),
        gForce: 2.4,
        latitude: 10.4806,
        longitude: -66.9036,
        altitudeM: 900.5,
        speedKmh: 55.0,
      );

      final roundtripped = TelemetrySample.fromMap(original.toMap());

      expect(roundtripped.id, original.id);
      expect(
        roundtripped.recordedAt.isAtSameMomentAs(original.recordedAt),
        isTrue,
      );
      expect(roundtripped.gForce, original.gForce);
      expect(roundtripped.latitude, original.latitude);
      expect(roundtripped.longitude, original.longitude);
      expect(roundtripped.altitudeM, original.altitudeM);
      expect(roundtripped.speedKmh, original.speedKmh);
    });

    test('handles all-null optional fields', () {
      final sample = TelemetrySample(id: 1, recordedAt: DateTime.now());

      final roundtripped = TelemetrySample.fromMap(sample.toMap());

      expect(roundtripped.gForce, isNull);
      expect(roundtripped.latitude, isNull);
      expect(roundtripped.longitude, isNull);
      expect(roundtripped.altitudeM, isNull);
      expect(roundtripped.speedKmh, isNull);
    });
  });
}
