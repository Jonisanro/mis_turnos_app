import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

bool isPasswordVisible = false;
//Controladores de los campos de texto
final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

class _LoginCardState extends State<LoginCard> {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5, // Ajusta la elevación según tus necesidades
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 45.0),
        width: 400,
        height: 450,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          gradient: LinearGradient(
            transform: GradientRotation(3.14 * 90),
            colors: [
              Color(0xFFB3E5FC),
              Colors.white,
            ],
            stops: [0.1, 0.4],
            tileMode: TileMode.clamp,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            PrincipalTextsLogin(),
            SizedBox(height: 50),
            LoginForm(),
            SizedBox(height: 50),
            LoginButton()
          ],
        ),
      ),
    );
  }
}

//TODO: VER DE PASAR LOS WIDGETS A ARCHIVOS SEPARADOS

class PrincipalTextsLogin extends StatelessWidget {
  const PrincipalTextsLogin({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(15),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            'Iniciar sesión con tu email',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          'Applicación de turnos, para agendar tus turnos de manera fácil y rápida',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
        child: Column(
      children: [
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: emailController,
            decoration: loginInputDecoration().copyWith(
              hintText: 'Email',
              prefixIcon: Icon(
                size: 20,
                Icons.email,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: loginInputDecoration().copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  size: 20,
                  Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
                color: Colors.grey,
              ),
              hintText: 'Password',
              prefixIcon: Icon(
                size: 20,
                Icons.lock,
                color: Colors.grey,
              ),
            ),
          ),
        )
      ],
    ));
  }

  InputDecoration loginInputDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.grey[200], // Color de fondo fijo
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(20.0), // Bordes redondeados siempre
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(20.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(20.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(20.0),
      ),
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      hintStyle: TextStyle(fontSize: 14),
    );
  }
}

class LoginButton extends ConsumerStatefulWidget {
  const LoginButton({super.key});

  @override
  _LoginButtonState createState() => _LoginButtonState();
}

class _LoginButtonState extends ConsumerState<LoginButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final authService = ref.read(loginProvider);
        final user = await authService.signInWithEmail(
          emailController.text,
          passwordController.text,
        );
        if (user != null) {
          SnackBar snackBar = SnackBar(
            content: Text('Inicio de sesión exitoso'),
            backgroundColor: Colors.green,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          context.go('/home');
        } else {
          SnackBar snackBar = SnackBar(
            content: Text('Error al iniciar sesión'),
            backgroundColor: Colors.red,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1C1C1E), // Color oscuro del botón
        minimumSize: const Size(350, 45), // Ancho y alto del botón
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Bordes redondeados
        ),
      ),
      child: const Text(
        'Iniciar sesión',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white, // Texto en color blanco
        ),
      ),
    );
  }
}
