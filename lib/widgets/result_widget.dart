import 'package:flutter/material.dart';
import 'package:speedy/widgets/space_widget.dart';

class ResultWidget extends StatelessWidget {
  final double downloadRate;
  final double uploadRate;
  final String unit;

  const ResultWidget({
    required this.downloadRate,
    required this.uploadRate,
    required this.unit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SpaceWidget(),
        Text(
          "Result",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 30.0,
          ),
        ),
        SpaceWidget(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_circle_down),
                    SpaceWidget(),
                    Text("Download $unit"),
                  ],
                ),
                SpaceWidget(),
                Text(
                  downloadRate == 0 ? "..." : downloadRate.toString(),
                  style: TextStyle(fontSize: 32.0),
                ),
              ],
            ),
            SizedBox(height: 60.0, child: VerticalDivider()),
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_circle_up),
                    SpaceWidget(),
                    Text("Upload $unit"),
                  ],
                ),
                SpaceWidget(),
                Text(
                  uploadRate == 0 ? "..." : uploadRate.toString(),
                  style: TextStyle(fontSize: 32.0),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
