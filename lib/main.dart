import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';

List<CameraDescription> cameras = []; // Making an empty List that holds the description of our available cameras.
//Defining it here, because you can't initialize your camera in the future.

Future <void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(
      const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'Pranav',
      theme: ThemeData(
          primarySwatch: Colors.blue
      ),
      home: MainHomePage(cameras: cameras), // Passing CameraDescription to the home page.
    );
  }

}