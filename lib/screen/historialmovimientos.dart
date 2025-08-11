import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banktrust/base/database.dart';
import 'package:banktrust/sesion.dart';

class Transaccion {
  String tipo;
  double monto;
  String cuentaDestino;
  String cuentaOrigen;
  String fecha;
  String concepto;

  Transaccion({
    required this.tipo,
    required this.monto,
    required this.cuentaDestino,
    required this.cuentaOrigen,
    required this.fecha,
    required this.concepto,
  });
  factory Transaccion.fromMap(Map<String, dynamic> map, String tipo) {
    return Transaccion(
      tipo: tipo,
      monto: map['MONTO']?.toDouble() ?? 0.0,
      cuentaDestino: map.containsKey('NUMERO_DESTINO')
          ? map['NUMERO_DESTINO'].toString()
          : map['DESCRIPCION'] ?? 'N/A',
      fecha: map['FECHA'] ?? 'Fecha no disponible',
      concepto: map['CONCEPTO'] ?? 'N/A',
      cuentaOrigen: map['NUMERO_ORIGEN'].toString()
    );
  }
}

class Historialmovimientos extends StatefulWidget {
  const Historialmovimientos({super.key});
  @override
  HistorialmovimientosState createState() => HistorialmovimientosState();
}

enum Opcion { transferencias, pagos, nada }

class HistorialmovimientosState extends State<Historialmovimientos> {
  final usuario = Sesion.usuarioActual;
  Opcion _seleccion = Opcion.nada;
  List<Transaccion> _transaccion = [];

  Future<void> cargarTransacciones() async {
    final dbHelper = DatabaseHelper();
    int cuentaInt = usuario!.idCuenta;
    List<Transaccion> resultado = [];

    if (_seleccion == Opcion.transferencias) {
      final data = await dbHelper.obtenerTransferencias(cuentaInt);
      resultado = data
          .map((mapa) => Transaccion.fromMap(mapa, 'TRANSFERENCIA'))
          .toList();
    } else if (_seleccion == Opcion.pagos) {
      final data = await dbHelper.obtenerPagos(cuentaInt);
      print(data);
      resultado = data
          .map((mapa) => Transaccion.fromMap(mapa, 'PAGO'))
          .toList();
    }

    setState(() {
      _transaccion = resultado;
    });
    print("resultado $resultado");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: Column(
        children: [
          // Encabezado estilo perfil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, bottom: 10),
            color: const Color(0xFF328535),
            child: Center(
              child: Text(
                'HISTORIAL',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 29.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: cuerpo()),
        ],
      ),
    );
  }

  Widget cuerpo() {
    return Column(
      children: [
        titulo(),
        radio("TRANSFERENCIAS"),
        radio("PAGOS"),
        Expanded(child: textos()),
      ],
    );
  }

  Widget titulo() {
    return Text(
      "Movimientos",
      style: GoogleFonts.poppins(fontSize: 45, color: const Color(0xFF328535)),
    );
  }

  Widget textos() {
    List<Transaccion> transaccionesFiltradas = _transaccion.where((t) {
      return t.tipo ==
          (_seleccion == Opcion.transferencias
              ? 'TRANSFERENCIA'
              : _seleccion == Opcion.pagos
              ? 'PAGO'
              : 'Nada');
    }).toList();

    if (transaccionesFiltradas.isEmpty) {
      return Center(
        child: Text(
          "Por favor, seleccione una opcion",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: transaccionesFiltradas.length,
      itemBuilder: (context, index) {
        final t = transaccionesFiltradas[index];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
          child: Row(
            children: [
              Image.asset(
                'assets/images/imgHistorial.png',
                width: 30,
                height: 51,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje(t)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String mensaje(t){
    if(_seleccion==Opcion.pagos){
      return "${t.fecha}\n${t.tipo} exitoso! Usted ha pagado: L.${t.monto}\na la cuenta: ${t.cuentaDestino}";
    }else if(_seleccion==Opcion.transferencias){
      if(usuario!.cuenta==t.cuentaDestino){
        return "${t.fecha}\n${t.tipo} exitosa! Usted ha recibido: L.${t.monto}\nde la cuenta: ${t.cuentaOrigen}\nConcepto: ${t.concepto}";
      }else{
        return "${t.fecha}\n${t.tipo} exitosa! Usted ha transferido: L.${t.monto}\na la cuenta: ${t.cuentaDestino}\nConcepto: ${t.concepto}";
      }
    }
    return "Por favor, seleccione una opcion.";
  }

  Widget radio(var opc) {
    Opcion valorRadio = opc == 'TRANSFERENCIAS'
        ? Opcion.transferencias
        : opc == 'PAGOS'
        ? Opcion.pagos
        : Opcion.nada;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 60),
      child: RadioListTile<Opcion>(
        controlAffinity: ListTileControlAffinity.trailing,
        title: Text(
          opc,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        value: valorRadio,
        groupValue: _seleccion,
        onChanged: (Opcion? nuevoValor) {
          setState(() {
            _seleccion = nuevoValor!;
            _transaccion.clear(); // Limpia mientras carga
          });
          cargarTransacciones(); // Carga desde BD
        },
      ),
    );
  }
}
