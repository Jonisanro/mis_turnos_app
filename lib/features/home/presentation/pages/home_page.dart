import 'package:flutter/material.dart';
/* import 'package:mis_turnos_app/core/shared_widgets/background_asset_widget.dart'; */
import 'package:mis_turnos_app/features/home/presentation/pages/widgets/calendar_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        /*        BackgroundAssetWidget(), */
        Container(
          child: Column(
            children: [
              // Primera fila
              Row(
                children: [
                  Expanded(
                    //TODO WIDGET 1 A DEFINIR
                    child: Container(
                      height: size.height * 0.4,
                      color: Colors.pink[50],
                      child: Center(child: Text('Widget 1')),
                    ),
                  ),
                  Expanded(
                    //TODO WIDGET 2 A DEFINIR
                    child: Container(
                      height: size.height * 0.4,
                      color: Colors.blueGrey,
                      child: Center(child: Text('Widget 2')),
                    ),
                  ),
                ],
              ),
              // Segunda fila con el calendario
              Expanded(
                child: CalendarWidget(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
