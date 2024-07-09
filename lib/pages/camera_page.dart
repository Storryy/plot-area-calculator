// This page has the camera view to record the video while tracking movement

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:utecbuild6/pages/input_page.dart';
import 'package:video_compress/video_compress.dart';
import 'edge_detection.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final EdgeDetectionState? edgeDetectionState;
  final InputPointsState? inputPointsState;

  const CameraPage({super.key, required this.cameras, this.edgeDetectionState, this.inputPointsState});

  @override
  State<CameraPage> createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> with SingleTickerProviderStateMixin {
  late CameraController controller;
  late Future<void> initializeControllerFuture;
  bool isRecording = false;
  XFile? videoFile;
  late AnimationController animationController;
  late Animation<double> animation;

  Widget currentPosition(){
    if(isRecording == true){
      return ElevatedButton(onPressed: (){
        widget.inputPointsState!.inputPosition();
      },
          child: const Text("Add current position as turn"));
    }
    else{
      return const Text("");
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Animation duration
    )..repeat(reverse: true); // Repeat the animation back and forth

    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut, // Smooth transition
    );
  }

  Future<void> initCamera() async {
    controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    initializeControllerFuture = controller.initialize();
  }

  Future<void> startRecording() async {
    if (!controller.value.isRecordingVideo) {
      await controller.startVideoRecording();
      if (widget.edgeDetectionState != null) {
        await widget.edgeDetectionState!.startTracking();
      }
      else if(widget.inputPointsState != null){
        await widget.inputPointsState!.startTracking();
      }
      setState(() {
        isRecording = true;
      });
    }
  }

  Future<void> stopRecording() async {
    /* ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
         content: Text("Compressing the video. Please hold on, this might take a while!")));*/
    if (controller.value.isRecordingVideo) {
      videoFile = await controller.stopVideoRecording();
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await videoFile?.saveTo(path);



      if (widget.edgeDetectionState != null) {
        await widget.edgeDetectionState!.stopTracking();
      }
      else if (widget.inputPointsState != null){
        await widget.inputPointsState!.stopTracking();
      }
      setState(() {
        isRecording = false;
        // Navigate or display video as needed
      });
      Navigator.pop(context);
      final MediaInfo? compressedVideoInfo = await compressVideo(path);

      if (compressedVideoInfo != null) {
        print('Compressed video saved to: ${compressedVideoInfo.path}');
      }

    }
  }

  @override
  void dispose() {
    animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Video for Tracking')),
      body: FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && widget.edgeDetectionState != null) {
            return Stack(
              children: [
                CameraPreview(controller),
                Align(
                  alignment: const Alignment(0.0, 0.6),
                      child: InkWell(
                    onTap: isRecording ? stopRecording : startRecording,
                    child: isRecording ?
                    Image.asset('assets/stopButton.png', width: 85, height: 85) :
                    Image.asset('assets/recordButton.png', width: 85, height: 85)
                  ),
                ),
                if (isRecording)
                   Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FadeTransition(
                        opacity: animation,
                        child: Image.asset('assets/redDot.png', width: 20, height: 20,),
                      ),
                    ),
                   ),
              ],
            );
          }
          else if(snapshot.connectionState == ConnectionState.done && widget.inputPointsState != null){
            return Stack(
              children: [
                CameraPreview(controller),
                Align(
                  alignment: const Alignment(0.0, 0.6),
                  child: InkWell(
                      onTap: isRecording ? stopRecording : startRecording,
                      child: isRecording ?
                      Image.asset('assets/stopButton.png', width: 85, height: 85) :
                      Image.asset('assets/recordButton.png', width: 85, height: 85)
                  ),
                ),
                Align(
                    alignment: const Alignment(0.0, 0.77),
                    child: currentPosition()
                ),
                if (isRecording && widget.inputPointsState != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FadeTransition(
                        opacity: animation,
                        child: Image.asset('assets/redDot.png', width: 20, height: 20,),
                      ),
                    ),
                  ),
              ],
            );
          }
          else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
  Future<MediaInfo?> compressVideo(String videoPath) async {
    try {
      final MediaInfo? info = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality, // Set the desired quality
        deleteOrigin: false, // Set to true if you want to delete the original file
      );

      // Return the compressed video info
      return info;
    } catch (e) {
      print('Error compressing video: $e');
      return null;
    }
  }
}
