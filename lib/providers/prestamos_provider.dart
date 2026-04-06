import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/prestamo.dart';
import '../models/pago.dart';
import '../services/prestamo_service.dart';

class PrestamosProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final PrestamoService _service = PrestamoService();
  
  List<Prestamo> _prestamos = [];
  bool _isLoading = false;

  List<Prestamo> get prestamos => _prestamos;
  bool get isLoading => _isLoading;

  Future<void> loadPrestamos() async {
    _isLoading = true;
    notifyListeners();

    _prestamos = await _db.getPrestamos();
    
    _isLoading = false;
    notifyListeners();
  }

  List<Prestamo> prestamosPorCliente(int clienteId) {
    return _prestamos.where((p) => p.clienteId == clienteId).toList();
  }

  Future<void> otorgarPrestamo({
    required int clienteId, 
    required double monto, 
    required double interes, 
    required int semanas
  }) async {
    await _service.crearPrestamo(
      clienteId: clienteId,
      monto: monto,
      interesPorcentaje: interes,
      semanas: semanas,
    );
    await loadPrestamos();
  }

  Future<List<Pago>> obtenerPagosDePrestamo(int prestamoId) async {
    return await _db.getPagosDePrestamo(prestamoId);
  }

  Future<void> registrarPago(int pagoId, double monto, int prestamoId) async {
    await _service.registrarPago(pagoId, monto, prestamoId);
    await loadPrestamos();
  }

  Future<void> eliminarPrestamo(int prestamoId) async {
    await _service.eliminarPrestamo(prestamoId);
    await loadPrestamos();
  }

  /// Calcula la deuda activa de un cliente en específico sumando totalAPagar menos totalPagado
  double deudaTotalActivaPorCliente(int clienteId) {
    final activos = prestamosPorCliente(clienteId).where((p) => p.estado == 'ACTIVO');
    double total = 0;
    for (var p in activos) {
      total += p.totalRestante;
    }
    return total;
  }

  Future<void> aplicarMora(int prestamoId, double montoMora) async {
    await _service.aplicarMoraAPrestamo(prestamoId, montoMora);
    await loadPrestamos();
  }

  double get dineroTotalPrestado {
    return _prestamos.fold(0.0, (sum, prestamo) => sum + prestamo.monto);
  }

  double get dineroTotalRecogido {
    return _prestamos.fold(0.0, (sum, prestamo) => sum + prestamo.totalPagado);
  }
}

