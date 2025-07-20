import 'package:flutter/material.dart';

class RunTestWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const RunTestWidget({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animation du bouton principal
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.cyanAccent,
                Colors.cyanAccent.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.3),
                spreadRadius: 10,
                blurRadius: 20,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isLoading
                      ? CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3,
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 60,
                        color: Colors.black,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'DÉMARRER',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 30),

        // Texte d'instruction
        Text(
          'Appuyez pour démarrer le test',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),

        SizedBox(height: 10),

        Text(
          'Le test mesurera votre vitesse de téléchargement,\nd\'envoi, le ping et la latence',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
          ),
        ),

        SizedBox(height: 40),

        // Indicateurs de ce qui sera testé
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTestIndicator(
              Icons.download,
              'Download',
              Colors.blue,
            ),
            _buildTestIndicator(
              Icons.upload,
              'Upload',
              Colors.green,
            ),
            _buildTestIndicator(
              Icons.speed,
              'Ping',
              Colors.orange,
            ),
            _buildTestIndicator(
              Icons.access_time,
              'Latence',
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestIndicator(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
