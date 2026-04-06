class Prestamo {
  final int? id;
  final int clienteId;
  final double monto;
  final double interes;
  final double totalAPagar;
  final int cuotas;
  final double totalPagado;
  final String estado; // ACTIVO o FINALIZADO
  final DateTime fechaInicio;

  Prestamo({
    this.id,
    required this.clienteId,
    required this.monto,
    required this.interes,
    required this.totalAPagar,
    required this.cuotas,
    this.totalPagado = 0.0,
    this.estado = 'ACTIVO',
    required this.fechaInicio,
  });

  double get totalRestante => totalAPagar - totalPagado;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'monto': monto,
      'interes': interes,
      'total_a_pagar': totalAPagar,
      'cuotas': cuotas,
      'total_pagado': totalPagado,
      'estado': estado,
      'fecha_inicio': fechaInicio.toIso8601String(),
    };
  }

  factory Prestamo.fromMap(Map<String, dynamic> map) {
    return Prestamo(
      id: map['id'],
      clienteId: map['cliente_id'],
      monto: map['monto'],
      interes: map['interes'],
      totalAPagar: map['total_a_pagar'],
      cuotas: map['cuotas'],
      totalPagado: map['total_pagado'],
      estado: map['estado'],
      fechaInicio: DateTime.parse(map['fecha_inicio']),
    );
  }

  Prestamo copyWith({
    int? id,
    int? clienteId,
    double? monto,
    double? interes,
    double? totalAPagar,
    int? cuotas,
    double? totalPagado,
    String? estado,
    DateTime? fechaInicio,
  }) {
    return Prestamo(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      monto: monto ?? this.monto,
      interes: interes ?? this.interes,
      totalAPagar: totalAPagar ?? this.totalAPagar,
      cuotas: cuotas ?? this.cuotas,
      totalPagado: totalPagado ?? this.totalPagado,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
    );
  }
}
