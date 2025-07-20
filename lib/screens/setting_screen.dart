import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speedy/widgets/selection_header.dart';
import 'package:speedy/widgets/settings_tile.dart';
import 'package:speedy/widgets/switch_tile.dart';
import '../providers/provider.dart';
import '../services/database_service.dart';
import '../services/auto_test_service.dart';
import '../services/csv_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _units = ['Kbps', 'Mbps', 'Gbps'];
  final List<String> _themes = ['Sombre', 'Clair', 'Système'];
  final List<int> _autoTestIntervals = [15, 30, 60, 120, 360, 720]; // en minutes
  final DatabaseService _databaseService = DatabaseService();

  String _getIntervalDisplayName(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes < 1440) {
      return '${(minutes / 60).round()} heure${(minutes / 60).round() > 1 ? 's' : ''}';
    } else {
      return '${(minutes / 1440).round()} jour${(minutes / 1440).round() > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<PreferencesProvider>(
        builder: (context, prefs, child) {
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              SelectionHeader( title: 'Général',),
              SettingsTile(
                icon: Icons.speed,
                title: 'Unité de vitesse',
                subtitle: prefs.speedUnit,
                onTap: () => _showUnitDialog(prefs),
              ),
              SettingsTile(
                icon: Icons.color_lens,
                title: 'Thème',
                subtitle: prefs.themeDisplayName,
                onTap: () => _showThemeDialog(prefs),
              ),

              SizedBox(height: 20),
              SelectionHeader(title: 'Notifications'),
              SwitchTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Recevoir des notifications de test',
                value: prefs.notificationsEnabled,
                onChanged: (value) => prefs.setNotificationsEnabled(value),
              ),

              SizedBox(height: 20),
              SelectionHeader(title: 'Test automatique'),
              SwitchTile(
                icon: Icons.auto_mode,
                title: 'Test automatique',
                subtitle: 'Effectuer des tests périodiques',
                value: prefs.autoTestEnabled,
                onChanged: (value) => prefs.setAutoTestEnabled(value),
              ),
              if (prefs.autoTestEnabled) ...[
                SettingsTile(
                  icon: Icons.schedule,
                  title: 'Intervalle de test',
                  subtitle: _getIntervalDisplayName(prefs.autoTestInterval),
                  onTap: () => _showIntervalDialog(prefs),
                ),
                Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      AutoTestService().isRunning ? Icons.play_circle : Icons.pause_circle,
                      color: AutoTestService().isRunning ? Colors.green : Colors.orange,
                    ),
                    title: Text('État du service'),
                    subtitle: Text(
                      AutoTestService().isRunning
                          ? 'Tests automatiques actifs'
                          : 'Tests automatiques en pause',
                    ),
                  ),
                ),
              ],

              SizedBox(height: 20),
              SelectionHeader(title: 'Données'),
              SettingsTile(
                icon: Icons.delete_sweep,
                title: 'Effacer l\'historique',
                subtitle: 'Supprimer tous les tests sauvegardés',
                onTap: () => _showClearHistoryDialog(),
              ),
              SettingsTile(
                icon: Icons.backup,
                title: 'Sauvegarde des données',
                subtitle: 'Exporter/Importer les données',
                onTap: () => _showBackupDialog(),
              ),

              SizedBox(height: 20),
              SelectionHeader(title: 'À propos'),
              SettingsTile(
                icon: Icons.info,
                title: 'Version de l\'application',
                subtitle: '1.0.0',
                onTap: () => _showAboutDialog(),
              ),
              SettingsTile(
                icon: Icons.help,
                title: 'Aide et support',
                subtitle: 'FAQ et contact',
                onTap: () => _showHelpDialog(),
              ),
              SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Politique de confidentialité',
                subtitle: 'Voir notre politique',
                onTap: () => _showPrivacyDialog(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUnitDialog(PreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir l\'unité de vitesse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _units.map((unit) => RadioListTile<String>(
            title: Text(unit),
            value: unit,
            groupValue: prefs.speedUnit,
            onChanged: (value) {
              prefs.setSpeedUnit(value!);
              Navigator.pop(context);
            },
            activeColor: Colors.cyanAccent,
          )).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(PreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _themes.asMap().entries.map((entry) {
            final index = entry.key;
            final theme = entry.value;
            return RadioListTile<int>(
              title: Text(theme),
              value: index,
              groupValue: prefs.themeMode.index,
              onChanged: (value) {
                prefs.setThemeMode(ThemeMode.values[value!]);
                Navigator.pop(context);
              },
              activeColor: Colors.cyanAccent,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showIntervalDialog(PreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Intervalle de test automatique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _autoTestIntervals.map((interval) => RadioListTile<int>(
            title: Text(_getIntervalDisplayName(interval)),
            value: interval,
            groupValue: prefs.autoTestInterval,
            onChanged: (value) {
              prefs.setAutoTestInterval(value!);
              Navigator.pop(context);
            },
            activeColor: Colors.cyanAccent,
          )).toList(),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer tout l\'historique des tests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _databaseService.deleteAllSpeedTests();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Historique supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sauvegarde des données'),
        content: Text('Voulez-vous exporter vos données de test en CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final tests = await _databaseService.getAllSpeedTests();
                if (tests.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Aucune donnée à exporter'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Afficher dialog de chargement
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

                await CsvService.exportToCsv(tests);

                // Fermer dialog de chargement
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export CSV réussi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Fermer dialog de chargement en cas d'erreur
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de l\'export: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Exporter'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('À propos de Speedy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Application de test de vitesse Internet'),
            SizedBox(height: 8),
            Text('Développé avec Flutter'),
            SizedBox(height: 8),
            Text('© 2024 Speedy App'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aide et support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Q: Comment fonctionne le test de vitesse?'),
            Text('R: L\'app teste votre connexion en téléchargeant et envoyant des données vers des serveurs fiables.'),
            SizedBox(height: 8),
            Text('Q: Puis-je programmer des tests automatiques?'),
            Text('R: Oui, activez les tests automatiques dans les paramètres.'),
            SizedBox(height: 16),
            Text('Contact:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('support@speedyapp.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Politique de confidentialité'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Collecte de données:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Résultats des tests de vitesse'),
              Text('• Adresse IP publique'),
              Text('• Horodatage des tests'),
              SizedBox(height: 12),
              Text('Utilisation:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Les données sont stockées localement'),
              Text('• Aucune donnée n\'est partagée avec des tiers'),
              Text('• Vous pouvez supprimer vos données à tout moment'),
              SizedBox(height: 12),
              Text('Sécurité:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• Connexions sécurisées (HTTPS)'),
              Text('• Aucun stockage de données personnelles'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

