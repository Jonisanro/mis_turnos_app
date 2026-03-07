import 'package:flutter/material.dart';

class BackgroundAssetWidget extends StatelessWidget {
  const BackgroundAssetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login_background.png',
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
    );
  }
}
