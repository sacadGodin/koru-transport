import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koru_website/data/bookings.dart';
import 'package:koru_website/widgets/route_map.dart';
import 'package:latlong2/latlong.dart';

Widget _app(LatLng destination, LatLng? pickup) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          child: RouteMap(
              destination: destination,
              pickup: pickup,
              onPickupChanged: (_) {}),
        ),
      ),
    );

void main() {
  // Pickup and destination on the same spot (Koru Hotel -> Koru Hotel) used
  // to make the map zoom in endlessly and freeze the booking form.
  testWidgets('map survives pickup and destination on the same spot',
      (t) async {
    final hotel = branchLocation(hotelName);
    await t.pumpWidget(_app(branchLocation(branches.first), hotel));
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpWidget(_app(hotel, hotel));
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpWidget(_app(branchLocation(branches[1]), hotel));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.takeException(), isNull);
  });
}
