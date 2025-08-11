import 'package:banktrust/models/usuario.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:banktrust/base/database.dart';
import 'package:banktrust/sesion.dart';

class Pagarservicios extends StatefulWidget {
  const Pagarservicios({super.key});

  @override
  _PagarserviciosState createState() => _PagarserviciosState();
}



class _PagarserviciosState extends State<Pagarservicios> {
  final usuario = Sesion.usuarioActual;
  late TextEditingController cuentaOrigen = TextEditingController(
    text: usuario?.cuenta.toString(),
  );
  List<Map<String, dynamic>> _opciones = [];
  Map<int, String> _mapaTipos = {};

  final TextEditingController cantpagarController = TextEditingController();
  String? _seleccion;

  @override
  void initState() {
    super.initState();
    cantpagarController.addListener(() => setState(() {}));
    cargarTiposDePagos();
  }

  @override
  void dispose() {
    cantpagarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              color: const Color(0xFF328535),
              child: Center(
                child: Text(
                  'PAGO DE SERVICIOS',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 29.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Datos',
              style: GoogleFonts.poppins(
                fontSize: 45,
                color: Color(0xFF328535),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CUENTA DE ORIGEN:',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextField(
                controller: cuentaOrigen,
                decoration: const InputDecoration(
                  enabled: false,
                  labelText: "123",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color.fromARGB(255, 222, 222, 222),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SERVICIO:',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFcce1c6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text("Elija una opción"),
                        iconEnabledColor: Colors.white,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFFcce1c6),
                        value: _seleccion != null
                            ? _opciones.firstWhere(
                                (e) => e['DESCRIPCION'] == _seleccion,
                              )['ID']
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        items: _opciones.map((tipo) {
                          return DropdownMenuItem<int>(
                            value: tipo['ID'],
                            child: Text(tipo['DESCRIPCION']),
                          );
                        }).toList(),
                        onChanged: (int? nuevoIdTipo) {
                          setState(() {
                            _seleccion =
                                _mapaTipos[nuevoIdTipo]; // guarda el nombre si quieres
                            cantpagarController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CANTIDAD A PAGAR:',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: TextField(
                controller: cantpagarController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    String text = newValue.text;
                    if (text.contains('.') && text.contains(',')) {
                      return oldValue;
                    }
                    return newValue;
                  }),
                ],
                enabled: _seleccion != null,
                decoration: const InputDecoration(
                  labelText: "L.0.00",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFcce1c6),
                ),
                onChanged: (value) {
                  if (value.length == 1 && value == '0') {
                    cantpagarController.clear();
                  }
                },
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: cantpagarController.text.isNotEmpty
                    ? mtdTransferencia
                    : null,
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
                child: const Text("Confirmar Pago"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> mtdTransferencia() async {
    bool confirmado = await mtdConfirmarDatos(context);
    if (confirmado) {
      // Asumimos que la cuenta es "123" fija
      int cuentaInt = usuario!.idCuenta;

      // Obtener el id_tipo según la opción seleccionada
      int idTipo = _mapaTipos.entries
          .firstWhere((entry) => entry.value == _seleccion)
          .key; // Suponiendo que empieza desde 1

      // Convertir el monto a double
      double monto =
          double.tryParse(cantpagarController.text.replaceAll(',', '.')) ?? 0;

      if (monto > usuario!.saldo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cuenta con fondos suficientes')),
        );
        setState(() {
          cantpagarController.clear();
          _seleccion = null;
        });
        return;
      } else {
        await DatabaseHelper().insertPagos(cuentaInt, idTipo, monto);
        await DatabaseHelper().actualizarSaldo(cuentaInt, monto);
        actualizarUsuario();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pago realizado con éxito')));
      setState(() {
        cantpagarController.clear();
        _seleccion = null;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pago cancelado')));
    }
  }

  Future<void> cargarTiposDePagos() async {
    final tipos = await DatabaseHelper().getTiposDePagos();
    setState(() {
      _opciones = tipos;
      for (var tipo in tipos) {
        final id = tipo['ID'];
        final nombre = tipo['DESCRIPCION'];
        if (id != null && nombre != null) {
          _mapaTipos[id as int] = nombre as String;
        }
      }
    });
  }

  Future<void> actualizarUsuario() async{
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'CUENTAS',
      where: 'ID = ?',
      whereArgs: [usuario!.idCuenta]
    );
    if(result.isNotEmpty){
      final cuenta = result.first;
      final _usuario = Usuario(
          idCuenta: (cuenta['ID'] as num?)?.toInt() ?? 0,
          nombre: cuenta['NOMBRE']?.toString() ?? '',
          cuenta: cuenta['NUMERO']?.toString() ?? '',
          saldo: (cuenta['SALDO'] as num?)?.toDouble() ?? 0.0,

        );

        Sesion.usuarioActual=_usuario;
    }
  }
}

Future<bool> mtdConfirmarDatos(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmación'),
          content: const Text('¿Está seguro que los datos son correctos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
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
