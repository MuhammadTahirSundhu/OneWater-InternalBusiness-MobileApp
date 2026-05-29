import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0369A1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop,
              size: 72,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'OneWater',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'PAKISTAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xCCFFFFFF),
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Premium Himalayan Mineral Water',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xAAFFFFFF),
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
