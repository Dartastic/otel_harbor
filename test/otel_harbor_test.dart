// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_harbor/otel_harbor.dart';
import 'package:test/test.dart';

void main() {
  group('otel_harbor', () {
    test('suppression toggles in zone', () async {
      expect(harborInstrumentationSuppressed(), isFalse);
      await runWithoutHarborInstrumentationAsync(() async {
        expect(harborInstrumentationSuppressed(), isTrue);
      });
      expect(harborInstrumentationSuppressed(), isFalse);
    });

    test('HarborResult fields default null', () {
      const r = HarborResult();
      expect(r.statusCode, isNull);
    });
  });
}
