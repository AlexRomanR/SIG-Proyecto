class RutasSinCortar {
  final int bscocNcoc;
  final int bscntCodf;
  final int bscocNcnt;
  final String dNomb;
  final int bscocNmor;
  final double bscocImor;
  final String bsmednser;
  final String bsmedNume;
  final double bscntlati;
  final double bscntlogi;
  final String dNcat;
  final String dCobc;
  final String dLotes;

  RutasSinCortar({
    required this.bscocNcoc,
    required this.bscntCodf,
    required this.bscocNcnt,
    required this.dNomb,
    required this.bscocNmor,
    required this.bscocImor,
    required this.bsmednser,
    required this.bsmedNume,
    required this.bscntlati,
    required this.bscntlogi,
    required this.dNcat,
    required this.dCobc,
    required this.dLotes,
  });

  // Constructor para crear un objeto RutasSinCortar desde un Map (JSON-like)
  factory RutasSinCortar.fromMap(Map<String, dynamic> map) {
    return RutasSinCortar(
      bscocNcoc: int.tryParse(map['bscocNcoc']) ?? 0,
      bscntCodf: int.tryParse(map['bscntCodf']) ?? 0,
      bscocNcnt: int.tryParse(map['bscocNcnt']) ?? 0,
      dNomb: map['dNomb'] ?? '',
      bscocNmor: int.tryParse(map['bscocNmor']) ?? 0,
      bscocImor: double.tryParse(map['bscocImor']) ?? 0.0,
      bsmednser: map['bsmednser']?.trim() ?? '',
      bsmedNume: map['bsmedNume']?.trim() ?? '',
      bscntlati: double.tryParse(map['bscntlati']) ?? 0.0,
      bscntlogi: double.tryParse(map['bscntlogi']) ?? 0.0,
      dNcat: map['dNcat']?.trim() ?? '',
      dCobc: map['dCobc']?.trim() ?? '',
      dLotes: map['dLotes']?.trim() ?? '',
    );
  }

  // Método opcional para convertir el objeto RutasSinCortar a JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'bscocNcoc': bscocNcoc,
      'bscntCodf': bscntCodf,
      'bscocNcnt': bscocNcnt,
      'dNomb': dNomb,
      'bscocNmor': bscocNmor,
      'bscocImor': bscocImor,
      'bsmednser': bsmednser,
      'bsmedNume': bsmedNume,
      'bscntlati': bscntlati,
      'bscntlogi': bscntlogi,
      'dNcat': dNcat,
      'dCobc': dCobc,
      'dLotes': dLotes,
    };
  }
}
