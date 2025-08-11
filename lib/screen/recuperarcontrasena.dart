import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'package:banktrust/sesion.dart';
import 'package:banktrust/base/database.dart';

class RecuperarContrasena extends StatefulWidget {
  final String cuenta;

  const RecuperarContrasena({super.key, required this.cuenta});

  @override
  State<RecuperarContrasena> createState() => _RecuperarContrasenaState();
}

class _RecuperarContrasenaState extends State<RecuperarContrasena> {
  late TextEditingController cuentaController;
  final TextEditingController contrasenaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cuentaController = TextEditingController(text: widget.cuenta);
  }

  //r
  void recuperarContrasena() async {
    String nuevaClave = contrasenaController.text.trim();
    String cuenta = cuentaController.text.trim();

    if (nuevaClave.isEmpty || cuenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    bool confirmado = await confirmarCambioContrasena(context);
    if (!confirmado) return;

    try {
      final dbHelper = DatabaseHelper();
      final idCuenta = await dbHelper.getCuentaIdPorNumero(int.parse(cuenta));

      if (idCuenta != null) {
        await dbHelper.updateCuentaClave(idCuenta, nuevaClave);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada exitosamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cuenta no encontrada')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    /*
    String cuenta = cuentaController.text;
    String contrasena = contrasenaController.text;

    if (cuenta.isNotEmpty && contrasena.isNotEmpty) {
      bool confirmado = await confirmarCambioContrasena(context);
      if (confirmado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada exitosamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Operación cancelada')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
    }
    */
  }

  Future<bool> confirmarCambioContrasena(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmación'),
            content: const Text(
              '¿Está seguro que desea cambiar la contraseña de esta cuenta?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        toolbarHeight: 120,
        title: Text(
          "¿Clave olvidada?",
          style: GoogleFonts.poppins(
            fontSize: 30,
            color: const Color(0xFF328535),
          ), //i
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
      ), // 28
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Center(
          child: SizedBox(
            width: 350,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Nueva contraseña",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: Color(0xFF8F8E8E),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
                  "NUEVA CONTRASEÑA",
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
                ), //2003
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: recuperarContrasena,
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
                      ),
                    ),
                    child: const Text("Cambiar Contraseña"),
                  ),
                ),
              ],
            ),
          ),
        ), //c
      ),
    );
  } //k
}
