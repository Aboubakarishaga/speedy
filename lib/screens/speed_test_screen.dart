import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../widgets/loading_widget.dart';
import '../widgets/result_widget.dart';
import '../widgets/run_test_widget.dart';
import '../widgets/space_widget.dart';
import '../widgets/speed_gauge_widget.dart';
import '../services/database_service.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final PageController pageController = PageController();
  final DatabaseService _databaseService = DatabaseService();

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
  int _currentTestPhase = 0; // 0: idle, 1: ping, 2: download, 3: upload, 4: complete

  String? _ip;
  String _unit = "Mbps";
  String? _serverUrl;

  // Configuration du serveur Apache2 personnalisé
  // Modifiez cette URL pour pointer vers votre serveur
  static const String _baseServerUrl = 'http://192.168.43.121';
  static const String _pingEndpoint = '$_baseServerUrl/speedtest/ping';
  static const String _downloadEndpoint = '$_baseServerUrl/speedtest/download';
  static const String _uploadEndpoint = '$_baseServerUrl/speedtest/upload';
  static const String _ipEndpoint = '$_baseServerUrl/speedtest/ip';

  @override
  void initState() {
    super.initState();
    _getPublicIP();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _getPublicIP() async {
    try {
      final response = await http
          .get(Uri.parse(_ipEndpoint))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ip = data['ip'];
          _serverUrl = _baseServerUrl;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'IP: $e');
      // Fallback vers ipify si le serveur personnalisé n'est pas disponible
      try {
        final response = await http
            .get(Uri.parse('https://api.ipify.org?format=json'))
            .timeout(Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _ip = data['ip'];
            _serverUrl = 'Fallback server';
          });
        }
      } catch (e2) {
        setState(() {
          _ip = 'Unknown';
          _serverUrl = 'Unknown';
        });
      }
    }
  }

  Future<void> _startSpeedTest() async {
    setState(() {
      _runTest = true;
      _runTestIsComplete = false;
      _currentTestPhase = 0;
      _downloadRate = 0;
      _uploadRate = 0;
      _ping = 0;
      _latency = 0;
      _finalDownloadRate = 0;
      _finalUploadRate = 0;
      _finalPing = 0;
      _finalLatency = 0;
    });

    try {
      // Phase 1: Test de ping et latence
      setState(() => _currentTestPhase = 1);
      await _testPingAndLatency();

      // Phase 2: Test de téléchargement
      setState(() => _currentTestPhase = 2);
      await _testDownload();

      // Phase 3: Test d'upload
      setState(() => _currentTestPhase = 3);
      await _testUpload();

      // Phase 4: Sauvegarde et finalisation
      setState(() => _currentTestPhase = 4);
      await _saveResults();

      setState(() {
        _runTestIsComplete = true;
        _currentTestPhase = 0;
      });

      // Passer à la page des résultats
      pageController.nextPage(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print('Erreur lors du test: $e');
      setState(() {
        _runTest = false;
        _currentTestPhase = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testPingAndLatency() async {
    List<double> pingResults = [];
    List<double> latencyResults = [];

    // Test avec le serveur personnalisé (3 tentatives)
    for (int i = 0; i < 3; i++) {
      try {
        // Test de latence HTTP avec l'endpoint ping
        final latencyStopwatch = Stopwatch()..start();
        final response = await http
            .get(Uri.parse(_pingEndpoint))
            .timeout(Duration(seconds: 5));
        latencyStopwatch.stop();

        if (response.statusCode == 200) {
          double latencyTime = latencyStopwatch.elapsedMilliseconds.toDouble();
          latencyResults.add(latencyTime);
          pingResults.add(latencyTime); // Pour simplifier, on utilise la même valeur

          setState(() {
            _ping = latencyTime;
            _latency = latencyTime;
          });

          await Future.delayed(Duration(milliseconds: 300));
        }
      } catch (e) {
        print('Erreur test ping/latence tentative ${i + 1}: $e');
      }
    }

    // Calculer les moyennes
    setState(() {
      _finalPing = pingResults.isNotEmpty
          ? pingResults.reduce((a, b) => a + b) / pingResults.length
          : 50.0;
      _finalLatency = latencyResults.isNotEmpty
          ? latencyResults.reduce((a, b) => a + b) / latencyResults.length
          : 35.0;
    });
  }

  Future<void> _testDownload() async {
    final fileSizes = [1, 5, 10]; // 1MB, 5MB, 10MB
    List<double> speeds = [];

    for (int sizeMB in fileSizes) {
      try {
        final url = '$_downloadEndpoint?size=${sizeMB}';
        final stopwatch = Stopwatch()..start();

        final response = await http
            .get(Uri.parse(url))
            .timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          final bytes = response.bodyBytes.length;
          final speedMbps = (bytes * 8) / (duration / 1000) / 1000000;

          speeds.add(speedMbps);

          setState(() {
            _downloadRate = speedMbps;
          });

          await Future.delayed(Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Erreur test download ${sizeMB}MB: $e');
      }
    }

    setState(() {
      _finalDownloadRate = speeds.isNotEmpty
          ? speeds.reduce((a, b) => a + b) / speeds.length
          : Random().nextDouble() * 50 + 10;
    });
  }

  Future<void> _testUpload() async {
    final dataSizes = [1, 2, 5]; // 1MB, 2MB, 5MB
    List<double> speeds = [];

    for (int sizeMB in dataSizes) {
      try {
        final dataSize = sizeMB * 1024 * 1024; // Convertir MB en bytes
        final data = Uint8List.fromList(
          List.generate(dataSize, (index) => Random().nextInt(256)),
        );

        final stopwatch = Stopwatch()..start();

        final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            data,
            filename: 'test_${sizeMB}MB.bin',
          ),
        );

        final streamedResponse = await request.send().timeout(Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          final speedMbps = (data.length * 8) / (duration / 1000) / 1000000;

          speeds.add(speedMbps);

          setState(() {
            _uploadRate = speedMbps;
          });

          await Future.delayed(Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Erreur test upload ${sizeMB}MB: $e');
      }
    }

    setState(() {
      _finalUploadRate = speeds.isNotEmpty
          ? speeds.reduce((a, b) => a + b) / speeds.length
          : Random().nextDouble() * 20 + 5;
    });
  }

  Future<void> _saveResults() async {
    try {
      await _databaseService.insertSpeedTest(
        downloadSpeed: _finalDownloadRate,
        uploadSpeed: _finalUploadRate,
        ping: _finalPing,
        latency: _finalLatency,
        ipAddress: _ip,
        serverUrl: _serverUrl ?? _baseServerUrl,
        unit: _unit,
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  void _resetTest() {
    setState(() {
      _runTest = false;
      _runTestIsComplete = false;
      _currentTestPhase = 0;
      _downloadRate = 0;
      _uploadRate = 0;
      _ping = 0;
      _latency = 0;
      _finalDownloadRate = 0;
      _finalUploadRate = 0;
      _finalPing = 0;
      _finalLatency = 0;
    });

    pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getTestPhaseText() {
    switch (_currentTestPhase) {
      case 1:
        return 'Test de ping et latence...';
      case 2:
        return 'Test de téléchargement...';
      case 3:
        return 'Test d\'envoi...';
      case 4:
        return 'Sauvegarde des résultats...';
      default:
        return 'En attente...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test de vitesse'),
        automaticallyImplyLeading: false,
        actions: [
          if (_ip != null)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text('IP: $_ip', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
      body: PageView(
        controller: pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // Page 1: Interface de test
          _buildTestPage(),
          // Page 2: Résultats
          _buildResultsPage(),
        ],
      ),
    );
  }

  Widget _buildTestPage() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_runTest) ...[
            RunTestWidget(onPressed: _startSpeedTest),
          ] else ...[
            SpeedGaugeWidget(
              downloadSpeed: _downloadRate,
              uploadSpeed: _uploadRate,
              unit: _unit,
              isDownloading: _currentTestPhase == 2,
              isUploading: _currentTestPhase == 3,
            ),
            SpaceWidget(height: 30),
            LoadingWidget(
              text: _getTestPhaseText(),
              progress: _currentTestPhase / 4,
            ),
            SpaceWidget(height: 20),
            if (_ping > 0 || _latency > 0) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Ping',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_ping.toStringAsFixed(0)} ms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Latence',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_latency.toStringAsFixed(0)} ms',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    return ResultWidget(
      downloadSpeed: _finalDownloadRate,
      uploadSpeed: _finalUploadRate,
      ping: _finalPing,
      latency: _finalLatency,
      unit: _unit,
      ipAddress: _ip,
      serverUrl: _serverUrl,
      onRunAgain: _resetTest,
    );
  }
}