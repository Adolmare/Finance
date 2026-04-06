class Pago {
  final int? id;
  final int prestamoId;
  final int numeroCuota;
  final double monto;
  final DateTime fechaVencimiento;
  final DateTime? fechaPago;
  final String estado; // PENDIENTE, PAGADO

  Pago({
    this.id,
    required this.prestamoId,
    required this.numeroCuota,
    required this.monto,
    required this.fechaVencimiento,
    this.fechaPago,
    this.estado = 'PENDIENTE',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prestamo_id': prestamoId,
      'numero_cuota': numeroCuota,
      'monto': monto,
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'fecha_pago': fechaPago?.toIso8601String(),
      'estado': estado,
    };
  }

  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'],
      prestamoId: map['prestamo_id'],
      numeroCuota: map['numero_cuota'],
      monto: map['monto'],
      fechaVencimiento: DateTime.parse(map['fecha_vencimiento']),
      fechaPago: map['fecha_pago'] != null ? DateTime.parse(map['fecha_pago']) : null,
      estado: map['estado'],
    );
  }

  Pago copyWith({
    int? id,
    int? prestamoId,
    int? numeroCuota,
    double? monto,
    DateTime? fechaVencimiento,
    DateTime? fechaPago,
    String? estado,
  }) {
    return Pago(
      id: id ?? this.id,
      prestamoId: prestamoId ?? this.prestamoId,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      monto: monto ?? this.monto,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaPago: fechaPago ?? this.fechaPago,
      estado: estado ?? this.estado,
    );
  }
}
