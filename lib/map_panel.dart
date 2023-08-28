import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart' as geo;

class MapPanel extends StatefulWidget {
  List<Location> locationList;
  LatLng center = LatLng(43.651070, -79.347015);
  double zoom = 4.0;

  MapPanel({Key? key, required this.locationList}) : super(key: key);

  @override
  State<MapPanel> createState() => _MapState();
}

class _MapState extends State<MapPanel> {
  late GoogleMapController mapController;
  String currentMarkerId = 'currentMarker';
  Set<Marker> markers = {};
  loc.Location locationService = loc.Location();
  loc.LocationData? currentPosition;
  LatLng? targetPosition;
  Location? targetLocation;
  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    _updateMapMarkers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _updateCurrentLocation(loc.LocationData locationData) {
    currentPosition = locationData;
    widget.center = LatLng(locationData.latitude!, locationData.longitude!);
    Marker marker = Marker(
      markerId: MarkerId(currentMarkerId),
      position: LatLng(locationData.latitude!, locationData.longitude!),
      infoWindow: InfoWindow(title: 'You are here', snippet: 'You are here now'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      onTap: () {},
    );
    markers.add(marker);
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: widget.zoom,
        ),
      ),
    );
  }

  Future<void> _showSelectedLocation(Location location) async {
    LatLng? position = await getLocationPosition(location);
    if (position != null) {
      targetPosition = position;
      CameraPosition nowPos = CameraPosition(target: position, zoom: 11.0);
      mapController.moveCamera(CameraUpdate.newCameraPosition(nowPos));
      setState(() {
        polylines.clear();
      });
    }
  }

  Future<void> _updateMapMarkers() async {
    markers = await getMarkers();
    setState(() {});
  }

  Future<void> _getCurrentPosition() async {
    bool hasPermission = await _handleLocationPermission();
    if (hasPermission) {
      locationService.getLocation().then((loc.LocationData locationData) {
        setState(() {
          _updateCurrentLocation(locationData);
        });
      }).catchError((e) {
        debugPrint(e.toString());
      });
    }
  }

  void _startNavigation() async {
    bool serviceEnabled = await _handleLocationPermission();
    if (serviceEnabled) {
      loc.LocationData currentPosition = await locationService.getLocation();
      loc.LocationData? currentLocation = currentPosition;
      StreamSubscription<loc.LocationData> locationSubscription =
          locationService.onLocationChanged.listen((loc.LocationData currentLocation) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
              zoom: 16,
            ),
          ),
        );
        if (mounted).
