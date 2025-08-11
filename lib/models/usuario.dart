class Usuario {
  final int idCuenta;
  final String nombre;
  final String cuenta;
  final double saldo;
  String? imagenBase64;

  Usuario({
    required this.idCuenta,
    required this.nombre,
    required this.cuenta,
    required this.saldo,
    this.imagenBase64,
  });
}