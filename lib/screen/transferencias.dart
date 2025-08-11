import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:banktrust/screen/Barramenu.dart';
import 'package:banktrust/base/database.dart';
import 'package:banktrust/sesion.dart';
import 'package:banktrust/models/usuario.dart';

class Transferencias extends StatefulWidget {
  const Transferencias({super.key});

  @override
  State<Transferencias> createState() => _TransferenciasState();
}

class _TransferenciasState extends State<Transferencias> {
  final usuario = Sesion.usuarioActual;
  
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  // int _paginaActual = 1;

  late TextEditingController cuentaOrigen = TextEditingController(
    text: usuario?.cuenta.toString(),
  );
  late TextEditingController cuentaDestino = TextEditingController();
  late TextEditingController monto = TextEditingController();
  late TextEditingController concepto = TextEditingController();
  late FocusNode focusCuentaDestino;

  @override
  void initState() {
    super.initState();

    cuentaDestino = TextEditingController();
    focusCuentaDestino = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusCuentaDestino.requestFocus();
      final navBarState = _bottomNavigationKey.currentState;
      navBarState?.setPage(1); 
    });
  }

  Future<void> mtdTransferencia() async {
    String vrCuentaDestino = cuentaDestino.text;
    String vrMonto = monto.text;
    String vrConcepto = concepto.text;

    if (vrCuentaDestino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escriba la cuenta de destino')),
      );
    } else if (vrMonto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escriba el monto a transferir'),
        ),
      );
    } else if (vrConcepto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor escriba un pequeño concepto para la transacción',
          ),
        ),
      );
    } else {
      // Mostrar mensaje de confirmación
      bool confirmado = await mtdConfirmarDatos(context);

      if (confirmado) {
        try {
          final dbHelper = DatabaseHelper(); //instanciando la base de datos
          int vrNumeroCuentaDestino = int.parse(cuentaDestino.text); //tomando el número de la casilla donde se escribió el número de destino
          int? vrIdCuentaDestino = await dbHelper.getCuentaIdPorNumero(vrNumeroCuentaDestino); //busscando el ID del número de cuenta de destino

          if(vrIdCuentaDestino != null)
          {
            int vrNumeroCuentaOrigen = int.parse(cuentaOrigen.text); //tomando el número de cuenta desde el parámetro reicibo al hacer el llamado a esta pantalla
            int? vrIdCuenta = await dbHelper.getCuentaIdPorNumero(vrNumeroCuentaOrigen); //busscando el ID del número de cuenta del usuarioa actual
            
            if(vrIdCuentaDestino != vrIdCuenta)
            {
              double vrMonto = double.parse(monto.text); //trayendo el monto desde la casilla
              String vrConcepto = concepto.text.toString(); //trayendo el concepto desde la casilla
              // int vrId = int.parse(vrIdCuenta.toString());
              // double? vrSaldo = await dbHelper.getSaldoActualPorIdCuenta(vrId); //método para obtener el saldo actual
              double? vrSaldo = usuario?.saldo;

              if (vrSaldo! >= vrMonto) {
                if (vrIdCuenta != null) {
                  await dbHelper.insertTransferencias(vrIdCuenta, vrIdCuentaDestino, vrMonto, vrConcepto); //realizando el envío de la transferencia hacia la base de datos
                  actualizarUsuario();
                  confirmado = await mtdOtraTransferencia(context);
                  
                  if (confirmado) {
                    mtdLimpiarCampos();
                  } else {
                    Future.delayed(const Duration(seconds: 0), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Barramenu()),
                      ); //r
                    });
                  }
                } else {
                  mtdMessage(context, 'Hubo un error al buscar la cuenta de origen');
                }
              } else {
                mtdMessage(context, 'Estimado usuario la cuenta origen no tiene suficiente saldo para realizar esta acción: \n Saldo actual: $vrSaldo \n Monto transferencia: $vrMonto');
              }
            } else {
              mtdMessage(context, 'La cuenta origen no puede ser la misma que la cuenta destino');
            }
            
          } else {
            mtdMessage(context, 'El número de cuenta escrito no existe en el catálogo de cuentas bancarias');
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        // Navigator.pop(context);
      } else {
        // Usuario canceló
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Operación cancelada')));
      }
    }
  }

  void mtdLimpiarCampos() {
    cuentaDestino.clear();
    monto.clear();
    concepto.clear();

    FocusScope.of(context).requestFocus(focusCuentaDestino);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      // appBar: AppBar(
      //   toolbarHeight: 120,
      //   title: Text(
      //     "Datos",
      //     style: GoogleFonts.poppins(
      //       fontSize: 44,
      //       color: const Color(0xFF328535),
      //     ),
      //     textAlign: TextAlign.center,
      //   ),
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: const Color(0xFFFEF7FF),
      // ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              color: const Color(0xFF328535),
              child: Center(
                child: Text(
                  'REALIZAR TRANSFERENCIA',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Datos",
              style: GoogleFonts.poppins (fontSize: 45, color: Color(0xFF328535)),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CUENTA DE ORIGEN:',
                  style:  GoogleFonts.dmSans(
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
                  labelText: "Cuenta de origen",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color.fromARGB(255, 222, 222, 222),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CUENTA DE DESTINO:',
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
                focusNode: focusCuentaDestino,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: cuentaDestino,
                // obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Escriba aquí la cuenta de destino",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFcce1c6),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MONTO DE TRANSFERENCIA:',
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
                controller: monto,
                // obscureText: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}$')),
                ],
                decoration: const InputDecoration(
                  labelText: "Escriba aquí el monto que desea transferir",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFcce1c6),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CONCEPTO:',
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
                controller: concepto,
                // obscureText: true,
                decoration: const InputDecoration(
                  labelText:
                      "Por favor escriba un concepto para la transacción",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFcce1c6),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: mtdTransferencia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27662A),
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                child: const Text("Realizar transacción"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // bottomNavigationBar: CurvedNavigationBar(
      //   key: _bottomNavigationKey,
      //   height: 60,
      //   backgroundColor: const Color(0xFFFEF7FF),
      //   color: const Color(0xFF328535),
      //   buttonBackgroundColor: const Color(0xFF55A14E),
      //   animationCurve: Curves.easeInOut,
      //   animationDuration: const Duration(milliseconds: 300),
      //   index: _paginaActual,
      //   items: const <Widget>[
      //     Icon(Icons.payment, size: 30, color: Colors.white),
      //     Icon(Icons.swap_horiz, size: 30, color: Colors.white),
      //     Icon(Icons.person, size: 30, color: Colors.white),
      //     Icon(Icons.history, size: 30, color: Colors.white),
      //     Icon(Icons.logout, size: 30, color: Colors.white),
      //   ],
      //   onTap: (index) {
      //     setState(() {
      //       _paginaActual = index;
      //     });

      //     // Navegación futura
      //     switch (index) {
      //       case 0:
      //         break;
      //       case 1:
      //         break;
      //       case 2:
      //         // Navigator.pushReplacement(
      //         //   context,
      //         //   MaterialPageRoute(builder: (context) => Perfil()),
      //         // );
      //         Navigator.pushReplacement(
      //           context,
      //           PageRouteBuilder(
      //             pageBuilder: (_, __, ___) => Perfil(),
      //             transitionDuration: const Duration(milliseconds: 500),
      //             reverseTransitionDuration: Duration.zero,
      //             transitionsBuilder:
      //                 (context, animation, secondaryAnimation, child) {
      //                   return FadeTransition(opacity: animation, child: child);
      //                 },
      //           ),
      //         );
      //         break;
      //       case 3:
      //         Navigator.pushReplacement(
      //           context,
      //           PageRouteBuilder(
      //             pageBuilder: (_, __, ___) => Historialmovimientos(),
      //             transitionDuration: const Duration(seconds: 1),
      //             reverseTransitionDuration: Duration.zero,
      //             transitionsBuilder:
      //                 (context, animation, secondaryAnimation, child) {
      //                   return FadeTransition(opacity: animation, child: child);
      //                 },
      //           ),
      //         );
      //         break;
      //       case 4:
      //         // Navigator.pushReplacement(
      //         //   context,
      //         //   MaterialPageRoute(
      //         //     builder: (context) =>
      //         //         RecuperarContrasena(cuenta: usuario.cuenta),
      //         //   ),
      //         // );
      //         break;
      //     }
      //   },
      // ),
    );
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
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí'),
            ),
          ],
        ),
      ) ??
      false; // Retorna false si el usuario cierra el diálogo sin elegir
}

Future<bool> mtdOtraTransferencia(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmación'),
          content: const Text(
            'La transferencia ha sido exitosa, ¿Desea realizar otra transferencia?',
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
      false; // Retorna false si el usuario cierra el diálogo sin elegir
}

void mtdMessage(BuildContext context, String vrText) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Mensaje'),
        content: SingleChildScrollView(
          child: Text(vrText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

  