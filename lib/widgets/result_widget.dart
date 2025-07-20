import 'package:flutter/material.dart';
import 'space_widget.dart';

class ResultWidget extends StatelessWidget {
  final double downloadSpeed;
  final double uploadSpeed;
  final double ping;
  final double latency;
  final String unit;
  final String? ipAddress;
  final String? serverUrl;
  final VoidCallback onRunAgain;

  const ResultWidget({
    Key? key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.latency,
    required this.unit,
    this.ipAddress,
    this.serverUrl,
    required this.onRunAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Résultats du test',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SpaceWidget(height: 30),

          // Résultats principaux
          Row(
            children: [
              Expanded(
                child: _buildSpeedCard(
                  'Téléchargement',
                  downloadSpeed,
                  unit,
                  Icons.download,
                  Colors.cyanAccent,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSpeedCard(
                  'Envoi',
                  uploadSpeed,
                  unit,
                  Icons.upload,
                  Colors.green,
                ),
              ),
            ],
          ),

          SpaceWidget(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSpeedCard(
                  'Ping',
                  ping,
                  'ms',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSpeedCard(
                  'Latence',
                  latency,
                  'ms',
                  Icons.access_time,
                  Colors.purple,
                ),
              ),
            ],
          ),

          SpaceWidget(height: 30),

          // Informations supplémentaires
          if (ipAddress != null || serverUrl != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations de connexion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SpaceWidget(height: 12),
                    if (ipAddress != null) ...[
                      Row(
                        children: [
                          Icon(Icons.public, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Adresse IP: $ipAddress'),
                        ],
                      ),
                      SpaceWidget(height: 8),
                    ],
                    if (serverUrl != null) ...[
                      Row(
                        children: [
                          Icon(Icons.dns, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Serveur: ${serverUrl!}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SpaceWidget(height: 20),
          ],

          // Évaluation de la connexion
          _buildConnectionEvaluation(),

          SpaceWidget(height: 30),

          // Bouton pour refaire un test
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onRunAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text(
                    'Refaire un test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard(String label, double value, String unit, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: color,
            ),
            SpaceWidget(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SpaceWidget(height: 4),
            Text(
              '${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionEvaluation() {
    String evaluation;
    Color evaluationColor;
    IconData evaluationIcon;

    // Évaluation basée sur la vitesse de téléchargement
    if (downloadSpeed >= 100) {
      evaluation = 'Excellente';
      evaluationColor = Colors.green;
      evaluationIcon = Icons.signal_wifi_4_bar;
    } else if (downloadSpeed >= 50) {
      evaluation = 'Très bonne';
      evaluationColor = Colors.lightGreen;
      evaluationIcon = Icons.signal_wifi_4_bar;
    } else if (downloadSpeed >= 25) {
      evaluation = 'Bonne';
      evaluationColor = Colors.orange;
      evaluationIcon = Icons.wifi;
    } else if (downloadSpeed >= 10) {
      evaluation = 'Moyenne';
      evaluationColor = Colors.deepOrange;
      evaluationIcon = Icons.wifi_2_bar;
    } else {
      evaluation = 'Faible';
      evaluationColor = Colors.red;
      evaluationIcon = Icons.wifi_1_bar;
    }

    return Card(
      color: evaluationColor.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              evaluationIcon,
              color: evaluationColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qualité de connexion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  evaluation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: evaluationColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
