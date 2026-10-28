// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_harbor_suppression.dart';

class HarborResult {
  /// Creates a result.
  const HarborResult({
    this.project,
    this.repository,
    this.imageDigest,
    this.imageTag,
    this.imageSize,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? project;
  final String? repository;
  final String? imageDigest;
  final String? imageTag;
  final int? imageSize;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class HarborCallResult<T> {
  /// Creates a call result.
  const HarborCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final HarborResult? result;
}

Future<T> tracedHarbor<T>({
  required String operation,
  required Future<HarborCallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (harborInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_harbor');
  final span = t.startSpan('harbor $operation', kind: SpanKind.client);
  try {
    span.addAttributes(
        OTelAPI.attributes([OTelAPI.attributeString('rpc.system', 'harbor')]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.project != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('harbor.project', res.project!)]));
      }
      if (res.repository != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('harbor.repository', res.repository!)]));
      }
      if (res.imageDigest != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('container.image.id', res.imageDigest!)]));
      }
      if (res.imageTag != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('container.image.tag', res.imageTag!)]));
      }
      if (res.imageSize != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeInt('container.image.size', res.imageSize!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('harbor.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            ErrorAttributes.errorType.key,
            res.errorCode ?? 'harbor.error',
          )
        ]));
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
