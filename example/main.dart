// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_harbor/otel_harbor.dart';

/// Traces Harbor calls with OpenTelemetry.
///
/// `otel_harbor` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Harbor call in
/// [tracedHarbor]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'harbor-example');

  // Traces a Harbor call.
  final harborId = await tracedHarbor<String>(
    operation: 'create',
    invoke: () async {
      // Make the Harbor call here, then report what it returned.
      const id = 'harbor_8f3a2c';
      return const HarborCallResult(
          value: id,
          result: HarborResult(
              project: 'example',
              repository: 'example',
              imageDigest: 'example',
              imageTag: 'example',
              imageSize: 512,
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedHarbor create returned $harborId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutHarborInstrumentationAsync.
  await runWithoutHarborInstrumentationAsync(
    () => tracedHarbor<String>(
      operation: 'create',
      invoke: () async {
        const id = 'harbor_8f3a2c';
        return const HarborCallResult(
            value: id,
            result: HarborResult(
                project: 'example',
                repository: 'example',
                imageDigest: 'example',
                imageTag: 'example',
                imageSize: 512,
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
