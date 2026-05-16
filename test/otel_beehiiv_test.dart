// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_beehiiv/otel_beehiiv.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_beehiiv-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('posts.send records audience + status', () async {
    await tracedBeehiiv<String>(
      operation: 'posts.send',
      publicationId: 'pub-1',
      invoke: () async => const BeehiivCallResult(
        value: 'ok',
        result: BeehiivResult(
          publicationId: 'pub-1',
          postStatus: 'confirmed',
          postAudience: 'premium',
          adPlacementCpm: 2500,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('beehiiv posts.send')!);
    expect(a['beehiiv.publication.id'], 'pub-1');
    expect(a['beehiiv.post.audience'], 'premium');
    expect(a['beehiiv.ad_placement.cpm.minor'], 2500);
  });

  test('subscriptions.create records tier + status', () async {
    await tracedBeehiiv<String>(
      operation: 'subscriptions.create',
      invoke: () async => const BeehiivCallResult(
        value: 'ok',
        result: BeehiivResult(
          subscriptionTier: 'premium',
          subscriptionStatus: 'active',
          referringSiteCount: 3,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('beehiiv subscriptions.create')!);
    expect(a['beehiiv.subscription.tier'], 'premium');
    expect(a['beehiiv.subscription.status'], 'active');
    expect(a['beehiiv.referring_site_count'], 3);
  });

  test('suppression skips spans', () async {
    await runWithoutBeehiivInstrumentationAsync(() async {
      await tracedBeehiiv<String>(
        operation: 'publications.list',
        invoke: () async => const BeehiivCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('beehiiv '), isEmpty);
  });
}
