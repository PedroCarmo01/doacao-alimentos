import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../../core/erros/erro_amigavel.dart';

/// Endereço encontrado pelo CEP (cadastro T4, etapa 4).
class EnderecoDoCep {
  const EnderecoDoCep({
    required this.cep,
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.uf,
    this.coordenadas,
  });

  final String cep;
  final String rua;
  final String bairro;
  final String cidade;
  final String uf;

  /// Nem todo CEP tem coordenadas na BrasilAPI.
  final Coordenadas? coordenadas;

  /// "Rua X, Bairro - Cidade/UF" (sem o número: a pessoa completa).
  String get textoParaEndereco {
    final partes = [rua, bairro].where((parte) => parte.isNotEmpty).join(', ');
    return '$partes - $cidade/$uf';
  }
}

/// CONTRATO: buscar o endereço de um CEP.
///
/// Diferente dos outros repositórios, este NÃO passa pelo nosso backend:
/// o app consulta a BrasilAPI direto, porque é um dado público e não precisa
/// de login. Lança [ErroDeRegra] com uma mensagem que diz o que fazer.
abstract interface class CepRepository {
  Future<EnderecoDoCep> buscar(String cep);
}

/// `GET https://brasilapi.com.br/api/cep/v2/{cep}`.
class CepRepositoryBrasilApi implements CepRepository {
  CepRepositoryBrasilApi({http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  static const tempoLimite = Duration(seconds: 8);

  final http.Client _cliente;

  @override
  Future<EnderecoDoCep> buscar(String cep) async {
    final numero = _conferir(cep);
    final http.Response resposta;
    try {
      resposta = await _cliente
          .get(Uri.parse('https://brasilapi.com.br/api/cep/v2/$numero'))
          .timeout(tempoLimite);
    } on TimeoutException {
      throw _semConexao;
    } on http.ClientException {
      throw _semConexao;
    }
    if (resposta.statusCode == 404) {
      throw const ErroDeRegra(
        'CEP não encontrado. Confira os números ou use o GPS.',
      );
    }
    if (resposta.statusCode != 200) throw _semConexao;
    try {
      return _ler(numero, utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw _semConexao; // resposta que não é JSON
    } on TypeError {
      throw _semConexao; // JSON com formato inesperado
    }
  }

  static const _semConexao = ErroDeRegra(
    'Não foi possível buscar o CEP agora. Digite o endereço ou use o GPS.',
  );

  EnderecoDoCep _ler(String cep, String texto) {
    final json = jsonDecode(texto) as Map<String, dynamic>;
    final localizacao = json['location'];
    Coordenadas? coordenadas;
    if (localizacao is Map && localizacao['coordinates'] is Map) {
      final pontos = localizacao['coordinates'] as Map;
      // A BrasilAPI manda as coordenadas como texto ("-23.52").
      final latitude = double.tryParse('${pontos['latitude']}');
      final longitude = double.tryParse('${pontos['longitude']}');
      if (latitude != null && longitude != null) {
        coordenadas = Coordenadas(latitude, longitude);
      }
    }
    return EnderecoDoCep(
      cep: cep,
      rua: '${json['street'] ?? ''}',
      bairro: '${json['neighborhood'] ?? ''}',
      cidade: '${json['city'] ?? ''}',
      uf: '${json['state'] ?? ''}',
      coordenadas: coordenadas,
    );
  }
}

/// Sem internet: qualquer CEP válido devolve o centro de Mogi das Cruzes.
class CepRepositoryFake implements CepRepository {
  const CepRepositoryFake();

  @override
  Future<EnderecoDoCep> buscar(String cep) async {
    final numero = _conferir(cep);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return EnderecoDoCep(
      cep: numero,
      rua: 'Avenida Vereador Narciso Yague Guimarães',
      bairro: 'Centro Cívico',
      cidade: 'Mogi das Cruzes',
      uf: 'SP',
      coordenadas: const Coordenadas(-23.5228, -46.1883),
    );
  }
}

/// Usada pelas duas implementações: CEP precisa ter 8 números.
String _conferir(String cep) {
  final erro = ValidadorUsuario.cep(cep);
  final numero = ValidadorDocumento.somenteDigitos(cep);
  if (erro != null || numero.isEmpty) {
    throw const ErroDeRegra('Digite os 8 números do CEP.');
  }
  return numero;
}
