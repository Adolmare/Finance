import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/cliente.dart';
import '../../models/prestamo.dart';
import '../../models/pago.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE clientes (
  id $idType,
  nombre $textType,
  telefono $textType,
  direccion $textType,
  fecha_creacion $textType
)
''');

    await db.execute('''
CREATE TABLE prestamos (
  id $idType,
  cliente_id $integerType,
  monto $realType,
  interes $realType,
  total_a_pagar $realType,
  cuotas $integerType,
  total_pagado $realType,
  estado $textType,
  fecha_inicio $textType,
  FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE pagos (
  id $idType,
  prestamo_id $integerType,
  numero_cuota $integerType,
  monto $realType,
  fecha_vencimiento $textType,
  fecha_pago TEXT,
  estado $textType,
  FOREIGN KEY (prestamo_id) REFERENCES prestamos (id) ON DELETE CASCADE
)
''');
  }

  // --- CRUD Clientes ---
  Future<int> insertCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> getClientes() async {
    final db = await instance.database;
    final result = await db.query('clientes', orderBy: 'nombre ASC');
    return result.map((map) => Cliente.fromMap(map)).toList();
  }

  Future<Cliente?> getCliente(int id) async {
    final db = await instance.database;
    final result = await db.query('clientes', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Cliente.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCliente(Cliente cliente) async {
    final db = await instance.database;
    return await db.update('clientes', cliente.toMap(),
        where: 'id = ?', whereArgs: [cliente.id]);
  }

  Future<int> deleteCliente(int id) async {
    final db = await instance.database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Prestamos ---
  Future<int> insertPrestamo(Prestamo prestamo) async {
    final db = await instance.database;
    return await db.insert('prestamos', prestamo.toMap());
  }

  Future<List<Prestamo>> getPrestamos() async {
    final db = await instance.database;
    final result = await db.query('prestamos', orderBy: 'fecha_inicio DESC');
    return result.map((map) => Prestamo.fromMap(map)).toList();
  }

  Future<int> updatePrestamo(Prestamo prestamo) async {
    final db = await instance.database;
    return await db.update('prestamos', prestamo.toMap(),
        where: 'id = ?', whereArgs: [prestamo.id]);
  }

  Future<int> deletePrestamo(int id) async {
    final db = await instance.database;
    return await db.delete('prestamos', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD Pagos ---
  Future<int> insertPago(Pago pago) async {
    final db = await instance.database;
    return await db.insert('pagos', pago.toMap());
  }

  Future<void> insertPagosBatch(List<Pago> pagos) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var pago in pagos) {
      batch.insert('pagos', pago.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Pago>> getPagosDePrestamo(int prestamoId) async {
    final db = await instance.database;
    final result = await db.query('pagos',
        where: 'prestamo_id = ?',
        whereArgs: [prestamoId],
        orderBy: 'numero_cuota ASC');
    return result.map((map) => Pago.fromMap(map)).toList();
  }

  Future<int> updatePago(Pago pago) async {
    final db = await instance.database;
    return await db.update('pagos', pago.toMap(),
        where: 'id = ?', whereArgs: [pago.id]);
  }
}
