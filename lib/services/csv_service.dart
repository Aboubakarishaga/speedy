import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class CsvService {
  static Future<String> generateCsvContent(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return '';

    // En-têtes CSV
    String csv = 'Date,Heure,Download (Mbps),Upload (Mbps),Ping (ms),Latence (ms),Adresse IP,Serveur\n';

    // Données
    for (var test in data) {
      final DateTime date = DateTime.parse(test['test_date']);
      final String formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      final String formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

      csv += '"$formattedDate","$formattedTime",';
      csv += '"${test['download_speed']}","${test['upload_speed']}",';
      csv += '"${test['ping']}","${test['latency']}",';
      csv += '"${test['ip_address'] ?? 'N/A'}","${test['server_url'] ?? 'N/A'}"\n';
    }

    return csv;
  }

  static Future<void> exportToCsv(List<Map<String, dynamic>> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Aucune donnée à exporter');
      }

      // Générer le contenu CSV
      String csvContent = await generateCsvContent(data);

      // Obtenir le répertoire des documents
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'speed_test_history_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      // Écrire le fichier
      await file.writeAsString(csvContent);

      // Partager le fichier
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Historique des tests de vitesse',
        subject: 'Export CSV - Speed Test',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'export CSV: $e');
    }
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    return true; // iOS ne nécessite pas de permission pour les documents de l'app
  }
}