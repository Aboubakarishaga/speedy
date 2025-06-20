import 'package:flutter/material.dart';
import 'package:flutter_speed_test_plus/flutter_speed_test_plus.dart';

import '../widgets/loading_widget.dart';
import '../widgets/result_widget.dart';
import '../widgets/run_test_widget.dart';
import '../widgets/space_widget.dart';
import '../widgets/speed_gauge_widget.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final internetSpeedTest = FlutterInternetSpeedTest()..enableLog();
  final PageController pageController = PageController();

  double _downloadRate = 0;
  double _uploadRate = 0;
  double _finalDownloadRate = 0;
  double _finalUploadRate = 0;
  bool _isServerSelectionInProgress = false;
  bool _runTest = false;
  bool _runTestIsComplete = false;

  String? _ip;
  String _unit = "Mbps";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Speed Test")),
      body:
          !_runTest
              ? RunTestWidget(
                onTap: () {
                  setState(() {
                    startTest();
                  });
                },
              )
              : _isServerSelectionInProgress
              ? const LoadingWidget()
              : SingleChildScrollView(
                child: Column(
                  children: [
                    _runTestIsComplete
                        ? Column(
                          children: [
                            ResultWidget(
                              unit: _unit,
                              downloadRate: _finalDownloadRate,
                              uploadRate: _finalUploadRate,
                            ),
                            SpaceWidget(),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 80.0),
                              child: RunTestWidget(
                                onTap: () {
                                  startTest();
                                },
                              ),
                            ),
                          ],
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: SizedBox(
                            height: 400.0,
                            child: PageView(
                              controller: pageController,
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "Download Speed",
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30.0,
                                      ),
                                    ),
                                    SpaceWidget(),
                                    SpeedGaugeWidget(
                                      value: _downloadRate,
                                      unit: _unit,
                                      pointerColor: Colors.cyanAccent,
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "Upload Speed",
                                      style: TextStyle(
                                        color: Colors.purpleAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30.0,
                                      ),
                                    ),
                                    SpaceWidget(),
                                    SpeedGaugeWidget(
                                      value: _uploadRate,
                                      unit: _unit,
                                      pointerColor: Colors.cyanAccent,
                                      enableLoadingAnimation: false,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    SpaceWidget(),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.public,
                              color: Colors.cyanAccent,
                              size: 30.0,
                            ),
                            SpaceWidget(),
                            Text(
                              "IP Adresse",
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SpaceWidget(),
                            Text(
                              _ip ?? "...",
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SpaceWidget(),
                  ],
                ),
              ),
    );
  }

  Future<void> startTest() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _runTest = true;
        _runTestIsComplete = false;
      });

      await internetSpeedTest.startTesting(
        onCompleted: (download, upload) {
          setState(() {
            _runTestIsComplete = true;
            _finalDownloadRate = download.transferRate;
            _finalUploadRate = upload.transferRate;
          });
        },
        onProgress: (percent, data) {
          setState(() {
            if (data.type == TestType.download) {
              _downloadRate = data.transferRate;
              pageController.animateTo(
                0,
                duration: Duration(milliseconds: 100),
                curve: Curves.decelerate,
              );
            } else {
              _uploadRate = data.transferRate;
              pageController.animateTo(
                1,
                duration: Duration(milliseconds: 100),
                curve: Curves.decelerate,
              );
            }
          });
        },
        onDefaultServerSelectionInProgress: () {
          setState(() {
            _isServerSelectionInProgress = true;
          });
        },
        onDefaultServerSelectionDone: (client) {
          setState(() {
            _isServerSelectionInProgress = true;
            _ip = client?.ip;
          });
        },
        onError: (errorMessage, speedTestError) {
          reset();
        },
        onCancel: () {
          reset();
        },
      );
    });
  }

  void reset() {
    setState(() {
      _downloadRate = 0;
      _uploadRate = 0;
      _finalUploadRate = 0;
      _finalDownloadRate = 0;
      _ip = null;
      _runTest = false;
    });
  }
}
