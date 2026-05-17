# otel_harbor

Dartastic OpenTelemetry bridge for Harbor (self-hosted container registry).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_harbor/otel_harbor.dart';

await tracedHarbor<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return HarborCallResult(value: r, result: HarborResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutHarborInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
