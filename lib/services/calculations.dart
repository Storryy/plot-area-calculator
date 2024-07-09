//All calculations taking place in the applications are here.

import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



class DistanceCalculation {

  getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    Position position =
    await Geolocator.
    getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    return position;
  }

  // To calculate the distance between 2 points
  List<double> calculateDistance(List<Position> points) {
    List<double> distanceBetweenPoints = [];

    for(int i = 0; i<points.length; i++){
      int nextIndex = (i + 1) % points.length;
      Position coord0 = points[i];
      Position coord1 = points[nextIndex];
      double lat0 = coord0.latitude;
      double lon0 = coord0.longitude;
      double lat1 = coord1.latitude;
      double lon1 = coord1.longitude;

      double distanceInMeters = Geolocator.distanceBetween(
          lat0, lon0, lat1, lon1);

      distanceBetweenPoints.add(distanceInMeters);
    }
    return distanceBetweenPoints;
  }

  // To convert Degrees to Radians
  double degToRad(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // To calculate the Area covered by the points
  double polygonArea(List<Position> points) {
    const double R = 6378137; // Earth's radius in meters
    double totalArea = 0.0;
    double areaSqFt = 0.0;

    for (int i = 0; i < points.length; i++) {
      Position coord0 = points[i];
      Position coord1 = points[(i + 1) % points.length];

      double lat0 = degToRad(coord0.latitude); // Default to 0 if null
      double lon0 = degToRad(coord0.longitude); // Default to 0 if null
      double lat1 = degToRad(coord1.latitude); // Default to 0 if null
      double lon1 = degToRad(coord1.longitude); // Default to 0 if null

      // Area calculation based on the spherical excess formula
      totalArea += (lon1 - lon0) * (2 + math.sin(lat0) + math.sin(lat1));
    }

    totalArea = (totalArea.abs()) / 2.0;
    totalArea *= math.pow(R, 2); // Convert to square meters
    areaSqFt = totalArea * 10.76391041671; // Convert to square feet
    return areaSqFt;
  }

  // This function is used to get the direction list: The direction list stores the directions, each line is going in, and also gives us the coordinates after checking and removing two consecutive ones going in the same direction
  calculateBearingPosition(List<Position> coordinates, List<String?> directionList) {
    List<double?> bearingList = [];
    List<double?> directionDegreesList = [];

    for (int i = 0; i < coordinates.length; i++) {
      int nextIndex = (i + 1) % coordinates.length;

      double lat0 = coordinates[i].latitude;
      double lon0 = coordinates[i].longitude;
      double lat1 = coordinates[nextIndex].latitude;
      double lon1 = coordinates[nextIndex].longitude;

      double bearing = Geolocator.bearingBetween(lat0, lon0, lat1, lon1);
      bearingList.add(bearing);
    }

    // To convert the Bearing into Direction.
    for (int i = 0; i < bearingList.length; i++) {
      if (bearingList[i]! > 0) {
        var directionCoords = bearingList[i];
        directionDegreesList.add(directionCoords);
      }
      else {
        var directionCoords = 360.0 + bearingList[i]!;
        directionDegreesList.add(directionCoords);
      }
    }

    // To find out the direction each side is going in
    for (int i = 0; i < directionDegreesList.length; i++) {
      if (directionDegreesList[i]! >= 0 &&
          directionDegreesList[i]! <= 22.5 &&
          directionDegreesList[i]! >= 337.5) {
        directionList.add("North");
      }
      else if (directionDegreesList[i]! > 22.5 &&
          directionDegreesList[i]! <= 67.5) {
        directionList.add("North East");
      }
      else if (directionDegreesList[i]! > 67.5 &&
          directionDegreesList[i]! <= 112.5) {
        directionList.add("East");
      }
      else if (directionDegreesList[i]! > 112.5 &&
          directionDegreesList[i]! <= 157.5) {
        directionList.add("South East");
      }
      else if (directionDegreesList[i]! > 157.5 &&
          directionDegreesList[i]! <= 202.5) {
        directionList.add("South");
      }
      else if (directionDegreesList[i]! > 202.5 &&
          directionDegreesList[i]! <= 247.5) {
        directionList.add("South West");
      }
      else if (directionDegreesList[i]! > 247.5 &&
          directionDegreesList[i]! <= 292.5) {
        directionList.add("West");
      }
      else if (directionDegreesList[i]! > 292.5 &&
          directionDegreesList[i]! <= 337.5) {
        directionList.add("North West");
      }
      else {
        directionList.add("North");
      }
    }
    // To check if two consecutive points are going in the same direction, and if so, removing the 2nd point.
    int i = 0;
    while (i < directionList.length - 1) {
      if (directionList[i] == directionList[i + 1]) {
        directionList.removeAt(i); // Direction List stores the direction faced by the first and second side, then second and third side ..... until the last and first side.
        coordinates.removeAt(i + 1); // Coordinates stores the points plotted on the map, 0th entry is the first point, 1st entry is the second.... nth entry is n+1 point.
      } else {
        i++;
      }
    }
    return coordinates;
  }

  // To convert Position into LatLng
  List<LatLng> convertToLatLng(List<List<double?>> points) {
    List<LatLng> latLngList = points.map((point) {
      if (point.length != 2) {
        throw ArgumentError(
            'Each point must contain exactly 2 values: latitude and longitude.');
      }
      return LatLng(point[0]!, point[1]!);
    }).toList();

    return latLngList;
  }

  // To calculate the centroid of the plot, to add the marker that shows the area of the plot.
  LatLng calculateCentroid(List<LatLng> points) {
    double latSum = 0.0;
    double lonSum = 0.0;
    int numPoints = points.length;

    for (var point in points) {
      latSum += point.latitude;
      lonSum += point.longitude;
    }

    return LatLng(latSum / numPoints, lonSum / numPoints);
  }

  // To find out the outward direction each line is facing. Sloppy code :p
  List<String> outwardDirection(List<String> directionList) {

    List<String> facingDirectionList = [];

    for (int i = 0; i < directionList.length; i++) {
      int nextIndex = (i + 1) % directionList.length;

      if (directionList[i] == "North") {
        if (directionList[nextIndex] == "North" ||
            directionList[nextIndex] == "North East" ||
            directionList[nextIndex] == "East" ||
            directionList[nextIndex] == "South East" ||
            directionList[nextIndex] == "South") {
          facingDirectionList.add("West");
        } else {
          facingDirectionList.add("East");
        }
      } else if (directionList[i] == "North East") {
        if (directionList[nextIndex] == "North East" ||
            directionList[nextIndex] == "East" ||
            directionList[nextIndex] == "South East" ||
            directionList[nextIndex] == "South" ||
            directionList[nextIndex] == "South West") {
          facingDirectionList.add("North West");
        } else {
          facingDirectionList.add("South East");
        }
      } else if (directionList[i] == "East") {
        if (directionList[nextIndex] == "East" ||
            directionList[nextIndex] == "South East" ||
            directionList[nextIndex] == "South" ||
            directionList[nextIndex] == "South West" ||
            directionList[nextIndex] == "West") {
          facingDirectionList.add("North");
        } else {
          facingDirectionList.add("South");
        }
      } else if (directionList[i] == "South East") {
        if (directionList[nextIndex] == "South East" ||
            directionList[nextIndex] == "South" ||
            directionList[nextIndex] == "South West" ||
            directionList[nextIndex] == "West" ||
            directionList[nextIndex] == "North West") {
          facingDirectionList.add("North East");
        } else {
          facingDirectionList.add("South West");
        }
      } else if (directionList[i] == "South") {
        if (directionList[nextIndex] == "South" ||
            directionList[nextIndex] == "South West" ||
            directionList[nextIndex] == "West" ||
            directionList[nextIndex] == "North West" ||
            directionList[nextIndex] == "North") {
          facingDirectionList.add("East");
        } else {
          facingDirectionList.add("West");
        }
      } else if (directionList[i] == "South West") {
        if (directionList[nextIndex] == "South West" ||
            directionList[nextIndex] == "West" ||
            directionList[nextIndex] == "North West" ||
            directionList[nextIndex] == "North" ||
            directionList[nextIndex] == "North East") {
          facingDirectionList.add("South East");
        } else {
          facingDirectionList.add("North West");
        }
      } else if (directionList[i] == "West") {
        if (directionList[nextIndex] == "West" ||
            directionList[nextIndex] == "North West" ||
            directionList[nextIndex] == "North" ||
            directionList[nextIndex] == "North East" ||
            directionList[nextIndex] == "East") {
          facingDirectionList.add("South");
        } else {
          facingDirectionList.add("North");
        }
      } else if (directionList[i] == "North West") {
        if (directionList[nextIndex] == "North West" ||
            directionList[nextIndex] == "North" ||
            directionList[nextIndex] == "North East" ||
            directionList[nextIndex] == "East" ||
            directionList[nextIndex] == "South East") {
          facingDirectionList.add("South West");
        } else {
          facingDirectionList.add("North East");
        }
      }
    }
    return facingDirectionList;
  }

  // To calculate the angle between two sides.
  List<double?> angleBetween(List<Position> points) {

    List<double?> finalAngles = [];

    for (int i = 0; i < points.length; i++) {
      int nextIndex = (i + 1) % points.length;
      int nextToNextIndex = (i + 2) % points.length;
      Position p1 = points[i];
      Position p2 = points[nextIndex];
      Position p3 = points[nextToNextIndex];

      double bearing1 = Geolocator.bearingBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude);
      double bearing2 = Geolocator.bearingBetween(p2.latitude, p2.longitude, p3.latitude, p3.longitude);

      double angle = angleBetweenLines(bearing1, bearing2);
      finalAngles.add(angle);
    }

    return finalAngles;
  }

  double angleBetweenLines(double bearing1, double bearing2) {
    bearing1 = (bearing1 + 360) % 360;
    bearing2 = (bearing2 + 360) % 360;

    double angle = (bearing2 - bearing1).abs();
    if (angle > 180) {
      angle = 360 - angle;
    }

    return angle;
  }

}
