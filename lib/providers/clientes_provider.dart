import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/cliente.dart';

class ClientesProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Cliente> _clientes = [];
  bool _isLoading = false;

  List<Cliente> get clientes => _clientes;
  bool get isLoading => _isLoading;

  Future<void> loadClientes() async {
    _isLoading = true;
    notifyListeners();
    
    _clientes = await _db.getClientes();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> agregarCliente(String nombre, String telefono, String direccion) async {
    final nuevoCliente = Cliente(
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
      fechaCreacion: DateTime.now(),
    );
    await _db.insertCliente(nuevoCliente);
    await loadClientes();
  }

  Future<void> actualizarCliente(Cliente cliente) async {
    await _db.updateCliente(cliente);
    await loadClientes();
  }

  Future<void> eliminarCliente(int id) async {
    await _db.deleteCliente(id);
    await loadClientes();
  }
}
