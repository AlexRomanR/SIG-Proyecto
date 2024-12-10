class RegistroCorte {
  final int codigoUbicacion;
  final int usuarioRelacionado;
  final int codigoFijo;
  final String nombre;
  final String medidorSerie;
  final String numeroMedidor;
  final String? valorMedidor;
  final String? observacion;
  final DateTime fechaCorte; 
  final String? fotoBase64;

  RegistroCorte({
    required this.codigoUbicacion,
    required this.usuarioRelacionado,
    required this.codigoFijo,
    required this.nombre,
    required this.medidorSerie,
    required this.numeroMedidor,
    this.valorMedidor,
    this.observacion,
    required this.fechaCorte,  
    this.fotoBase64,
  });

  // Método para convertir a Map (incluyendo fechaCorte)
  Map<String, dynamic> toMap() {
    return {
      'codigoUbicacion': codigoUbicacion,
      'usuarioRelacionado': usuarioRelacionado,
      'codigoFijo': codigoFijo,
      'nombre': nombre,
      'medidorSerie': medidorSerie,
      'numeroMedidor': numeroMedidor,
      'valorMedidor': valorMedidor,
      'observacion': observacion,
      'fechaCorte': fechaCorte.toIso8601String(),  
      'fotoBase64': fotoBase64,
    };
  }

  // Método para crear un RegistroCorte desde un Map (manejando la fechaCorte)
  factory RegistroCorte.fromMap(Map<String, dynamic> map) {
    return RegistroCorte(
      codigoUbicacion: map['codigoUbicacion'],
      usuarioRelacionado: map['usuarioRelacionado'],
      codigoFijo: map['codigoFijo'],
      nombre: map['nombre'],
      medidorSerie: map['medidorSerie'],
      numeroMedidor: map['numeroMedidor'],
      valorMedidor: map['valorMedidor'],
      observacion: map['observacion'],
      fechaCorte: DateTime.parse(map['fechaCorte']),  
      fotoBase64: map['fotoBase64'],
    );
  }
}