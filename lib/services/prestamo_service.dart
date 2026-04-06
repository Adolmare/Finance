import '../core/database/database_helper.dart';
import '../models/prestamo.dart';
import '../models/pago.dart';

class PrestamoService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Calcula el total a pagar y genera el plan de cuotas calculadas equitativamente
  /// Inserta el préstamo y sus cuotas en SQLite a traves de una transaccion
  Future<Prestamo> crearPrestamo({
    required int clienteId,
    required double monto,
    required double interesPorcentaje,
    required int semanas,
  }) async {
    // Cálculo
    final double interesTotal = monto * (interesPorcentaje / 100);
    final double totalAPagar = monto + interesTotal;
    final double montoPorCuota = totalAPagar / semanas;
    final DateTime fechaInicio = DateTime.now();

    final nuevoPrestamo = Prestamo(
      clienteId: clienteId,
      monto: monto,
      interes: interesPorcentaje,
      totalAPagar: totalAPagar,
      cuotas: semanas,
      totalPagado: 0.0,
      estado: 'ACTIVO',
      fechaInicio: fechaInicio,
    );

    // Guardar en BD
    final idGuardado = await _dbHelper.insertPrestamo(nuevoPrestamo);
    final prestamoConId = nuevoPrestamo.copyWith(id: idGuardado);

    // Generar cuotas (pagos semanales)
    List<Pago> pagosAGenerar = [];
    for (int i = 1; i <= semanas; i++) {
      pagosAGenerar.add(Pago(
        prestamoId: idGuardado,
        numeroCuota: i,
        monto: montoPorCuota,
        fechaVencimiento: fechaInicio.add(Duration(days: 7 * i)),
        estado: 'PENDIENTE',
      ));
    }

    await _dbHelper.insertPagosBatch(pagosAGenerar);

    return prestamoConId;
  }

  /// Registrar un pago de una cuota específica
  Future<void> registrarPago(int pagoId, double montoPagado, int prestamoId) async {
    // 1. Obtener la lista de pagos para buscar el que vamos a actualizar
    final pagos = await _dbHelper.getPagosDePrestamo(prestamoId);
    final index = pagos.indexWhere((p) => p.id == pagoId);
    if (index == -1) throw Exception("Pago no encontrado");

    final pago = pagos[index];

    // Actualizar estado del pago a PAGADO y enviar a BD
    final pagoActualizado = pago.copyWith(
      estado: 'PAGADO',
      fechaPago: DateTime.now(),
    );
    await _dbHelper.updatePago(pagoActualizado);

    // 2. Reflejar en el préstamo
    final prestamos = await _dbHelper.getPrestamos();
    final pIndex = prestamos.indexWhere((p) => p.id == prestamoId);
    if (pIndex != -1) {
      final prestamoObj = prestamos[pIndex];
      final nuevoTotalPagado = prestamoObj.totalPagado + montoPagado;
      
      String nuevoEstado = prestamoObj.estado;
      if (nuevoTotalPagado >= prestamoObj.totalAPagar) {
        nuevoEstado = 'FINALIZADO';
      }

      final prestamoActualizado = prestamoObj.copyWith(
        totalPagado: nuevoTotalPagado,
        estado: nuevoEstado,
      );

      await _dbHelper.updatePrestamo(prestamoActualizado);
    }
  }

  /// Eliminar un crédito completo y sus cuotas (CASCADE en sqlite borra cuotas)
  Future<void> eliminarPrestamo(int prestamoId) async {
    await _dbHelper.deletePrestamo(prestamoId);
  }

  /// Aplica una multa/mora añadiendo una cuota extra al final y recalculando el total a pagar
  Future<void> aplicarMoraAPrestamo(int prestamoId, double montoMora) async {
    // 1. Obtener los pagos actuales para determinar la última fecha de pago y el número de cuota
    final pagos = await _dbHelper.getPagosDePrestamo(prestamoId);
    if (pagos.isEmpty) return;

    final ultimoPago = pagos.last;
    final nuevaFecha = ultimoPago.fechaVencimiento.add(const Duration(days: 7));
    final nuevaCuota = ultimoPago.numeroCuota + 1;

    // 2. Insertar nuevo pago extra (por mora)
    final nuevoPago = Pago(
      prestamoId: prestamoId,
      numeroCuota: nuevaCuota,
      monto: montoMora,
      fechaVencimiento: nuevaFecha,
      estado: 'PENDIENTE',
    );
    await _dbHelper.insertPago(nuevoPago);

    // 3. Actualizar el Prestamo sumando el total a pagar y las cuotas
    final prestamos = await _dbHelper.getPrestamos();
    final pIndex = prestamos.indexWhere((p) => p.id == prestamoId);
    if (pIndex != -1) {
      final prestamoObj = prestamos[pIndex];
      // Si la mora reactivara el crédito que estaba finalizado, lo regresa a ACTIVO.
      final nuevoEstado = (prestamoObj.totalPagado >= (prestamoObj.totalAPagar + montoMora)) 
          ? 'FINALIZADO' 
          : 'ACTIVO';

      final prestamoActualizado = prestamoObj.copyWith(
        totalAPagar: prestamoObj.totalAPagar + montoMora,
        cuotas: prestamoObj.cuotas + 1,
        estado: nuevoEstado,
      );

      await _dbHelper.updatePrestamo(prestamoActualizado);
    }
  }
}

