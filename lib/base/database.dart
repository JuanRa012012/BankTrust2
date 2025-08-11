import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        //PARA PODER TENER EL AVATAR AL AZAR EN EL PERFIL SE OCUPA GUARDAR ESE CAMPO EN LA BASE
        await db.execute('''
          CREATE TABLE CUENTAS(
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            NUMERO INTEGER,
            CLAVE VARCHAR(50),
            NOMBRE VARCHAR(50),
            SALDO NUMERIC(12,2),
            IMAGEN TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE TRANSFERENCIAS(
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            ID_CUENTA INTEGER REFERENCES CUENTAS(ID),
            ID_CUENTA_DESTINO INTEGER REFERENCES CUENTAS(ID),
            FECHA DATE DEFAULT CURRENT_DATE,
            MONTO NUMERIC(12,2),
            CONCEPTO VARCHAR(100)
          )
        ''');
        await db.execute('''
          CREATE TABLE PAGOS_TIPOS(
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            DESCRIPCION VARCHAR(100)
          )
        ''');
        await db.execute('''
          CREATE TABLE PAGOS(
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            ID_CUENTA INTEGER REFERENCES CUENTAS(ID),
            ID_TIPO INTEGER REFERENCES PAGOS_TIPOS(ID),
            FECHA DATE DEFAULT CURRENT_DATE,
            MONTO NUMERIC(12,2)
          )
        ''');
        await db.execute('''
          INSERT INTO PAGOS_TIPOS
          (
            DESCRIPCION
          )
          VALUES
          ('SANAA'), ('UNIVERSIDAD'), ('ENEE'), ('CABLE COLOR'), ('CLARO'), ('HONDUTEL'), ('TIGO');
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllCuentas() async {
    final db = await database;
    return await db.query('CUENTAS');
  }

  Future<void> insertCuenta(
    String nombre,
    int numero,
    String clave,
    double saldo,
  ) async {
    final db = await database;
    await db.insert('CUENTAS', {
      'NOMBRE': nombre,
      'NUMERO': numero,
      'CLAVE': clave,
      'SALDO': saldo,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int?> getCuentaIdPorNumero(int numeroCuenta) async {
    final db = await database;
    final result = await db.query(
      'CUENTAS',
      where: 'NUMERO = ?',
      whereArgs: [numeroCuenta],
    );

    if (result.isNotEmpty) {
      return result.first['ID'] as int;
    } else {
      return null;
    }
  }

  Future<void> updateCuentaClave(int id, String clave) async {
    final db = await database;
    await db.update(
      'CUENTAS',
      {'CLAVE': clave},
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTiposDePagos() async {
    final db = await database;
    return await db.query('PAGOS_TIPOS');
  }

  Future<List<Map<String, dynamic>>> obtenerTransferencias(int cuentaId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT 
      T.ID,
      T.FECHA,
      T.MONTO,
      T.CONCEPTO,
      T.ID_CUENTA,
      T.ID_CUENTA_DESTINO,
      C1.NUMERO AS NUMERO_ORIGEN,
      C2.NUMERO AS NUMERO_DESTINO
    FROM TRANSFERENCIAS T
    JOIN CUENTAS C1 ON T.ID_CUENTA = C1.ID
    JOIN CUENTAS C2 ON T.ID_CUENTA_DESTINO = C2.ID
    WHERE T.ID_CUENTA = ? OR T.ID_CUENTA_DESTINO = ?
    ORDER BY T.FECHA DESC
  ''',
      [cuentaId, cuentaId],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> obtenerPagos(int cuentaId) async {
    final db = await database;

    return await db.rawQuery(
      '''
    SELECT P.ID_CUENTA, P.FECHA, P.MONTO, PT.DESCRIPCION,
    C.NUMERO AS NUMERO_ORIGEN
    FROM PAGOS P
    JOIN PAGOS_TIPOS PT ON P.ID_TIPO = PT.ID
    JOIN CUENTAS C ON P.ID_CUENTA = C.ID
    WHERE P.ID_CUENTA = ?
    ORDER BY P.FECHA DESC
  ''',
      [cuentaId],
    );
  }

  Future<void> insertPagos(int id_cuenta, int id_tipo, double monto) async {
    final db = await database;
    await db.insert('PAGOS', {
      'ID_CUENTA': id_cuenta,
      'ID_TIPO': id_tipo,
      'MONTO': monto,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTransferencias(
    int? vrIdCuenta,
    int? vrIdCuentaDestino,
    double vrMonto,
    String vrConcepto,
  ) async {
    final db = await database;
    await db.insert('TRANSFERENCIAS', {
      'ID_CUENTA': vrIdCuenta,
      'ID_CUENTA_DESTINO': vrIdCuentaDestino,
      'MONTO': vrMonto,
      'CONCEPTO': vrConcepto,
    });

    actualizarSaldo(int.parse(vrIdCuenta.toString()), vrMonto);
    actualizarSaldo(int.parse(vrIdCuentaDestino.toString()), -vrMonto);
  }

  Future<double?> getSaldoActualPorIdCuenta(int idCuenta) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT SUM(SALDO) SALDO
    FROM (
      SELECT SALDO
      FROM CUENTAS
      WHERE ID = ?
      UNION ALL
      SELECT -SUM(MONTO)
      FROM TRANSFERENCIAS
      WHERE ID_CUENTA = ?
      UNION ALL
      SELECT -SUM(MONTO)
      FROM PAGOS
      WHERE ID_CUENTA = ?
      UNION ALL
      SELECT SUM(MONTO)
      FROM TRANSFERENCIAS
      WHERE ID_CUENTA_DESTINO = ?
      )
  ''',
      [idCuenta, idCuenta, idCuenta, idCuenta],
    );

    if (result.isNotEmpty && result.first['SALDO'] != null) {
      return (result.first['SALDO'] as num).toDouble();
    } else {
      return 0.0;
    }
  }

  Future<void> actualizarSaldo(int idCuenta, double monto) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE CUENTAS SET SALDO = SALDO - ? WHERE ID = ?',
      [monto, idCuenta],
    );
  }
}
