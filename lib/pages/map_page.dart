import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.mapPoints,
    required this.centroid,
    required this.area,
    required this.sideLengths,
  });

  final List<LatLng> mapPoints;
  final LatLng centroid;
  final double area;
  final List<double> sideLengths;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  double _mapBearing = 0;
  List<Widget> _polylineTextWidgets = [];

  @override
  void initState() {
    super.initState();
    _initializeMarkerWithArea();
    _initializePolylines();
    _initializePolygon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePolylineTextWidgets();
    });
  }

  void _initializeMarkerWithArea() {
    _markers.add(
      Marker(
        markerId: const MarkerId('area_marker'),
        position: widget.centroid,
        infoWindow: InfoWindow(
          title: 'Area: ${widget.area.toStringAsFixed(3)} sq.ft',
          snippet: 'Approximate Area',
        ),
      ),
    );
  }

  void _initializePolylines() {
    List<LatLng> polylinePoints = List.from(widget.mapPoints)
      ..add(widget.mapPoints.first);

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('polyline'),
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  void _initializePolygon() {
    _polygons.add(
      Polygon(
        polygonId: const PolygonId('polygon'),
        points: widget.mapPoints,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 3,
      ),
    );
  }

  Future<void> _updatePolylineTextWidgets() async {
    if (_mapController == null) return;

    List<Widget> textWidgets = [];
    for (int i = 0; i < widget.mapPoints.length; i++) {
      int nextIndex = (i + 1) % widget.mapPoints.length;
      final startPoint = widget.mapPoints[i];
      final endPoint = widget.mapPoints[nextIndex];
      final midPoint = LatLng(
        (startPoint.latitude + endPoint.latitude) / 2,
        (startPoint.longitude + endPoint.longitude) / 2,
      );

      ScreenCoordinate? screenCoordinate = await _mapController!.getScreenCoordinate(midPoint);

      textWidgets.add(
        Positioned(
          left: screenCoordinate.x.toDouble() - 20, // Adjust the position
          top: screenCoordinate.y.toDouble() - 10, // Adjust the position
          child: Transform.rotate(
            angle: -_mapBearing * (math.pi / 180),
            child: Container(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                '${widget.sideLengths[i].toStringAsFixed(2)} ft',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _polylineTextWidgets = textWidgets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Area of your plot is ${(widget.area).toStringAsFixed(2)} sq.ft'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.mapPoints[0],
              zoom: 17,
            ),
            compassEnabled: true,
            markers: _markers,
            polylines: _polylines,
            polygons: _polygons,
            onMapCreated: (controller) {
              _mapController = controller;
              _updatePolylineTextWidgets();
            },
            onCameraMove: (CameraPosition position) {
              setState(() {
                _mapBearing = position.bearing;
              });
              _updatePolylineTextWidgets();
            },
          ),
          ..._polylineTextWidgets,
        ],
      ),
    );
  }
}
