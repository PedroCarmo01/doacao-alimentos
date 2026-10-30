import 'package:shared_models/shared_models.dart';

/// "Como chegar" (T22, T23): o endereço que abre a rota no app de mapas.
///
/// O formato `https://www.google.com/maps/dir/?api=1&destination=lat,lng`
/// é aberto pelo Google Maps (ou pelo navegador, se não houver app).
abstract final class RotaNoMapa {
  static Uri para(Coordenadas destino) => Uri.https(
    'www.google.com',
    '/maps/dir/',
    {'api': '1', 'destination': '${destino.latitude},${destino.longitude}'},
  );
}
