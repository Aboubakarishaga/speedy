import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speedy/widgets/selection_header.dart';
import 'package:speedy/widgets/settings_tile.dart';
import 'package:speedy/widgets/switch_tile.dart';
import '../providers/provider.dart';
import '../services/database_service.dart';
import '../services/auto_test_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _units = ['Kbps', 'Mbps', 'Gbps'];
  final List<String> _themes = ['Sombre', 'Clair', 'Système'];
  final List<int> _autoTestIntervals = [15, 30, 60, 120, 360, 720]; // en minutes

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
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Sombre'),
              value: ThemeMode.dark,
              groupValue: prefs.themeMode,
              onChanged: (value) {
                prefs.setThemeMode(value!);
                Navigator.pop(context);
              },
              activeColor: Colors.cyanAccent,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Clair'),
              value: ThemeMode.light,
              groupValue: prefs.themeMode,
              onChanged: (value) {
                prefs.setThemeMode(value!);
                Navigator.pop(context);
              },
              activeColor: Colors.cyanAccent,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Système'),
              value: ThemeMode.system,
              groupValue: prefs.themeMode,
              onChanged: (value) {
                prefs.setThemeMode(value!);
                Navigator.pop(context);
              },
              activeColor: Colors.cyanAccent,
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialog(PreferencesProvider prefs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Intervalle des tests automatiques'),
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
        title: Text('Effacer l\'historique'),
        content: Text('Êtes-vous sûr de vouloir supprimer tout l\'historique des tests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseService().deleteAllSpeedTests();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Historique supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression'),
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
        content: Text('Fonctionnalité de sauvegarde à venir...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('À propos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Speed Test App'),
            Text('Version: 1.0.0'),
            SizedBox(height: 10),
            Text('Application de test de vitesse Internet'),
            Text('Développé avec Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Questions fréquentes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('• Comment effectuer un test?'),
              Text('  Appuyez sur le bouton "GO" sur l\'écran principal.'),
              SizedBox(height: 8),
              Text('• Pourquoi mes résultats varient-ils?'),
              Text('  La vitesse Internet peut varier selon l\'heure, la charge du réseau et votre position.'),
              SizedBox(height: 8),
              Text('• Comment activer les tests automatiques?'),
              Text('  Allez dans Paramètres > Test automatique et activez l\'option.'),
              SizedBox(height: 8),
              Text('• Que signifient Download/Upload?'),
              Text('  Download: vitesse de réception des données'),
              Text('  Upload: vitesse d\'envoi des données'),
              SizedBox(height: 15),
              Text(
                'Contact:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text('Email: support@speedtestapp.com'),
              Text('Site web: www.speedtestapp.com'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
              Text(
                'Collecte des données:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Nous collectons uniquement les résultats de vos tests de vitesse'),
              Text('• Aucune donnée personnelle n\'est collectée'),
              Text('• Les données sont stockées localement sur votre appareil'),
              SizedBox(height: 15),
              Text(
                'Utilisation des données:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Les données servent uniquement à l\'historique des tests et aussi à facilité la prédiction des performances future du réseau.'),
              Text('• Aucun partage avec des tiers'),
              Text('• Vous pouvez supprimer vos données à tout moment'),
              SizedBox(height: 15),
              Text(
                'Sécurité:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Toutes les données sont chiffrées'),
              Text('• Aucune transmission de données sensibles'),
              Text('• Respect des standards de sécurité'),
              SizedBox(height: 15),
              Text(
                'Vos droits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Droit d\'accès à vos données'),
              Text('• Droit de suppression'),
              Text('• Droit de portabilité'),
              SizedBox(height: 10),
              Text('Dernière mise à jour: Juin 2025'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('J\'ai compris'),
          ),
        ],
      ),
    );
  }
}