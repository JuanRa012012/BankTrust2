import 'package:banktrust/screen/BarraMenu.dart';
import 'package:banktrust/screen/recuperarcontrasena.dart';
import 'package:banktrust/screen/splashscreen.dart';
import 'package:flutter/material.dart';
import './screen/crearcuenta.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'screen/perfil.dart';
import 'package:flutter/services.dart';

import 'package:banktrust/base/database.dart';
import 'package:banktrust/models/usuario.dart'; // ajusta la ruta según tu proyecto
import 'package:banktrust/sesion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class IniciarSesion extends StatefulWidget {
  const IniciarSesion({Key? key}) : super(key: key);

  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  final TextEditingController cuentaController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  void validarInicioSesion() async {
    final cuenta = cuentaController.text.trim();
    final contrasena = contrasenaController.text.trim();

    if (cuenta.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    final cuentaParsed = int.tryParse(cuenta);
    if (cuentaParsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de cuenta inválido')),
      );
      return;
    }

    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'CUENTAS',
        where: 'NUMERO = ? AND CLAVE = ?',
        whereArgs: [cuentaParsed, contrasena],
      );

      if (result.isNotEmpty) {
        final cuenta = result.first;

        final usuario = Usuario(
          idCuenta: (cuenta['ID'] as num?)?.toInt() ?? 0,
          nombre: cuenta['NOMBRE']?.toString() ?? '',
          cuenta: cuenta['NUMERO']?.toString() ?? '',
          saldo: (cuenta['SALDO'] as num?)?.toDouble() ?? 0.0,

        );

        Sesion.usuarioActual = usuario;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Barramenu()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta o contraseña incorrecta')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        toolbarHeight: 120,
        title: Text(
          "Iniciar Sesión", //i
          style: GoogleFonts.poppins(
            fontSize: 45,
            color: const Color(0xFF328535),
          ),
        ),
        centerTitle: true,
        elevation: 0, //c
        backgroundColor: const Color(0xFFFEF7FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Inicia sesión para continuar",
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  color: Color(0xFF8F8E8E),
                ),
              ),
            ), //k
            const SizedBox(height: 80),
            SizedBox(
              width: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "NÚMERO DE CUENTA",
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      color: Color(0xFF8F8E8E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: cuentaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Ingrese su número",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFcce1c6),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "CONTRASEÑA",
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      color: Color(0xFF8F8E8E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: contrasenaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Ingrese su contraseña",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFcce1c6),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            String cuenta = cuentaController.text.trim();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecuperarContrasena(cuenta: cuenta),
                              ),
                            );
                          },
                          child: Text(
                            "¿Olvidó la Contraseña?",
                            style: GoogleFonts.dmSans(
                              color: Colors.blue,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CrearCuenta(),
                              ),
                            );
                          },
                          child: Text(
                            "Crear Cuenta",
                            style: GoogleFonts.dmSans(
                              color: Colors.blue,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      onPressed: validarInicioSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27662A),
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ), //2003
                      ),
                      child: const Text("Iniciar Sesión"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
