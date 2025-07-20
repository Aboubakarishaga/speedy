import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class AutoTestService {
  static final AutoTestService _instance = AutoTestService._internal();
  factory AutoTestService() => _instance;
  AutoTestService._internal();

  Timer? _timer;
  bool _isRunning = false;
  final DatabaseService _databaseService = DatabaseService();

  // URLs des serveurs de test
  static const String _cloudflareDownloadUrl = 'https://speed.cloudflare.com/__down';
  static const String _ipifyUrl = 'https://api.ipify.org?format=json';

  bool get isRunning => _isRunning;

  void startAutoTest(int intervalMinutes) {
    stopAutoTest();

    _isRunning = true;
    _timer = Timer.periodic(
      Duration(minutes: intervalMinutes),
          (timer) => _performAutoTest(),
    );

    print('Test automatique démarré - Intervalle: ${intervalMinutes} minutes');
  }

  void stopAutoTest() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('Test automatique arrêté');
  }

  Future<void> _performAutoTest() async {
    try {
      print('Exécution du test automatique...');

      final results = await _runSpeedTest();

      await _databaseService.insertSpeedTest(
        downloadSpeed: results['download']!,
        uploadSpeed: results['upload']!,
        ping: results['ping']!,
        latency: results['latency']!,
        ipAddress: results['ip'],
        serverUrl: 'Multiple servers (Cloudflare, HTTPBin)',
        unit: 'Mbps',
      );

      print('Test automatique terminé avec succès');
    } catch (e) {
      print('Erreur lors du test automatique: $e');
    }
  }

  Future<Map<String, dynamic>> _runSpeedTest() async {
    // Obtenir l'IP publique
    String? ip = await _getPublicIP();

    // Test de téléchargement
    double downloadSpeed = await _testDownload();

    // Test d'upload
    double uploadSpeed = await _testUpload();

    // Test de ping et latence
    Map<String, double> pingResults = await _testPingAndLatency();

    return {
      'download': downloadSpeed,
      'upload': uploadSpeed,
      'ping': pingResults['ping']!,
      'latency': pingResults['latency']!,
      'ip': ip,
    };
  }

  Future<String?> _getPublicIP() async {
    try {
      final response = await http.get(
        Uri.parse(_ipifyUrl),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'];
      }
    } catch (e) {
      print('Erreur lors de l\'obtention de l\'IP: $e');
    }
    return 'Unknown';
  }

  Future<double> _testDownload() async {
    try {
      final speeds = <double>[];

      // Test avec différentes tailles de fichiers
      final testSizes = [1000000, 5000000, 10000000]; // 1MB, 5MB, 10MB

      for (int size in testSizes) {
        try {
          final stopwatch = Stopwatch()..start();

          final response = await http.get(
            Uri.parse('$_cloudflareDownloadUrl?bytes=$size'),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            stopwatch.stop();
            final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
            final bytesReceived = response.bodyBytes.length;

            // Calculer la vitesse en Mbps
            final speedMbps = (bytesReceived * 8) / (durationInSeconds * 1000000);
            speeds.add(speedMbps);

            print('Download test: ${bytesReceived} bytes in ${durationInSeconds}s = ${speedMbps.toStringAsFixed(2)} Mbps');
          }
        } catch (e) {
          print('Erreur test download: $e');
          continue;
        }
      }

      if (speeds.isNotEmpty) {
        // Retourner la vitesse la plus élevée
        return speeds.reduce(max);
      }
    } catch (e) {
      print('Erreur générale download: $e');
    }

    return 0.0;
  }

  Future<double> _testUpload() async {
    try {
      final speeds = <double>[];

      // Test avec différentes tailles de données
      final testSizes = [500000, 1000000, 2000000]; // 500KB, 1MB, 2MB

      for (int size in testSizes) {
        try {
          // Créer des données aléatoires à envoyer
          final data = Uint8List.fromList(
              List.generate(size, (index) => Random().nextInt(256))
          );

          final stopwatch = Stopwatch()..start();

          final response = await http.post(
            Uri.parse('https://httpbin.org/post'),
            body: data,
            headers: {
              'Content-Type': 'application/octet-stream',
            },
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            stopwatch.stop();
            final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;

            if (durationInSeconds > 0) {
              // Calculer la vitesse en Mbps
              final speedMbps = (size * 8) / (durationInSeconds * 1000000);
              speeds.add(speedMbps);

              print('Upload test: ${size} bytes in ${durationInSeconds}s = ${speedMbps.toStringAsFixed(2)} Mbps');
            }
          }
        } catch (e) {
          print('Erreur test upload: $e');
          continue;
        }
      }

      if (speeds.isNotEmpty) {
        return speeds.reduce(max);
      }
    } catch (e) {
      print('Erreur générale upload: $e');
    }

    return 0.0;
  }

  Future<Map<String, double>> _testPingAndLatency() async {
    final pingTimes = <double>[];
    final latencyTimes = <double>[];

    // URLs de test pour ping et latence
    final testHosts = [
      'speed.cloudflare.com',
      'www.google.com',
      'www.github.com',
      'httpbin.org',
    ];

    for (String host in testHosts) {
      for (int i = 0; i < 3; i++) {
        try {
          // Test de ping (DNS lookup + connexion)
          final pingStopwatch = Stopwatch()..start();
          final addresses = await InternetAddress.lookup(host);
          if (addresses.isNotEmpty) {
            pingStopwatch.stop();
            pingTimes.add(pingStopwatch.elapsedMilliseconds.toDouble());
          }

          // Test de latence (requête HTTP complète)
          final latencyStopwatch = Stopwatch()..start();
          final response = await http.head(
            Uri.parse('https://$host'),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode < 400) {
            latencyStopwatch.stop();
            latencyTimes.add(latencyStopwatch.elapsedMilliseconds.toDouble());
          }

        } catch (e) {
          print('Erreur test ping/latence pour $host: $e');
          continue;
        }

        // Pause entre les tests
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    double avgPing = pingTimes.isEmpty ? 0.0 : _calculateMedian(pingTimes);
    double avgLatency = latencyTimes.isEmpty ? 0.0 : _calculateMedian(latencyTimes);

    return {
      'ping': avgPing,
      'latency': avgLatency,
    };
  }

  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;

    values.sort();
    final middle = values.length ~/ 2;

    if (values.length % 2 == 0) {
      return (values[middle - 1] + values[middle]) / 2.0;
    } else {
      return values[middle];
    }
  }
}
