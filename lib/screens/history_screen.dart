import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/csv_service.dart';
import '../widgets/space_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _speedTests = [];
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadSpeedTests();
  }

  Future<void> _loadSpeedTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tests = await _databaseService.getAllSpeedTests();
      setState(() {
        _speedTests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement de l\'historique: $e');
    }
  }

  Future<void> _exportToCsv() async {
    try {
      if (_speedTests.isEmpty) {
        _showErrorSnackBar('Aucune donnée à exporter');
        return;
      }

      // Demander les permissions si nécessaire
      bool hasPermission = await CsvService.requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('Permission de stockage requise pour l\'export');
        return;
      }

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Export en cours...'),
            ],
          ),
        ),
      );

      await CsvService.exportToCsv(_speedTests);

      // Fermer le dialog de chargement
      Navigator.of(context).pop();

      _showSuccessSnackBar('Export CSV réussi!');
    } catch (e) {
      // Fermer le dialog de chargement en cas d'erreur
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de l\'export: $e');
    }
  }

  Future<void> _deleteTest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer ce Test de l\'historique?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteSpeedTest(id);
        await _loadSpeedTests();
        _showSuccessSnackBar('Test supprimé avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression: $e');
      }
    }
  }

  Future<void> _deleteAllTests() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer tout l\'historique?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteAllSpeedTests();
        await _loadSpeedTests();
        _showSuccessSnackBar('Historique supprimé avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des tests'),
        automaticallyImplyLeading: false,
        actions: [
          if (_speedTests.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.file_download),
              onPressed: _exportToCsv,
              tooltip: 'Exporter en CSV',
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _deleteAllTests,
              tooltip: 'Supprimer tout',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _speedTests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun test effectué',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Effectuez votre premier test de vitesse',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadSpeedTests,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _speedTests.length,
          itemBuilder: (context, index) {
            final test = _speedTests[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(test['test_date']),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _formatTime(test['test_date']),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTest(test['id']),
                        ),
                      ],
                    ),
                    SpaceWidget(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpeedInfo(
                            'Download',
                            test['download_speed'],
                            test['unit'] ?? 'Mbps',
                            Icons.download,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildSpeedInfo(
                            'Upload',
                            test['upload_speed'],
                            test['unit'] ?? 'Mbps',
                            Icons.upload,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SpaceWidget(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpeedInfo(
                            'Ping',
                            test['ping'],
                            'ms',
                            Icons.speed,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildSpeedInfo(
                            'Latence',
                            test['latency'],
                            'ms',
                            Icons.access_time,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    if (test['ip_address'] != null || test['server_url'] != null) ...[
                      SpaceWidget(height: 12),
                      Divider(),
                      SpaceWidget(height: 8),
                      if (test['ip_address'] != null)
                        Row(
                          children: [
                            Icon(Icons.public, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'IP: ${test['ip_address']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      if (test['server_url'] != null) ...[
                        SizedBox(height: 4),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSpeedTests,
        tooltip: 'Actualiser',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSpeedInfo(String label, dynamic value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '${value?.toStringAsFixed(2) ?? '0.00'} $unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
