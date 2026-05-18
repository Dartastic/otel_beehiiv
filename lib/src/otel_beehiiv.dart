// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_beehiiv_suppression.dart';

const _tracerName = 'dartastic_otel_libs_beehiiv';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class BeehiivResult {
  const BeehiivResult({
    this.publicationId,
    this.itemCount,
    this.totalResults,
    this.subscriptionTier,
    this.subscriptionStatus,
    this.postStatus,
    this.postAudience,
    this.referringSiteCount,
    this.adPlacementCpm,
    this.requestId,
    this.statusCode,
  });

  /// Publication id.
  final String? publicationId;

  /// Items returned.
  final int? itemCount;

  /// `total_results`.
  final int? totalResults;

  /// `free` / `premium` — subscriber tier.
  final String? subscriptionTier;

  /// `active` / `pending` / `inactive` / `needs_attention`.
  final String? subscriptionStatus;

  /// `draft` / `confirmed` / `archived` for posts.
  final String? postStatus;

  /// `free` / `premium` / `all` — audience scope of post.
  final String? postAudience;

  /// Number of unique referring sites attributed (acquisition signal).
  final int? referringSiteCount;

  /// Ad placement CPM in minor units (publisher revenue dim).
  final int? adPlacementCpm;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class BeehiivCallResult<T> {
  const BeehiivCallResult({required this.value, this.result});
  final T value;
  final BeehiivResult? result;
}

/// Wraps a Beehiiv API call in a CLIENT span. [operation] is one of
/// `publications.list`, `publications.get`, `subscriptions.list`,
/// `subscriptions.create`, `subscriptions.update`, `subscriptions.bulk`,
/// `posts.list`, `posts.get`, `posts.create`, `posts.send`,
/// `segments.list`, `custom_fields.list`, `ad_placements.list`,
/// `automations.list`, `automations.subscribers.enroll`,
/// `referral_program.list`, `webhooks.create`.
Future<T> tracedBeehiiv<T>({
  required String operation,
  required Future<BeehiivCallResult<T>> Function() invoke,
  String? publicationId,
}) async {
  if (beehiivInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'beehiiv',
    'rpc.method': operation,
    'beehiiv.operation': operation,
  };
  if (publicationId != null) m['beehiiv.publication.id'] = publicationId;

  final span = _tracer().startSpan(
    'beehiiv $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.publicationId != null) {
        extras.add(OTel.attributeString(
          'beehiiv.publication.id',
          r.result!.publicationId!,
        ));
      }
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'beehiiv.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalResults != null) {
        extras.add(OTel.attributeInt(
          'beehiiv.total_results',
          r.result!.totalResults!,
        ));
      }
      if (r.result!.subscriptionTier != null) {
        extras.add(OTel.attributeString(
          'beehiiv.subscription.tier',
          r.result!.subscriptionTier!,
        ));
      }
      if (r.result!.subscriptionStatus != null) {
        extras.add(OTel.attributeString(
          'beehiiv.subscription.status',
          r.result!.subscriptionStatus!,
        ));
      }
      if (r.result!.postStatus != null) {
        extras.add(OTel.attributeString(
          'beehiiv.post.status',
          r.result!.postStatus!,
        ));
      }
      if (r.result!.postAudience != null) {
        extras.add(OTel.attributeString(
          'beehiiv.post.audience',
          r.result!.postAudience!,
        ));
      }
      if (r.result!.referringSiteCount != null) {
        extras.add(OTel.attributeInt(
          'beehiiv.referring_site_count',
          r.result!.referringSiteCount!,
        ));
      }
      if (r.result!.adPlacementCpm != null) {
        extras.add(OTel.attributeInt(
          'beehiiv.ad_placement.cpm.minor',
          r.result!.adPlacementCpm!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'beehiiv.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Beehiiv HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
