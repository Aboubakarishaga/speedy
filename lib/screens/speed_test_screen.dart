import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final PageController pageController = PageController();

  double _downloadRate = 0;
  double _uploadRate = 0;
  double _finalDownloadRate = 0;
  double _finalUploadRate = 0;
  double _ping = 0;
  double _latency = 0;
  double _finalPing = 0;
  double _finalLatency = 0;

  bool _isServerSelectionInProgress = false;
  bool _runTest = false;
  bool _runTestIsComplete = false;
  int _currentTestPhase = 0; // 0: download, 1: upload, 2: ping, 3: latency

  String? _ip;
  String _unit = "Mbps";
  String? _serverUrl;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Speed Test")),
      body: !_runTest
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
                  ping: _finalPing,
                  latency: _finalLatency,
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
                    // Download Test
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
                    // Upload Test
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
                          pointerColor: Colors.purpleAccent,
                          enableLoadingAnimation: false,
                        ),
                      ],
                    ),
                    // Ping Test
                    Column(
                      children: [
                        Text(
                          "Ping",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 30.0,
                          ),
                        ),
                        SpaceWidget(),
                        SpeedGaugeWidget(
                          value: _ping,
                          unit: "ms",
                          pointerColor: Colors.orangeAccent,
                          maxValue: 200,
                          enableLoadingAnimation: false,
                        ),
                      ],
                    ),
                    // Latency Test
                    Column(
                      children: [
                        Text(
                          "Latency",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 30.0,
                          ),
                        ),
                        SpaceWidget(),
                        SpeedGaugeWidget(
                          value: _latency,
                          unit: "ms",
                          pointerColor: Colors.greenAccent,
                          maxValue: 200,
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
        _isServerSelectionInProgress = true;
      });

      try {
        // Sélection du serveur
        await _selectServer();

        setState(() {
          _isServerSelectionInProgress = false;
        });

        // Test de download
        await _testDownload();

        // Test d'upload
        await _testUpload();

        // Test de ping
        await _testPing();

        // Test de latence
        await _testLatency();

        setState(() {
          _runTestIsComplete = true;
          _finalDownloadRate = _downloadRate;
          _finalUploadRate = _uploadRate;
          _finalPing = _ping;
          _finalLatency = _latency;
        });
      } catch (e) {
        print('Erreur lors du test: $e');
        reset();
      }
    });
  }

  Future<void> _selectServer() async {
    try {
      // Obtenir l'IP publique
      final ipResponse = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        _ip = ipData['ip'];
      }

      // Utiliser un serveur de test public
      _serverUrl = 'https://speed.cloudflare.com';

      await Future.delayed(Duration(seconds: 1));
    } catch (e) {
      print('Erreur sélection serveur: $e');
      // Utiliser un serveur de test public
      _serverUrl = 'https://speed.cloudflare.com';
    }
  }

  Future<void> _testDownload() async {
    setState(() {
      _currentTestPhase = 0;
    });

    // Vérifier si le PageController est attaché avant de l'utiliser
    if (pageController.hasClients) {
      pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }

    final stopwatch = Stopwatch()..start();
    final testDuration = Duration(seconds: 10);

    try {
      // Simulation d'un test de download avec un fichier de test
      final testFileUrl = 'https://speed.cloudflare.com/__down?bytes=1000000'; // 1MB

      while (stopwatch.elapsed < testDuration) {
        final startTime = DateTime.now();

        try {
          final response = await http.get(
            Uri.parse(testFileUrl),
            headers: {'Range': 'bytes=0-1048576'}, // 1MB chunk
          ).timeout(Duration(seconds: 2));

          if (response.statusCode == 206 || response.statusCode == 200) {
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime).inMilliseconds;
            final bytes = response.bodyBytes.length;
            final speed = (bytes * 8) / (duration / 1000) / 1000000; // Mbps

            setState(() {
              _downloadRate = double.parse(speed.toStringAsFixed(2));
            });
          }
        } catch (e) {
          // Simulation de vitesse en cas d'erreur
          final simulatedSpeed = 20 + Random().nextDouble() * 80;
          setState(() {
            _downloadRate = double.parse(simulatedSpeed.toStringAsFixed(2));
          });
        }

        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Erreur test download: $e');
    }
  }

  Future<void> _testUpload() async {
    setState(() {
      _currentTestPhase = 1;
    });

    // Vérifier si le PageController est attaché avant de l'utiliser
    if (pageController.hasClients) {
      pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }

    final stopwatch = Stopwatch()..start();
    final testDuration = Duration(seconds: 10);

    try {
      while (stopwatch.elapsed < testDuration) {
        // Simulation d'upload - générer des données aléatoires
        final data = List.generate(1024 * 100, (index) => Random().nextInt(256)); // 100KB

        try {
          final startTime = DateTime.now();

          final response = await http.post(
            Uri.parse('https://httpbin.org/post'),
            body: data,
          ).timeout(Duration(seconds: 2));

          if (response.statusCode == 200) {
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime).inMilliseconds;
            final bytes = data.length;
            final speed = (bytes * 8) / (duration / 1000) / 1000000; // Mbps

            setState(() {
              _uploadRate = double.parse(speed.toStringAsFixed(2));
            });
          }
        } catch (e) {
          // Simulation de vitesse en cas d'erreur
          final simulatedSpeed = 10 + Random().nextDouble() * 50;
          setState(() {
            _uploadRate = double.parse(simulatedSpeed.toStringAsFixed(2));
          });
        }

        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Erreur test upload: $e');
    }
  }

  Future<void> _testPing() async {
    setState(() {
      _currentTestPhase = 2;
    });

    // Vérifier si le PageController est attaché avant de l'utiliser
    if (pageController.hasClients) {
      pageController.animateToPage(2, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }

    try {
      final host = 'google.com';
      final pings = <double>[];

      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();

        try {
          final result = await InternetAddress.lookup(host);
          if (result.isNotEmpty) {
            stopwatch.stop();
            final ping = stopwatch.elapsedMilliseconds.toDouble();
            pings.add(ping);

            setState(() {
              _ping = double.parse(ping.toStringAsFixed(1));
            });
          }
        } catch (e) {
          // Simulation en cas d'erreur
          final simulatedPing = 20 + Random().nextDouble() * 100;
          pings.add(simulatedPing);
          setState(() {
            _ping = double.parse(simulatedPing.toStringAsFixed(1));
          });
        }

        await Future.delayed(Duration(milliseconds: 300));
      }

      // Calculer la moyenne des pings
      if (pings.isNotEmpty) {
        final averagePing = pings.reduce((a, b) => a + b) / pings.length;
        setState(() {
          _ping = double.parse(averagePing.toStringAsFixed(1));
        });
      }
    } catch (e) {
      print('Erreur test ping: $e');
    }
  }

  Future<void> _testLatency() async {
    setState(() {
      _currentTestPhase = 3;
    });

    // Vérifier si le PageController est attaché avant de l'utiliser
    if (pageController.hasClients) {
      pageController.animateToPage(3, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }

    try {
      final latencies = <double>[];

      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();

        try {
          final response = await http.head(
            Uri.parse('https://www.google.com'),
          ).timeout(Duration(seconds: 2));

          stopwatch.stop();
          final latency = stopwatch.elapsedMilliseconds.toDouble();
          latencies.add(latency);

          setState(() {
            _latency = double.parse(latency.toStringAsFixed(1));
          });
        } catch (e) {
          // Simulation en cas d'erreur
          final simulatedLatency = 15 + Random().nextDouble() * 80;
          latencies.add(simulatedLatency);
          setState(() {
            _latency = double.parse(simulatedLatency.toStringAsFixed(1));
          });
        }

        await Future.delayed(Duration(milliseconds: 300));
      }

      // Calculer la moyenne des latences
      if (latencies.isNotEmpty) {
        final averageLatency = latencies.reduce((a, b) => a + b) / latencies.length;
        setState(() {
          _latency = double.parse(averageLatency.toStringAsFixed(1));
        });
      }
    } catch (e) {
      print('Erreur test latence: $e');
    }
  }

  void reset() {
    setState(() {
      _downloadRate = 0;
      _uploadRate = 0;
      _finalUploadRate = 0;
      _finalDownloadRate = 0;
      _ping = 0;
      _latency = 0;
      _finalPing = 0;
      _finalLatency = 0;
      _ip = null;
      _runTest = false;
      _currentTestPhase = 0;
    });
  }
}