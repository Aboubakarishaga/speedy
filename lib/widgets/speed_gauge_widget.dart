import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpeedGaugeWidget extends StatefulWidget {
  final double downloadSpeed;
  final double uploadSpeed;
  final String unit;
  final bool isDownloading;
  final bool isUploading;

  const SpeedGaugeWidget({
    Key? key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.unit,
    this.isDownloading = false,
    this.isUploading = false,
  }) : super(key: key);

  @override
  State<SpeedGaugeWidget> createState() => _SpeedGaugeWidgetState();
}

class _SpeedGaugeWidgetState extends State<SpeedGaugeWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SpeedGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.downloadSpeed != oldWidget.downloadSpeed ||
        widget.uploadSpeed != oldWidget.uploadSpeed) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Jauge circulaire
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(300, 300),
                painter: SpeedGaugePainter(
                  downloadSpeed: widget.downloadSpeed * _animation.value,
                  uploadSpeed: widget.uploadSpeed * _animation.value,
                  isDownloading: widget.isDownloading,
                  isUploading: widget.isUploading,
                ),
              );
            },
          ),

          // Affichage central
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isDownloading) ...[
                Icon(
                  Icons.download,
                  color: Colors.cyanAccent,
                  size: 30,
                ),
                SizedBox(height: 8),
                Text(
                  '${widget.downloadSpeed.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Téléchargement',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ] else if (widget.isUploading) ...[
                Icon(
                  Icons.upload,
                  color: Colors.green,
                  size: 30,
                ),
                SizedBox(height: 8),
                Text(
                  '${widget.uploadSpeed.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Envoi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Text(
                  'Prêt',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Classe CustomPainter pour dessiner la jauge
class SpeedGaugePainter extends CustomPainter {
  final double downloadSpeed;
  final double uploadSpeed;
  final bool isDownloading;
  final bool isUploading;

  SpeedGaugePainter({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.isDownloading,
    required this.isUploading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Pinceau pour le fond de la jauge
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    // Dessiner le cercle de fond (3/4 de cercle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, // Commencer à 3/4 vers la gauche
      math.pi * 1.5,   // Arc de 270 degrés
      false,
      backgroundPaint,
    );

    // Calculer l'angle basé sur la vitesse
    final maxSpeed = 100.0; // Vitesse maximale pour l'affichage
    double currentSpeed = isDownloading ? downloadSpeed : uploadSpeed;

    if (currentSpeed > 0) {
      double progress = math.min(currentSpeed / maxSpeed, 1.0);
      double sweepAngle = progress * math.pi * 1.5; // Max 270 degrés

      // Couleur de la jauge selon le type de test
      Color gaugeColor = isDownloading
          ? Colors.cyanAccent
          : isUploading
          ? Colors.green
          : Colors.grey;

      // Pinceau pour la jauge active
      final gaugePaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round;

      // Dessiner l'arc de progression
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75, // Commencer au même point que le fond
        sweepAngle,
        false,
        gaugePaint,
      );

      // Dessiner un point à la fin de l'arc pour l'indicateur
      final indicatorAngle = -math.pi * 0.75 + sweepAngle;
      final indicatorPoint = Offset(
        center.dx + radius * math.cos(indicatorAngle),
        center.dy + radius * math.sin(indicatorAngle),
      );

      final indicatorPaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(indicatorPoint, 8, indicatorPaint);
    }

    // Dessiner des graduations
    _drawGraduations(canvas, center, radius);
  }

  void _drawGraduations(Canvas canvas, Offset center, double radius) {
    final graduationPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Dessiner 6 graduations pour 0, 20, 40, 60, 80, 100 Mbps
    for (int i = 0; i <= 5; i++) {
      final progress = i / 5.0; // 0.0 à 1.0
      final angle = -math.pi * 0.75 + (progress * math.pi * 1.5);

      final innerRadius = radius - 10;
      final outerRadius = radius + 5;

      final startPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, graduationPaint);

      // Ajouter des labels
      final speed = (progress * 100).toInt();
      final labelRadius = radius + 25;
      final labelPoint = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      textPainter.text = TextSpan(
        text: '$speed',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is SpeedGaugePainter) {
      return oldDelegate.downloadSpeed != downloadSpeed ||
          oldDelegate.uploadSpeed != uploadSpeed ||
          oldDelegate.isDownloading != isDownloading ||
          oldDelegate.isUploading != isUploading;
    }
    return true;
  }
}
