import 'package:banktrust/screen/historialmovimientos.dart';
import 'package:banktrust/screen/pagarservicios.dart';
import 'package:banktrust/screen/perfil.dart';
import 'package:banktrust/screen/transferencias.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:banktrust/main.dart';

class Barramenu extends StatefulWidget {
  const Barramenu({Key? key}) : super(key: key);

  @override
  State<Barramenu> createState() => _BarraMenuState();
}

class _BarraMenuState extends State<Barramenu> {
  int _paginaActual = 2;

  final List<Widget> _paginas = [
    Pagarservicios(),
    Transferencias(),
    Perfil(),
    Historialmovimientos(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final bool salir = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirmar salida"),
            content: const Text("¿Estás seguro que deseas cerrar sesión?"),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text("Sí, salir"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (salir) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const IniciarSesion()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        height: 60,
        backgroundColor: const Color(0xFFFEF7FF),
        color: const Color(0xFF328535),
        buttonBackgroundColor: const Color(0xFF27662A),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        index: _paginaActual,
        items: const <Widget>[
          Icon(Icons.payment, size: 30, color: Colors.white),
          Icon(Icons.swap_horiz, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
          Icon(Icons.history, size: 30, color: Colors.white),
          Icon(Icons.logout, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          if (index == 4) {
            _confirmarCerrarSesion(context);
          } else {
            setState(() {
              _paginaActual = index;
            });
          }
        },
      ),
    );
  }
}
