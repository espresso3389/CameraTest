import 'dart:async';
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
  Timer procTimer;
  final messages = ValueNotifier<String>('');
  final fileSize = ValueNotifier<int>(0);
  final bytesPerSec = ValueNotifier<double>(0);
  final movieDuration = ValueNotifier<Duration>(Duration.zero);

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    messages.dispose();
    fileSize.dispose();
    bytesPerSec.dispose();
    movieDuration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            controller?.value?.isInitialized != true
            ? Container(width: double.infinity, height: double.infinity, color: Colors.black)
            : ClipRect(
                child: Transform.scale(
                  scale: 1 / controller.value.aspectRatio,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                Container(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(icon: Icon(Icons.switch_camera), color: Colors.white, onPressed: () => switchCamera()),
                ),
                Expanded(child: Container()),
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.black54,
                  margin: EdgeInsets.all(4),
                  child: Column(children: [
                    SizedBox(
                      height: 70,
                      child: ValueListenableBuilder<String>(
                        valueListenable: messages,
                        builder: (context, stats, child) {
                          return Text(stats, style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.white));
                        }
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      _meter<int>(value: fileSize, unit: 'MB', val2str: (bytes) => (bytes / 1024 / 1024).toStringAsFixed(1)),
                      _meter<double>(value: bytesPerSec, unit: 'MB/s', val2str: (bps) => (bps / 1024 / 1024).toStringAsFixed(1)),
                      _meter<Duration>(value: movieDuration, unit: 'sec.', val2str: (d) => (d.inMilliseconds / 1000).toStringAsFixed(1))
                    ],),
                  ]),
                ),
                Container(
                  margin: EdgeInsets.all(4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: controller?.value?.isRecordingVideo == true ? null : RaisedButton(
                      child: Text('撮影開始', style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.white),),
                      color: Colors.green,
                      onPressed: controller?.value?.isRecordingVideo != true ? () => test() : null),
                  ),
                ),
              ],
            )
          ],
        ),
      )
    );
  }

  static Widget _fullscreenCameraPreview(BuildContext context, CameraController controller) {
    // get screen size
    final size = MediaQuery.of(context).size;

    if (controller?.value?.isInitialized != true) {
      return Container(width: size.width, height: size.height, color: Colors.black,);
    }

    // calculate scale for aspect ratio widget
    var scale = controller.value.aspectRatio / size.aspectRatio;

    // check if adjustments are needed...
    if (controller.value.aspectRatio < size.aspectRatio) {
      scale = 1 / scale;
    }

    return Transform.scale(
      scale: scale,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _meter<T>({ValueNotifier<T> value, String unit, String Function(T) val2str}) {
    return ValueListenableBuilder<T>(
      valueListenable: value,
      builder: (context, v, child) {
        return Container(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                child: Text(val2str(v), style: Theme.of(context).textTheme.headline3.copyWith(color: Colors.white), textAlign: TextAlign.right,)
              ),
              Container(
                padding: EdgeInsets.only(left: 2, bottom: 6),
                child: Text(unit, style: TextStyle(color: Colors.white70)))
            ],
          ),
        );
      }
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
    await recordOrStop(false);
    await controller?.dispose();
    if (description != null) {
      controller = CameraController(description, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      aspectRatio = controller.value.aspectRatio;
    } else {
      controller = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> test() async {
    await recordOrStop(true);
      final start = DateTime.now();
      procTimer = Timer.periodic(Duration(milliseconds: 300), (timer) async {
        final t = DateTime.now().difference(start);
        final limitDur = Duration(seconds: 20);
        final toStop = t > limitDur;
        if (toStop) {
          procTimer?.cancel();
        }

        if (toStop) {
          // 撮影終了; チェック画面に遷移
          procTimer?.cancel();
          await recordOrStop(false);
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CheckVideoPage(movieFile: recTempFile)));
          return;
        }

        final s = await recTempFile.stat();
        messages.value = '身分証をおでこの部分にかざすようにしてください';
        fileSize.value = s.size;
        bytesPerSec.value = s.size * 1000 / t.inMilliseconds;
        movieDuration.value = t;

      });
  }

  Future<void> recordOrStop(bool recording) async {
    if (controller?.value == null || controller.value.isRecordingVideo == recording) {
      return;
    }
    if (recording) {
      try { await recTempFile.delete(); } catch (e) {}
      await controller.startVideoRecording(recTempFile.path);
    } else {
      await controller.stopVideoRecording();
    }
    isRecording = recording;
    if (mounted) {
      setState(() {});
    }
  }
}
class CheckVideoPage extends StatefulWidget {
  @override
  _CheckVideoPageState createState() => _CheckVideoPageState();

  final File movieFile;

  CheckVideoPage({this.movieFile});
}

class _CheckVideoPageState extends State<CheckVideoPage> {
  VideoPlayerController _controller;
  bool flipLr = true;

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
      title: 'ビデオ確認',
      home: Scaffold(
        appBar: AppBar(
          title: Text('ビデオ確認',),
          actions: [
            IconButton(icon: Icon(Icons.flip), onPressed: () {
              flipLr = !flipLr;
              setState(() { });
            })
          ],),
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
