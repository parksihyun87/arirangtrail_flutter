import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StaticFestivalMap extends StatelessWidget {
  final LatLng location;
  final Set<Marker> markers;

  const StaticFestivalMap({
    super.key,
    required this.location,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 200,
        child: GoogleMap(
          key: const ValueKey('staticFestivalMap'),
          initialCameraPosition: CameraPosition(target: location, zoom: 15),
          markers: markers,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          liteModeEnabled: true,
        ));
  }
}
