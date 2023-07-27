import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var locationManger = Location();
  static const String routeMarkerId = "route-Dokki";
  static const String userMarkerId = "user-Marker";

  @override
  void initState() {
    super.initState();
    askUserForPermissionAndService();
  }

  void askUserForPermissionAndService() async {
    await requestPermission();
    await requestService();
    trackUserLocation();
  }

  var routeDokkiLocation = CameraPosition(
    target: LatLng(
      30.035863,
      31.2016553,
    ),
    zoom: 16,
  );
  Set<Marker> markersSet = {
    const Marker(
      markerId: MarkerId(routeMarkerId),
      position: LatLng(
        30.035863,
        31.2016553,
      ),
    ),
  };
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Maps"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              markers: markersSet,
              mapType: MapType.normal,
              initialCameraPosition: routeDokkiLocation,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                drawUserMarker();
              },
            ),
          ),
          ElevatedButton(
              onPressed: () {
                trackUserLocation();
              },
              child: Text("Start Tracking"))
        ],
      ),
    );
  }

  void drawUserMarker() async {
    var canGetLocation = await canUseGps();
    if (!canGetLocation) return;
    var locationData = await locationManger.getLocation();
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0),
        16));
    markersSet.add(Marker(
      markerId: MarkerId(userMarkerId),
      position:
          LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0),
    ));
    setState(() {});
  }

  Future<void> getUserLocation() async {
    var canGetLocation = await canUseGps();
    if (!canGetLocation) return;
    var locationData = await locationManger.getLocation();
    print(locationData.altitude);
    print(locationData.longitude);
  }

  StreamSubscription<LocationData>? trakingService = null;

  Future<void> trackUserLocation() async {
    var canGetLocation = await canUseGps();
    if (!canGetLocation) return;
    locationManger.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2000,
      distanceFilter: 5,
    );
    trakingService = locationManger.onLocationChanged.listen((locationData) {
      markersSet.add(Marker(
        markerId: const MarkerId(userMarkerId),
        position:
            LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0),
      ));
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(locationData.latitude ?? 0.0, locationData.longitude ?? 0.0),
          16));
      setState(() {
        print(locationData.latitude);
        print(locationData.longitude);
      });
    });
  }

  @override
  void dispose() {
    trakingService?.cancel();
    super.dispose();
  }

  Future<bool> canUseGps() async {
    var permissionGranted = await isPermissionGranted();
    if (!permissionGranted) {
      return false;
    }
    var isServiceEnabled = await isLocationServicedEnabled();
    if (!isServiceEnabled) {
      return false;
    }
    return true;
  }

  Future<bool> isLocationServicedEnabled() async {
    return await locationManger.serviceEnabled();
  }

  Future<bool> requestService() async {
    var enabled = await locationManger.requestService();
    return enabled;
  }

  Future<bool> isPermissionGranted() async {
    var permissionStatus = await locationManger.hasPermission();
    return permissionStatus == PermissionStatus.granted;
  }

  Future<bool> requestPermission() async {
    var permissionStatus = locationManger.requestPermission();
    return permissionStatus == PermissionStatus.granted;
  }
}
