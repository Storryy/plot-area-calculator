import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:utecbuild6/pages/map_page.dart';
import '../services/calculations.dart';
import 'camera_page.dart';

class InputPoints extends StatefulWidget{
  final List<CameraDescription> cameras; // List of available cameras
  const InputPoints({super.key, required this.cameras});

  @override
  State<StatefulWidget> createState() => InputPointsState();
}

class InputPointsState extends State<InputPoints> {
  bool isTracking = false; // To check if tracking is ongoing
  List<Position> points = []; // List to store the positions (latitude and longitude)
  List<double> distanceBetweenPoints = []; // List to store distances between points
  List<double?> angleBetweenSides = []; // List to store angles between points
  int checker = 0; // To check if tracking is complete
  int counter = 1; // To count the number of points added
  DistanceCalculation distanceCalculation = DistanceCalculation(); // Instance of a class to perform distance calculations

  // Method to open the map page with calculated data
  Widget? openMap() {
    if (checker == 1) {
      return ElevatedButton(
          onPressed: () {

            double areaOfPlot = distanceCalculation.polygonArea(points); // Calculate area of the plot

            List<LatLng> manualPositions = points.map((position) => LatLng(position.latitude, position.longitude)).toList(); // Convert Position to LatLng

            var centroid = distanceCalculation.calculateCentroid(manualPositions); // Calculate centroid

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MapPage(
                        mapPoints: manualPositions,
                        area: areaOfPlot,
                        centroid: centroid,
                        sideLengths: distanceBetweenPoints
                    )
                )
            );
          },
          child: const Text("Open map")
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              radius: 1.5,
              colors: [
                Color(0xFFF2F1EE),
                Color(0xFFE4E2DC)
              ]
          ),
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Input your points here!", textAlign: TextAlign.center, style: TextStyle(fontSize: 22)),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Click on 'start Tracking', then go around the perimeter of your plot! \n"
                            "\n"
                            "After reaching every turn keep pressing the button\n'Add current position as Turn'\nUntil you reach back to the starting position, then press stop tracking!",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraPage(
                                    cameras: widget.cameras,
                                    inputPointsState: this
                                )
                            )
                        );
                      },
                      child: const Text("Start Tracking!"),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: openMap(),
                    )
                  ]
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Method to start tracking positions
  Future<void> startTracking() async {
    points.clear(); // Clear previous points
    angleBetweenSides.clear();
    distanceBetweenPoints.clear();

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Started Tracking Successfully!"),
            duration: Duration(seconds: 1)
        )
    );
    setState(() {
      checker = 0;
      isTracking = true;
    });

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      points.add(currentPosition); // Add the starting position
    });
  }

  // Method to stop tracking positions
  Future<void> stopTracking() async {
    checker = 1;
    counter = 1;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tracking Complete!"),
          duration: Duration(seconds: 1),
        )
    );

    distanceBetweenPoints = distanceCalculation.calculateDistance(points); // Calculate distances between points
    angleBetweenSides = distanceCalculation.angleBetween(points); // Calculate angles between points

    setState(() {
      isTracking = false;
    });
  }

  // Method to input the current position as a turn
  Future<void> inputPosition() async {
    if (isTracking) {
      counter++;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Location for point number $counter marked successfully!"),
              duration: const Duration(seconds: 1)
          )
      );
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      points.add(currentPosition); // Add the current position as a turn
    } else {
      return;
    }
  }


}
