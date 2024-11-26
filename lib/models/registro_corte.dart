class RegistroCorte {
  final int codigoUbicacion;
  final int codigoFijo;
  final String nombre;
  final String medidorSerie;
  final String numeroMedidor;
  final String valorMedidor;
  final DateTime fechaCorte; 

  RegistroCorte({
    required this.codigoUbicacion,
    required this.codigoFijo,
    required this.nombre,
    required this.medidorSerie,
    required this.numeroMedidor,
    required this.valorMedidor,
    required this.fechaCorte,  
  });

  // Método para convertir a Map (incluyendo fechaCorte)
  Map<String, dynamic> toMap() {
    return {
      'codigoUbicacion': codigoUbicacion,
      'codigoFijo': codigoFijo,
      'nombre': nombre,
      'medidorSerie': medidorSerie,
      'numeroMedidor': numeroMedidor,
      'valorMedidor': valorMedidor,
      'fechaCorte': fechaCorte.toIso8601String(),  
    };
  }

  // Método para crear un RegistroCorte desde un Map (manejando la fechaCorte)
  factory RegistroCorte.fromMap(Map<String, dynamic> map) {
    return RegistroCorte(
      codigoUbicacion: map['codigoUbicacion'],
      codigoFijo: map['codigoFijo'],
      nombre: map['nombre'],
      medidorSerie: map['medidorSerie'],
      numeroMedidor: map['numeroMedidor'],
      valorMedidor: map['valorMedidor'],
      fechaCorte: DateTime.parse(map['fechaCorte']),  
    );
  }
}