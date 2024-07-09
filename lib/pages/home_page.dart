// 1) Selection page: Here you can select if you want to manually input points or not
// YES takes you to input_page where you can manually input turns.
// NO takes you to edge_detection, which automatically detects turns and plots points

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'edge_detection.dart';
import 'input_page.dart';

class MainHomePage extends StatefulWidget{
  final List<CameraDescription> cameras;

  const MainHomePage({super.key, required this.cameras});

  @override
  State<StatefulWidget> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage>{

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
          child: SafeArea(
            child: SizedBox.expand(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        child: Text("Welcome to Area Calculator!",
                          style: TextStyle(fontSize: 22),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        child: Text("Do you want to manually input points?",
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                child: const Text("Yes!"),
                                onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => InputPoints(cameras: widget.cameras)));
                                },
                              ),

                              ElevatedButton(
                                child: const Text("No!"),
                                onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EdgeDetection(cameras: widget.cameras,)));
                                },
                              ),
                            ],
                          )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }
}