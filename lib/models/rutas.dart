class Ruta {
  final int bsrutnrut; // Número de la ruta
  final String bsrutdesc; // Descripción de la ruta
  final String bsrutabrv; // Abreviación de la ruta
  final int bsruttipo; // Tipo de ruta
  final int bsrutnzon; // Número de la zona
  final String bsrutfcor; // Fecha de corte
  final int bsrutcper; // Periodo de corte
  final int bsrutstat; // Estado de la ruta
  final int bsrutride; // Identificador único
  final String dNomb; // Nombre del responsable
  final int gbzonNzon; // Número de zona
  final String dNzon; // Descripción de la zona

  Ruta({
    required this.bsrutnrut,
    required this.bsrutdesc,
    required this.bsrutabrv,
    required this.bsruttipo,
    required this.bsrutnzon,
    required this.bsrutfcor,
    required this.bsrutcper,
    required this.bsrutstat,
    required this.bsrutride,
    required this.dNomb,
    required this.gbzonNzon,
    required this.dNzon,
  });

  // Constructor para crear un objeto Ruta desde un Map (JSON-like)
  factory Ruta.fromMap(Map<String, dynamic> map) {
    return Ruta(
      bsrutnrut: int.tryParse(map['bsrutnrut']) ?? 0,
      bsrutdesc: map['bsrutdesc']?.trim() ?? '',
      bsrutabrv: map['bsrutabrv']?.trim() ?? '',
      bsruttipo: int.tryParse(map['bsruttipo']) ?? 0,
      bsrutnzon: int.tryParse(map['bsrutnzon']) ?? 0,
      bsrutfcor: map['bsrutfcor']?.trim() ?? '',
      bsrutcper: int.tryParse(map['bsrutcper']) ?? 0,
      bsrutstat: int.tryParse(map['bsrutstat']) ?? 0,
      bsrutride: int.tryParse(map['bsrutride']) ?? 0,
      dNomb: map['dNomb']?.trim() ?? '',
      gbzonNzon: int.tryParse(map['GbzonNzon']) ?? 0,
      dNzon: map['dNzon']?.trim() ?? '',
    );
  }

  // Método opcional para convertir el objeto Ruta a JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'bsrutnrut': bsrutnrut,
      'bsrutdesc': bsrutdesc,
      'bsrutabrv': bsrutabrv,
      'bsruttipo': bsruttipo,
      'bsrutnzon': bsrutnzon,
      'bsrutfcor': bsrutfcor,
      'bsrutcper': bsrutcper,
      'bsrutstat': bsrutstat,
      'bsrutride': bsrutride,
      'dNomb': dNomb,
      'GbzonNzon': gbzonNzon,
      'dNzon': dNzon,
    };
  }
}
