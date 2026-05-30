import 'package:flutter/material.dart';
import 'package:mis_turnos_app/core/shared_widgets/background_asset_widget.dart';
import 'package:mis_turnos_app/features/login/presentation/widgets/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [BackgroundAssetWidget(), Center(child: RegisterCard())],
      ),
    );
  }
}
