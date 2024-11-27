import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sig_proyecto/models/rutas.dart';
import 'package:sig_proyecto/server.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:sig_proyecto/models/registro_corte.dart';

class RutasService extends ChangeNotifier {
  List<Ruta> rutas = [];
  bool isLoading = true;
  final Server servidor = Server();

  // Método para cargar las rutas
  Future<List<Ruta>> loadRutas() async {
    isLoading = true;
    notifyListeners();

    // Construir el cuerpo SOAP
    String soapBody = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <W0Corte_ObtenerRutas xmlns="http://activebs.net/">
      <liNrut>1</liNrut>
      <liNcnt>0</liNcnt>
      <liCper>0</liCper>
    </W0Corte_ObtenerRutas>
  </soap:Body>
</soap:Envelope>''';

    try {
      // Realizar la solicitud HTTP POST
      final response = await http.post(
        Uri.parse('${servidor.baseURL}wsVarios/wsBS.asmx'),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '"http://activebs.net/W0Corte_ObtenerRutas"',
        },
        body: soapBody,
      );

      if (response.statusCode == 200) {
        // Analizar la respuesta XML y convertirla a objetos Ruta
        rutas = parseRutas(response.body);

        isLoading = false;
        notifyListeners();
        return rutas;
      } else {
        isLoading = false;
        notifyListeners();
        throw Exception('Failed to load rutas: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print('Error en loadRutas: $e');
      throw Exception('Error en loadRutas');
    }
  }

  // Método para analizar el XML y convertirlo a una lista de Rutas
  List<Ruta> parseRutas(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final rutas = <Ruta>[];

    // Buscar todas las etiquetas <Table>
    final tableElements = document.findAllElements('Table');
    for (var tableElement in tableElements) {
      // Crear un Map con los valores de cada columna
      final map = {
        'bsrutnrut': tableElement.getElement('bsrutnrut')?.innerText ?? '0',
        'bsrutdesc': tableElement.getElement('bsrutdesc')?.innerText ?? '',
        'bsrutabrv': tableElement.getElement('bsrutabrv')?.innerText ?? '',
        'bsruttipo': tableElement.getElement('bsruttipo')?.innerText ?? '0',
        'bsrutnzon': tableElement.getElement('bsrutnzon')?.innerText ?? '0',
        'bsrutfcor': tableElement.getElement('bsrutfcor')?.innerText ?? '',
        'bsrutcper': tableElement.getElement('bsrutcper')?.innerText ?? '0',
        'bsrutstat': tableElement.getElement('bsrutstat')?.innerText ?? '0',
        'bsrutride': tableElement.getElement('bsrutride')?.innerText ?? '0',
        'dNomb': tableElement.getElement('dNomb')?.innerText ?? '',
        'GbzonNzon': tableElement.getElement('GbzonNzon')?.innerText ?? '0',
        'dNzon': tableElement.getElement('dNzon')?.innerText ?? '',
      };

      // Agregar a la lista un objeto Ruta
      rutas.add(Ruta.fromMap(map));
    }

    return rutas;
  }

  Future<void> exportarCortesAlServidor(List<RegistroCorte> registros) async {
    for (var registro in registros) {
      // Construir el cuerpo SOAP con los valores correctos
      String fechaFormateada = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(registro.fechaCorte);
      String soapBody = '''
        <?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
            <W3Corte_UpdateCorte xmlns="http://activebs.net/">
              <liNcoc>${registro.codigoUbicacion}</liNcoc> 
              <liCemc>2</liCemc>
              <ldFcor>$fechaFormateada</ldFcor>
              <liPres>3</liPres>
              <liCobc>${registro.codigoFijo}</liCobc>
              <liLcor>${registro.valorMedidor}</liLcor>
              <liNofn>${registro.usuarioRelacionado}</liNofn>
              <lsAppName>FlutterApp</lsAppName>
            </W3Corte_UpdateCorte>
          </soap:Body>
        </soap:Envelope>''';

      print('Cuerpo SOAP: $soapBody');
      try {
        final response = await http.post(
          Uri.parse('${servidor.baseURL}wsVarios/wsBS.asmx'),
          headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            'SOAPAction': '"http://activebs.net/W3Corte_UpdateCorte"',
          },
          body: soapBody,
        );
        
        if (response.statusCode == 200) {
          print('Registro enviado con éxito: ${registro.codigoUbicacion}');
        } else {
          print('Error al enviar el registro ${registro.codigoUbicacion}: ${response.statusCode}');
        }
      } catch (e) {
        print('Error al enviar el registro ${registro.codigoUbicacion}: $e');
      }

    }
  }

}
