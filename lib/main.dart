import 'dart:async';
import 'dart:io' as io;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CameraTestPage(),
    );
  }
}

class CameraTestPage extends StatefulWidget {
  CameraTestPage({Key key}) : super(key: key);

  @override
  _CameraTestPageState createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {

  CameraController controller;
  double aspectRatio = 3 / 4;
  bool isRecording = false;
  File recTempFile;
  Timer statTimer;
  final stats = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    stats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Test'),
        actions: [
          IconButton(icon: Icon(isRecording ? Icons.stop :  Icons.fiber_manual_record), onPressed: () => recordOrStop(!isRecording),),
          IconButton(icon: Icon(Icons.play_arrow), onPressed: () => play(),),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: controller?.value?.isInitialized == true
            ? CameraPreview(controller)
            : Container(width: 10, height: 10 * aspectRatio)),
          ValueListenableBuilder<String>(
            valueListenable: stats,
            builder: (context, stats, child) {
              return Text(stats);
            }
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => switchCamera(),
        tooltip: 'Switch Camera',
        child: Icon(Icons.switch_camera),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> initCamera() async {
    recTempFile = File(path.join((await getTemporaryDirectory()).path, 'temp.mp4'));
    final cameras = await availableCameras();
    final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front) ?? cameras[0];
    setCamera(camera);
  }

  Future<void> switchCamera() async {
    final cameras = await availableCameras();
    final index = cameras.indexOf(controller?.description);
    final camera = cameras[(index + 1) % cameras.length];
    await setCamera(camera);
  }

  Future<void> setCamera(CameraDescription description) async {
    await controller?.dispose();
    if (description != null) {
      controller = CameraController(description, ResolutionPreset.low, enableAudio: false);
      await controller.initialize();
      aspectRatio = controller.value.aspectRatio;
    } else {
      controller = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> recordOrStop(bool recording) async {
    if (controller.value.isRecordingVideo == recording) {
      return;
    }
    if (recording) {
      try { await recTempFile.delete(); } catch (e) {}
      await controller.startVideoRecording(recTempFile.path);
      final start = DateTime.now();
      statTimer = Timer.periodic(Duration(milliseconds: 300), (timer) async {
        final s = await recTempFile.stat();
        final size = s.size / 1024 / 1024;
        final t = DateTime.now().difference(start).inMicroseconds / 1000 / 1000;
        final rate = size / t;
        stats.value = '${size.toStringAsFixed(2)} MB, ${rate.toStringAsFixed(2)} MB/s';
      });
    } else {
      statTimer?.cancel();
      await controller.stopVideoRecording();
    }
    isRecording = recording;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> play() async {
    await recordOrStop(false);
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => VideoPlayerPage(movieFile: recTempFile)));
  }
}
class VideoPlayerPage extends StatefulWidget {
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();

  final File movieFile;

  VideoPlayerPage({this.movieFile});
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
        widget.movieFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('Playing Video',)),
        body: Center(
          child: _controller.value.initialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
