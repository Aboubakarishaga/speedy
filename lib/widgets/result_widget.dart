import 'package:flutter/material.dart';
import 'space_widget.dart';

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
    return Column(
      children: [
        SpaceWidget(),
        Text(
          "Résultats",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 30.0,
          ),
        ),
        SpaceWidget(),
        // Download et Upload
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_circle_down, color: Colors.cyanAccent),
                    SpaceWidget(),
                    Text("Download $unit"),
                  ],
                ),
                SpaceWidget(),
                Text(
                  downloadRate == 0 ? "..." : downloadRate.toString(),
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 60.0, child: VerticalDivider()),
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_circle_up, color: Colors.purpleAccent),
                    SpaceWidget(),
                    Text("Upload $unit"),
                  ],
                ),
                SpaceWidget(),
                Text(
                  uploadRate == 0 ? "..." : uploadRate.toString(),
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        SpaceWidget(),
        SpaceWidget(),
        // Ping et Latence
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.network_ping, color: Colors.orangeAccent),
                    SpaceWidget(),
                    Text("Ping ms"),
                  ],
                ),
                SpaceWidget(),
                Text(
                  ping == 0 ? "..." : ping.toString(),
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 60.0, child: VerticalDivider()),
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: Colors.greenAccent),
                    SpaceWidget(),
                    Text("Latence ms"),
                  ],
                ),
                SpaceWidget(),
                Text(
                  latency == 0 ? "..." : latency.toString(),
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}