import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koru_website/data/bookings.dart';
import 'package:koru_website/data/tracking.dart';
import 'package:koru_website/pages/track_page.dart';

TrackingInfo info(Stage stage, [TripStatus? trip]) => TrackingInfo(
      ref: 'KR-1001',
      type: TransportType.values.first,
      branch: '',
      date: DateTime(2026, 11, 24),
      time: const TimeOfDay(hour: 10, minute: 0),
      stage: stage,
      trip: trip,
    );

void main() {
  test('each stage shows its own step', () {
    expect(progressStep(info(Stage.newRequest)), 0);
    expect(progressStep(info(Stage.confirmed)), 1);
    expect(progressStep(info(Stage.reserved)), 2);
    expect(progressStep(info(Stage.arranged)), 3);
  });

  test('each trip status shows its own step, the last one included', () {
    // 3 booking steps, then one per trip status.
    const steps = 3 + 5;
    for (final trip in TripStatus.values) {
      final i = progressStep(info(Stage.arranged, trip));
      expect(i, 3 + trip.index, reason: trip.name);
      expect(i, lessThan(steps), reason: trip.name);
    }
  });
}
