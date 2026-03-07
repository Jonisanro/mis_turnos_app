import 'package:flutter/material.dart';
import 'package:mis_turnos_app/core/shared_widgets/background_asset_widget.dart';
import 'package:mis_turnos_app/features/login/presentation/widgets/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Stack(
        children: [BackgroundAssetWidget(), Center(child: LoginCard())],
      ),
    );
  }
}
