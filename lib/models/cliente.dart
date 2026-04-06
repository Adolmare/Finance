class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String direccion;
  final DateTime fechaCreacion;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      direccion: map['direccion'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? direccion,
    DateTime? fechaCreacion,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

