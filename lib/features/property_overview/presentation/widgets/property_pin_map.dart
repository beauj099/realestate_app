import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/themes.dart';

/// A map under the address search with the property's pin. Tapping the map
/// moves the pin onto the house: the pin is the listing's location, which is
/// what the valuation report, nearby sales and homes for sale are matched by
/// (suburb names differ between sources; a location does not).
class PropertyPinMap extends StatefulWidget {
  final RealEstateTheme theme;
  final double? lat;
  final double? lng;
  final ValueChanged<LatLng> onPlacePin;
  final bool busy;

  const PropertyPinMap({
    super.key,
    required this.theme,
    required this.lat,
    required this.lng,
    required this.onPlacePin,
    this.busy = false,
  });

  @override
  State<PropertyPinMap> createState() => _PropertyPinMapState();
}

class _PropertyPinMapState extends State<PropertyPinMap> {
  /// Cape Town, zoomed out, until there is a pin.
  static const _start = LatLng(-33.95, 18.60);
  static const _houseZoom = 18.0;

  final _map = MapController();
  bool _ready = false;

  LatLng? get _pin => widget.lat != null && widget.lng != null
      ? LatLng(widget.lat!, widget.lng!)
      : null;

  @override
  void didUpdateWidget(covariant PropertyPinMap old) {
    super.didUpdateWidget(old);
    final pin = _pin;
    if (_ready &&
        pin != null &&
        (old.lat != widget.lat || old.lng != widget.lng)) {
      _map.move(pin, _map.camera.zoom < 16 ? _houseZoom : _map.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final pin = _pin;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: theme.borderLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: pin ?? _start,
                initialZoom: pin == null ? 10 : _houseZoom,
                onMapReady: () => _ready = true,
                onTap: (_, point) => widget.onPlacePin(point),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.realworth.app',
                  maxZoom: 19,
                ),
                if (pin != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pin,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          Icons.location_on,
                          size: 44,
                          color: theme.primaryColor,
                          shadows: const [
                            Shadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                // The map tiles' licence asks for credit on the map itself;
                // this keeps it to a small (i) that opens on tap.
                const RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [TextSourceAttribution('OpenStreetMap')],
                ),
              ],
            ),
            Positioned(
              left: 10,
              top: 10,
              right: 56,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.busy) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.busy
                              ? 'Finding the address…'
                              : pin == null
                              ? 'Tap the house to place the pin'
                              : 'Not quite right? Tap the house',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
