import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'package:banktrust/base/database.dart';

class CrearCuenta extends StatefulWidget {
  const CrearCuenta({super.key});

  @override
  State<CrearCuenta> createState() => _CrearCuentaState();
}

class _CrearCuentaState extends State<CrearCuenta> {
  final TextEditingController cuentaController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();

  String? tipoSeleccionado;
  final Map<String, double> tiposCuenta = {
    'Básica': 25000,
    'Estudiante': 50000,
    'Profesional': 75000,
  };

  void crearCuenta() async {
    String cuenta = cuentaController.text.trim();
    String contrasena = contrasenaController.text.trim();
    String nombre = nombreController.text.trim();
    String apellido = apellidoController.text.trim();

    if (cuenta.isNotEmpty &&
        contrasena.isNotEmpty &&
        nombre.isNotEmpty &&
        apellido.isNotEmpty &&
        tipoSeleccionado != null) {
      try {
        int numeroCuenta = int.parse(cuenta);

        final idExistente = await DatabaseHelper().getCuentaIdPorNumero(
          numeroCuenta,
        );
        if (idExistente != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe una cuenta con ese número'),
            ),
          );
          return;
        }
        await DatabaseHelper().insertCuenta(
          '$nombre $apellido',
          numeroCuenta,
          contrasena,
          tiposCuenta[tipoSeleccionado]!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear cuenta: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      appBar: AppBar(
        toolbarHeight: 120,
        title: Text(
          "Crear Cuenta",
          style: GoogleFonts.poppins(fontSize: 30, color: Color(0xFF328535)),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
      ),
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
                    "Complete el formulario para registrarse",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: Color(0xFF8F8E8E),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildLabel("NÚMERO DE CUENTA"),
                _buildTextField(
                  cuentaController,
                  "Ingrese su número",
                  isNumeric: true,
                ),
                const SizedBox(height: 25),
                _buildLabel("CONTRASEÑA"),
                _buildTextField(
                  contrasenaController,
                  "Ingrese su contraseña",
                  isPassword: true,
                ),
                const SizedBox(height: 25),
                _buildLabel("NOMBRE"),
                _buildTextField(nombreController, "Ingrese su nombre"),
                const SizedBox(height: 25),
                _buildLabel("APELLIDO"),
                _buildTextField(apellidoController, "Ingrese su apellido"),
                const SizedBox(height: 25),

                _buildLabel("TIPO DE CUENTA"),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFcce1c6),
                    border: OutlineInputBorder(),
                  ),
                  value: tipoSeleccionado,
                  hint: const Text("Seleccione un tipo"),
                  onChanged: (value) {
                    setState(() {
                      tipoSeleccionado = value!;
                    });
                  },
                  items: tiposCuenta.keys.map((tipo) {
                    return DropdownMenuItem(value: tipo, child: Text(tipo));
                  }).toList(),
                ),

                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: crearCuenta,
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
                    child: const Text("Crear Cuenta"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(fontSize: 20, color: const Color(0xFF8F8E8E)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumeric = false,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      obscureText: isPassword,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: const Color(0xFFcce1c6),
      ),
    );
  }
}
