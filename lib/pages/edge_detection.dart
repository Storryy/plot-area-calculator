// 2.2) This is the second page if you want corner detection to happen automatically

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:utecbuild6/pages/map_page.dart';
import 'package:utecbuild6/pages/testing.dart';
import '../services/calculations.dart';
import 'camera_page.dart';

class EdgeDetection extends StatefulWidget {
  final List<CameraDescription> cameras;
  const EdgeDetection({super.key, required this.cameras});

  @override
  State<EdgeDetection> createState() => EdgeDetectionState();

}

class EdgeDetectionState extends State<EdgeDetection>{

  List<Position> coordinates = [];
  List<Position> smoothedCoordinates = [];
  List<Position> corners = [];
  List<Position> cornersFromJustCoords = [];
  List<Position> paddedSmoothCorners = [];
  List<String> facingDirectionList = [];
  List<double> distanceBetweenPoints = [];
  List<double?> angleBetweenSides = [];
  bool isTracking = false;
  int windowSize = 2;
  double bearingThreshold = 30.0;
  double areaSqFt = 0.0;
  int checker = 0;
  StreamSubscription<Position>? positionStreamSubscription;


  DistanceCalculation distanceCalculation = DistanceCalculation();

  Widget coordinatesBuild(){
    if(corners.isNotEmpty){
      return Text("Coordinates are: $corners", style: const TextStyle(fontSize: 16), textAlign: TextAlign.center);
    }
    else{
      return const Text("");
    }
  }

  Widget openMap() {
    print(smoothedCoordinates);
    cornerDetectionV2();
    paddedSmoothCorners = List.from(corners);
    if(checker == 1) {
      return ElevatedButton(onPressed: () async {
        areaSqFt = distanceCalculation.polygonArea(paddedSmoothCorners);

        if(paddedSmoothCorners.isNotEmpty && areaSqFt > 0.0) {
          List<LatLng> smoothCorners = paddedSmoothCorners.map((
              position) =>
              LatLng(position.latitude, position.longitude))
              .toList();

          var centroid = distanceCalculation.calculateCentroid(smoothCorners);

          Navigator.push(context, MaterialPageRoute(
              builder: (context) =>
                  MapPage(
                      mapPoints: smoothCorners,
                      area: areaSqFt,
                      centroid: centroid,
                      sideLengths: distanceBetweenPoints
              )));
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete Tracking and calculate area first!")));
        }

      }, child: const Text("Open Map final corners!"));

  }
    else{
      return const Text("");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Color(0xFFF2F1EE),
                    Color(0xFFE4E2DC)
                  ]
              )
          ),

          child: SizedBox.expand(
              child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.topCenter,
                          child: SafeArea(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text("Welcome to Area Calculator smoothed coords!", style: TextStyle(fontSize: 22), textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        const SizedBox(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text("After clicking Start Tracking, go around the Perimeter of your plot.\n"
                                "\n"
                                "After going around and reaching back to the start, click on stop tracking, then find out the area and look at the points on the map!", textAlign: TextAlign.center,),
                          ),
                        ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CameraPage(cameras: widget.cameras, edgeDetectionState: this)));
                              }, child: const Text("Start Recording and Tracking"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        ElevatedButton(onPressed: (){
                          areaSqFt = distanceCalculation.polygonArea(coordinates);

                          if(coordinates.isNotEmpty && areaSqFt > 0.0) {
                            List<LatLng> coords = coordinates.map((
                                position) =>
                                LatLng(position.latitude, position.longitude))
                                .toList();

                            var centroid = distanceCalculation.calculateCentroid(coords);

                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    MapPage(
                                        mapPoints: coords,
                                        area: areaSqFt,
                                        centroid: centroid,
                                        sideLengths: []
                                    )));
                          }

                        }, child: Text("Open Maps plain coords")),

                        const SizedBox(height: 20,),
                        ElevatedButton(onPressed: (){
                          print(coordinates);
                          cornerDetectionV3OnPlainCoords();
                          areaSqFt = distanceCalculation.polygonArea(cornersFromJustCoords);

                          if(cornersFromJustCoords.isNotEmpty && areaSqFt > 0.0) {
                            List<LatLng> babyCorners = cornersFromJustCoords.map((
                                position) =>
                                LatLng(position.latitude, position.longitude))
                                .toList();

                            var centroid = distanceCalculation.calculateCentroid(babyCorners);

                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    MapPage(
                                        mapPoints: babyCorners,
                                        area: areaSqFt,
                                        centroid: centroid,
                                        sideLengths: []
                                    )));
                          }

                        }, child: Text("Open maps Corners on basic coords")),

                        const SizedBox(height: 20,),
                        ElevatedButton(onPressed: (){
                          areaSqFt = distanceCalculation.polygonArea(smoothedCoordinates);

                          if(smoothedCoordinates.isNotEmpty && areaSqFt > 0.0) {
                            List<LatLng> smoothCoords = smoothedCoordinates.map((
                                position) =>
                                LatLng(position.latitude, position.longitude))
                                .toList();

                            var centroid = distanceCalculation.calculateCentroid(smoothCoords);

                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    MapPage(
                                        mapPoints: smoothCoords,
                                        area: areaSqFt,
                                        centroid: centroid,
                                        sideLengths: distanceBetweenPoints
                                    )));
                          }

                        }, child: Text("Open Maps Smooth Coords")),

                        const SizedBox(height: 20,),
                        openMap(),

                        const SizedBox(height: 20,),
                        ElevatedButton(onPressed: () async {
                          Position currentPosition = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.best,
                          );
                          Navigator.push(context, MaterialPageRoute(builder: (context) => testing(currentPostion: currentPosition)));
                        }, child: Text("Testing")),


                        const SizedBox(height: 20,),
                        coordinatesBuild(),
                      ],
                    ),
                  ),
              ),
          ),
        ),
    );

  }
  Future<void> startTracking() async {
    coordinates.clear();
    smoothedCoordinates.clear();
    corners.clear();
    facingDirectionList.clear();
    angleBetweenSides.clear();
    paddedSmoothCorners.clear();

    setState(() {
      isTracking = true;
    });

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    // Add the current position to the corners list
    setState(() {
      corners.add(currentPosition);
    });

    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2
    );

    positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position){
      if (!mounted) return;

      setState(() {
        coordinates.add(position);
        print(coordinates);
      });
    });
  }

  Future<void> stopTracking() async {
    await writeListToFile(coordinates);


    smoothCoordinates();
    print(smoothedCoordinates);
    checker = 1;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Tracking Successful!"),
            duration: Duration(seconds: 2)
        ));

    List<String> fixedDirectionList = [];

    paddedSmoothCorners = distanceCalculation.calculateBearingPosition(paddedSmoothCorners, fixedDirectionList);

    facingDirectionList = distanceCalculation.outwardDirection(fixedDirectionList);

    angleBetweenSides = distanceCalculation.angleBetween(paddedSmoothCorners);

    distanceBetweenPoints = distanceCalculation.calculateDistance(paddedSmoothCorners);
    setState(() {
      isTracking = false;
    });

    positionStreamSubscription?.cancel();

  }

  Future<void> smoothCoordinates() async{
    for(int i = 0; i < coordinates.length; i++) {
      int start = max(0, i - windowSize);
      int end = min(coordinates.length, i + windowSize + 1);

      double sumLat = 0;
      double sumLng = 0;

      int count = 0;

      for (int j = start; j < end; j++){
        sumLat += coordinates[j].latitude;
        sumLng += coordinates[j].longitude;
        count++;
      }
      double avgLat = sumLat/count;
      double avgLng = sumLng/count;

      smoothedCoordinates.add(Position(
          latitude: avgLat,
          longitude: avgLng,
          timestamp: coordinates[i].timestamp,
          speed: coordinates[i].speed,
          accuracy: coordinates[i].accuracy,
          altitude: coordinates[i].altitude,
          heading: coordinates[i].heading,
          speedAccuracy: coordinates[i].speedAccuracy,
          floor: coordinates[i].floor,
          isMocked: coordinates[i].isMocked,
          altitudeAccuracy: coordinates[i].altitudeAccuracy,
          headingAccuracy: coordinates[i].headingAccuracy));
    }
  }

  Future<void> cornerDetection() async {

    if (smoothedCoordinates.length > 1) {
      Position previousCoordinate = smoothedCoordinates[smoothedCoordinates.length - 2];
      Position currentCoordinate = smoothedCoordinates.last;
      double bearingChange = Geolocator.bearingBetween(
          previousCoordinate.latitude,
          previousCoordinate.longitude,
          currentCoordinate.latitude,
          currentCoordinate.longitude);
      if(bearingChange.abs() >= bearingThreshold){
        corners.add(previousCoordinate);
      }
    }
  }

  // OR this (cornerDetectionV2): I haven't tested much, but the latter feels like a better way of figuring out the corner.

  Future<void> cornerDetectionV2() async {
    for (int i = 0; i < smoothedCoordinates.length; i++) {
      int nextIndex = (i + 1) % smoothedCoordinates.length;
      int nextToNextIndex = (i + 2) % smoothedCoordinates.length;

      Position currentCoordinate = smoothedCoordinates[i];
      Position nextCoordinate = smoothedCoordinates[nextIndex];
      Position afterNextCoordinate = smoothedCoordinates[nextToNextIndex];

      double bearing1 = Geolocator.bearingBetween(
        currentCoordinate.latitude,
        currentCoordinate.longitude,
        nextCoordinate.latitude,
        nextCoordinate.longitude,
      );

      double bearing2 = Geolocator.bearingBetween(
        nextCoordinate.latitude,
        nextCoordinate.longitude,
        afterNextCoordinate.latitude,
        afterNextCoordinate.longitude,
      );

      double bearingChange = (bearing2 - bearing1).abs();
      if (bearingChange > 180) {
        bearingChange = 360 - bearingChange;
      }

      print("b2 is $bearing2");
      print("b1 is $bearing1");
      print("bearing change is $bearingChange");

      if (bearingChange >= bearingThreshold) {
        corners.add(nextCoordinate);
      }
      print(corners.length);
    }
  }
  Future<void> cornerDetectionV3OnPlainCoords() async {
    for (int i = 0; i < coordinates.length; i++) {
      int nextIndex = (i + 1) % coordinates.length;
      int nextToNextIndex = (i + 2) % coordinates.length;

      Position currentCoordinate = coordinates[i];
      Position nextCoordinate = coordinates[nextIndex];
      Position afterNextCoordinate = coordinates[nextToNextIndex];

      double bearing1 = Geolocator.bearingBetween(
        currentCoordinate.latitude,
        currentCoordinate.longitude,
        nextCoordinate.latitude,
        nextCoordinate.longitude,
      );

      double bearing2 = Geolocator.bearingBetween(
        nextCoordinate.latitude,
        nextCoordinate.longitude,
        afterNextCoordinate.latitude,
        afterNextCoordinate.longitude,
      );

      double bearingChange = (bearing2 - bearing1).abs();
      if (bearingChange > 180) {
        bearingChange = 360 - bearingChange;
      }

      print("b2 is $bearing2");
      print("b1 is $bearing1");
      print("bearing change is $bearingChange");

      if (bearingChange >= bearingThreshold) {
        cornersFromJustCoords.add(nextCoordinate);
      }
      print(cornersFromJustCoords.length);
    }
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/my_list.txt';
  }

  Future<void> writeListToFile(List<Position> myList) async {
    final path = await getFilePath();
    final file = File(path);

    // Convert the list to a string with each item on a new line
    final content = myList.join('\n');
    await file.writeAsString(content);
    print(path);

  }


}