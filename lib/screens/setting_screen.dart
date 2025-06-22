import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoTestEnabled = false;
  String _selectedUnit = 'Mbps';
  String _selectedTheme = 'Sombre';

  final List<String> _units = ['Mbps', 'Kbps', 'Gbps'];
  final List<String> _themes = ['Sombre', 'Clair', 'Système'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Général'),
          _buildSettingsTile(
            icon: Icons.speed,
            title: 'Unité de vitesse',
            subtitle: _selectedUnit,
            onTap: () => _showUnitDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.color_lens,
            title: 'Thème',
            subtitle: _selectedTheme,
            onTap: () => _showThemeDialog(),
          ),

          SizedBox(height: 20),
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Recevoir des notifications de test',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),

          SizedBox(height: 20),
          _buildSectionHeader('Test automatique'),
          _buildSwitchTile(
            icon: Icons.auto_mode,
            title: 'Test automatique',
            subtitle: 'Effectuer des tests périodiques',
            value: _autoTestEnabled,
            onChanged: (value) {
              setState(() {
                _autoTestEnabled = value;
              });
            },
          ),

          SizedBox(height: 20),
          _buildSectionHeader('Données'),
          _buildSettingsTile(
            icon: Icons.delete_sweep,
            title: 'Effacer l\'historique',
            subtitle: 'Supprimer tous les tests sauvegardés',
            onTap: () => _showClearHistoryDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.backup,
            title: 'Sauvegarde des données',
            subtitle: 'Exporter/Importer les données',
            onTap: () => _showBackupDialog(),
          ),

          SizedBox(height: 20),
          _buildSectionHeader('À propos'),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Version de l\'application',
            subtitle: '1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Aide et support',
            subtitle: 'FAQ et contact',
            onTap: () => _showHelpDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Politique de confidentialité',
            subtitle: 'Voir notre politique',
            onTap: () => _showPrivacyDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.cyanAccent,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.cyanAccent),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.cyanAccent,
      ),
    );
  }

  void _showUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir l\'unité de vitesse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _units.map((unit) => RadioListTile<String>(
            title: Text(unit),
            value: unit,
            groupValue: _selectedUnit,
            onChanged: (value) {
              setState(() {
                _selectedUnit = value!;
              });
              Navigator.pop(context);
            },
            activeColor: Colors.cyanAccent,
          )).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir le thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _themes.map((theme) => RadioListTile<String>(
            title: Text(theme),
            value: theme,
            groupValue: _selectedTheme,
            onChanged: (value) {
              setState(() {
                _selectedTheme = value!;
              });
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
    content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text('Questions fréquentes:'),
    SizedBox(height: 10),
    Text('• Comment effectuer un test?'),
    Text('• Que signifient les résultats?'),
    Text('• Comment exporter l\'historique?'),
    SizedBox(height: 10),
    Text('Contact: support@speedtest.com'),
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
              Text('Collecte des données:'),
              SizedBox(height: 8),
              Text('• Résultats des tests de vitesse'),
              Text('• Adresse IP publique'),
              Text('• Horodatage des tests'),
              SizedBox(height: 16),
              Text('Utilisation des données:'),
              SizedBox(height: 8),
              Text('• Amélioration de l\'application'),
              Text('• Historique personnel'),
              Text('• Statistiques anonymes'),
              SizedBox(height: 16),
              Text('Vos données restent privées et ne sont pas partagées avec des tiers.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}