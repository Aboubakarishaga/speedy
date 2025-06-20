import 'package:flutter/material.dart';

class RunTestWidget extends StatelessWidget {
  final GestureTapCallback onTap;

  const RunTestWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100.0),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.0),
            border: Border.all(color: Colors.cyanAccent, width: 3.0),
          ),
          child: Center(
            child: Text(
              "GO",
              style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
