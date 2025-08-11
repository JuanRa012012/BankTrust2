import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:banktrust/screen/recuperarcontrasena.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:banktrust/sesion.dart';
import 'package:banktrust/base/database.dart'; 

final usuario = Sesion.usuarioActual;

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  _PerfilState createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  int _paginaActual = 2;
  File? _imagenPerfil;

  @override
  void initState() {
    super.initState();
    _cargarImagenGuardada();
  }

  void _cargarImagenGuardada() async {
    final db = await DatabaseHelper().database;
    final resultado = await db.query(
      'CUENTAS',
      columns: ['IMAGEN'],
      where: 'NUMERO = ?',
      whereArgs: [int.parse(Sesion.usuarioActual!.cuenta)],
    );

    if (resultado.isNotEmpty && resultado.first['IMAGEN'] != null) {
      String base64Image = resultado.first['IMAGEN'] as String;
      final bytes = base64Decode(base64Image);

      final tempDir = Directory.systemTemp;
      final tempFile = await File('${tempDir.path}/imagen_perfil.png').writeAsBytes(bytes);

      setState(() {
        _imagenPerfil = tempFile;
      });

      Sesion.usuarioActual!.imagenBase64 = base64Image;
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imagen = File(pickedFile.path);
      List<int> bytes = await imagen.readAsBytes();
      String base64Image = base64Encode(bytes);

      setState(() {
        _imagenPerfil = imagen;
      });

      final db = await DatabaseHelper().database;
      await db.update(
        'CUENTAS',
        {'IMAGEN': base64Image},
        where: 'NUMERO = ?',
        whereArgs: [int.parse(usuario!.cuenta)],
      );
      //este es para que la imagen quede en la sesion tambien
      usuario!.imagenBase64 = base64Image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Sesion.usuarioActual;

    if (usuario == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No hay usuario activo',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              color: const Color(0xFF328535),
              child: Center(
                child: Text(
                  'PERFIL',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 29.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _seleccionarImagen,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF328535),
                backgroundImage: _imagenPerfil != null
                    ? FileImage(_imagenPerfil!)
                    : null,
                child: _imagenPerfil == null
                    ? const Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              usuario.nombre,
              style: GoogleFonts.poppins(
                fontSize: 45,
                color: const Color(0xFF328535),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              usuario.cuenta,
              style: GoogleFonts.dmSans(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SALDO',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextField(
                enabled: false,
                controller: TextEditingController(
                  text: 'L ${usuario.saldo.toStringAsFixed(2)}',
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color.fromARGB(255, 222, 222, 222),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecuperarContrasena(cuenta: usuario.cuenta),
                  ),
                );
              },
              child: Text(
                'Cambiar contraseña',
                style: GoogleFonts.dmSans(
                  color: Colors.blue,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
