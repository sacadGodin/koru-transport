import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lang.dart';
import '../theme.dart';

// Map showing the trip: a green pin at the pickup point, a blue pin at the
// destination and a line between them. Tapping the map moves the pickup pin.
// When [driver] is set, a car shows where the driver is now.
// Uses free OpenStreetMap tiles (no API key needed).
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.destination,
    this.pickup,
    this.onPickupChanged,
    this.driver,
    this.height = 320,
  });

  final LatLng destination;
  final LatLng? pickup;
  // Called with the tapped point (null = the map is read-only).
  final ValueChanged<LatLng>? onPickupChanged;
  // Live driver position (null = not shown).
  final LatLng? driver;
  final double height;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final _controller = MapController();

  // Points the camera should show: every pin, or just the destination.
  List<LatLng> get _points => [
        if (widget.pickup != null) widget.pickup!,
        if (widget.driver != null) widget.driver!,
        widget.destination,
      ];

  @override
  void didUpdateWidget(RouteMap old) {
    super.didUpdateWidget(old);
    // A new destination was chosen: move the camera to show the whole trip.
    // The driver appeared on the map: also show the whole trip.
    if (old.destination != widget.destination ||
        (old.driver == null) != (widget.driver == null)) {
      _fit();
    }
  }

  void _fit() {
    if (_points.length == 1) {
      _controller.move(widget.destination, 13);
    } else {
      _controller.fitCamera(CameraFit.coordinates(
          coordinates: _points, padding: const EdgeInsets.all(56)));
    }
  }

  // One pin icon standing on its point.
  Marker _pin(LatLng point, Color color, IconData icon) => Marker(
        point: point,
        width: 44,
        height: 44,
        alignment: Alignment.topCenter,
        child: Icon(icon, size: 44, color: color),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.destination,
            initialZoom: 13,
            initialCameraFit: _points.length > 1
                ? CameraFit.coordinates(
                    coordinates: _points, padding: const EdgeInsets.all(56))
                : null,
            onTap: widget.onPickupChanged == null
                ? null
                : (_, point) => widget.onPickupChanged!(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.koru.koru_website',
            ),
            // Straight line from pickup to destination.
            if (widget.pickup != null)
              PolylineLayer(polylines: [
                Polyline(
                  points: [widget.pickup!, widget.destination],
                  color: AppColors.blue,
                  strokeWidth: 4,
                  pattern: StrokePattern.dashed(segments: const [12, 8]),
                ),
              ]),
            MarkerLayer(markers: [
              _pin(
                  widget.destination, AppColors.blueDark, Icons.local_hospital),
              if (widget.pickup != null)
                _pin(widget.pickup!, AppColors.success, Icons.location_on),
              // The driver's car: a round white badge so it stands out.
              if (widget.driver != null)
                Marker(
                  point: widget.driver!,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.blue, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Icon(Icons.directions_car,
                        size: 24, color: AppColors.blue),
                  ),
                ),
            ]),
            // Hint shown until the patient taps a pickup point.
            if (widget.pickup == null && widget.onPickupChanged != null)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                  child: Text(
                      context.t('Tap the map to set your pickup point',
                          'Alınış noktanızı seçmek için haritaya dokunun'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            // OpenStreetMap credit (required by its terms of use).
            RichAttributionWidget(attributions: [
              TextSourceAttribution('OpenStreetMap contributors',
                  onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'))),
            ]),
          ],
        ),
      ),
    );
  }
}
