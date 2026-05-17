// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_harbor_suppression.dart';

class HarborResult {
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

class HarborCallResult<T> {
  const HarborCallResult({required this.value, this.result});
  final T value;
  final HarborResult? result;
}

Future<T> tracedHarbor<T>({
  required String operation,
  required Future<HarborCallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (harborInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_harbor');
  final span = t.startSpan('harbor $operation', kind: SpanKind.client);
  try {
    span.setStringAttribute('rpc.system', 'harbor');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.project != null) {
        span.setStringAttribute('harbor.project', res.project!);
      }
      if (res.repository != null) {
        span.setStringAttribute('harbor.repository', res.repository!);
      }
      if (res.imageDigest != null) {
        span.setStringAttribute('container.image.id', res.imageDigest!);
      }
      if (res.imageTag != null) {
        span.setStringAttribute('container.image.tag', res.imageTag!);
      }
      if (res.imageSize != null) {
        span.setIntAttribute('container.image.size', res.imageSize!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('harbor.error.code', res.errorCode!);
      }
      final fail =
          res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
          ErrorResource.errorType.key,
          res.errorCode ?? 'harbor.error',
        );
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
