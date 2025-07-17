import 'package:flutter/material.dart';

class ResultWidget extends StatelessWidget {
  final double downloadRate;
  final double uploadRate;
  final double ping;
  final double latency;
  final String unit;

  const ResultWidget({
    required this.downloadRate,
    required this.uploadRate,
    required this.ping,
    required this.latency,
    required this.unit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Résultats du test",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 24),
            _buildMetricCard(
              context,
              "Téléchargement",
              downloadRate,
              Icons.arrow_circle_down,
              Colors.cyanAccent,
              unit,
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              context,
              "Envoi",
              uploadRate,
              Icons.arrow_circle_up,
              Colors.purpleAccent,
              unit,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    "Ping",
                    ping,
                    Icons.network_ping,
                    Colors.orangeAccent,
                    "ms",
                    isCompact: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    "Latence",
                    latency,
                    Icons.speed,
                    Colors.greenAccent,
                    "ms",
                    isCompact: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      BuildContext context,
      String title,
      double value,
      IconData icon,
      Color color,
      String unit, {
        bool isCompact = false,
      }) {
    return Card(
      elevation: isCompact ? 4 : 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: isCompact ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value == 0 ? "..." : "${value.toStringAsFixed(2)} $unit",
              style: TextStyle(
                fontSize: isCompact ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: value == 0 ? 0 : (value / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
