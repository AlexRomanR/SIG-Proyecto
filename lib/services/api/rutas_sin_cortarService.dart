import 'package:flutter/material.dart';
import 'package:gestion_asistencia_docente/models/rutas_sin_cortar.dart';
import 'package:gestion_asistencia_docente/server.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class RutasSinCortarService extends ChangeNotifier {
  List<RutasSinCortar> rutas = [];
  bool isLoading = true;
  final Server servidor = Server();

  // Método para cargar las rutas sin cortar
  Future<List<RutasSinCortar>> loadRutasSinCortar({int? rutaId}) async {
    isLoading = true;
    notifyListeners();

    // Construir el cuerpo SOAP
    String soapBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <W2Corte_ReporteParaCortesSIG xmlns="http://activebs.net/">
      <liNrut>${rutaId ?? 1}</liNrut>
      <liNcnt>0</liNcnt>
      <liCper>0</liCper>
    </W2Corte_ReporteParaCortesSIG>
  </soap:Body>
</soap:Envelope>''';

    try {
      // Realizar la solicitud HTTP POST
      final response = await http.post(
        Uri.parse('${servidor.baseURL}wsVarios/wsBS.asmx'),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '"http://activebs.net/W2Corte_ReporteParaCortesSIG"',
        },
        body: soapBody,
      );

      if (response.statusCode == 200) {
        // Analizar la respuesta XML y convertirla a objetos RutasSinCortar
        rutas = parseRutasSinCortar(response.body);

        isLoading = false;
        notifyListeners();
        return rutas;
      } else {
        isLoading = false;
        notifyListeners();
        throw Exception('Failed to load rutas sin cortar: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('Error en loadRutasSinCortar: $e');
      throw Exception('Error en loadRutasSinCortar');
    }
  }

  // Método para analizar el XML y convertirlo a una lista de RutasSinCortar
  List<RutasSinCortar> parseRutasSinCortar(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final rutas = <RutasSinCortar>[];

    // Buscar todas las etiquetas <Table>
    final tableElements = document.findAllElements('Table');
    for (var tableElement in tableElements) {
      // Crear un Map con los valores de cada columna
      final map = {
        'bscocNcoc': tableElement.getElement('bscocNcoc')?.innerText ?? '0',
        'bscntCodf': tableElement.getElement('bscntCodf')?.innerText ?? '0',
        'bscocNcnt': tableElement.getElement('bscocNcnt')?.innerText ?? '0',
        'dNomb': tableElement.getElement('dNomb')?.innerText ?? '',
        'bscocNmor': tableElement.getElement('bscocNmor')?.innerText ?? '0',
        'bscocImor': tableElement.getElement('bscocImor')?.innerText ?? '0.0',
        'bsmednser': tableElement.getElement('bsmednser')?.innerText ?? '',
        'bsmedNume': tableElement.getElement('bsmedNume')?.innerText ?? '',
        'bscntlati': tableElement.getElement('bscntlati')?.innerText ?? '0.0',
        'bscntlogi': tableElement.getElement('bscntlogi')?.innerText ?? '0.0',
        'dNcat': tableElement.getElement('dNcat')?.innerText ?? '',
        'dCobc': tableElement.getElement('dCobc')?.innerText ?? '',
        'dLotes': tableElement.getElement('dLotes')?.innerText ?? '',
      };

      // Agregar a la lista un objeto RutasSinCortar
      rutas.add(RutasSinCortar.fromMap(map));
    }

    return rutas;
  }
}
