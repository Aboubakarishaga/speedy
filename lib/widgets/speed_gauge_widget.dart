import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class SpeedGaugeWidget extends StatelessWidget {
  final double value;
  final String unit;
  final Color pointerColor;
  final bool enableLoadingAnimation;
  final double maxValue;

  const SpeedGaugeWidget({
    super.key,
    required this.value,
    required this.unit,
    required this.pointerColor,
    this.enableLoadingAnimation = true,
    this.maxValue = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.0,
      width: 300.0,
      child: SfRadialGauge(
        enableLoadingAnimation: enableLoadingAnimation,
        animationDuration: 4500,
        axes: [
          RadialAxis(
            minimum: 0,
            maximum: maxValue,
            ranges: [
              GaugeRange(
                startValue: 0,
                endValue: maxValue,
                startWidth: 10,
                endWidth: 10,
                color: Colors.black12,
              ),
            ],
            pointers: [
              NeedlePointer(value: value, enableAnimation: true),
              RangePointer(
                value: value,
                enableAnimation: true,
                color: pointerColor,
              ),
            ],
            annotations: [
              GaugeAnnotation(
                widget: Padding(
                  padding: EdgeInsets.only(top: 220.0),
                  child: Text(
                    "$value $unit",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}