import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Configurações do backend.
///
/// Os valores vêm do arquivo `.env` da pasta `backend`. Se a mesma variável
/// existir no sistema operacional (por exemplo, na CI ou em um servidor), o
/// valor do sistema tem prioridade.
///
/// As variáveis são conferidas ao iniciar: se faltar alguma obrigatória, o
/// servidor nem sobe e a mensagem diz o que corrigir. É melhor falhar cedo
/// do que descobrir o problema no meio de uma requisição.
class Env {
  const Env({
    required this.dbHost,
    required this.dbPorta,
    required this.dbNome,
    required this.dbUsuario,
    required this.dbSenha,
    required this.dbTls,
    required this.jwtSegredo,
    required this.jwtValidade,
    required this.prazoReserva,
    required this.raioPadraoKm,
    required this.fusoHorarioUtc,
    required this.corsOrigem,
    required this.escutarNaRede,
    required this.consultarBrasilApi,
  });

  /// Lê o [arquivo] `.env` da pasta onde o comando foi executado.
  factory Env.carregar({String arquivo = '.env'}) {
    final doArquivo = DotEnv()..load([arquivo]);
    final leitor = _LeitorDeVariaveis(doArquivo, Platform.environment);

    final segredo = leitor.texto('JWT_SEGREDO');
    if (segredo.length < 32) {
      throw StateError(
        'JWT_SEGREDO deve ter pelo menos 32 caracteres. '
        'Gere um novo com o comando que está no .env.example.',
      );
    }

    return Env(
      dbHost: leitor.texto('DB_HOST', padrao: '127.0.0.1'),
      dbPorta: leitor.inteiro('DB_PORTA', padrao: 3306),
      dbNome: leitor.texto('DB_NOME', padrao: 'summit'),
      dbUsuario: leitor.texto('DB_USUARIO'),
      dbSenha: leitor.texto('DB_SENHA'),
      dbTls: leitor.booleano('DB_TLS', padrao: true),
      jwtSegredo: segredo,
      jwtValidade: Duration(
        days: leitor.inteiro('JWT_VALIDADE_DIAS', padrao: 30),
      ),
      prazoReserva: Duration(
        minutes: leitor.inteiro('RESERVA_MINUTOS', padrao: 60),
      ),
      raioPadraoKm: leitor.decimal('RAIO_PADRAO_KM', padrao: 10),
      fusoHorarioUtc: leitor.inteiro('FUSO_HORARIO', padrao: -3),
      corsOrigem: leitor.texto('CORS_ORIGEM', padrao: '*'),
      escutarNaRede: leitor.booleano('ESCUTAR_NA_REDE', padrao: false),
      consultarBrasilApi: leitor.booleano('CONSULTAR_BRASILAPI', padrao: true),
    );
  }

  final String dbHost;
  final int dbPorta;
  final String dbNome;
  final String dbUsuario;
  final String dbSenha;
  final bool dbTls;
  final String jwtSegredo;

  /// RN05: quanto tempo o login vale (JWT_VALIDADE_DIAS, padrão 30 dias).
  final Duration jwtValidade;
  final Duration prazoReserva;
  final double raioPadraoKm;
  final int fusoHorarioUtc;
  final String corsOrigem;
  final bool escutarNaRede;

  /// RN03: `false` = não consulta a BrasilAPI (para testar sem internet).
  /// Todo CNPJ com dígitos válidos vira "verificação pendente".
  final bool consultarBrasilApi;
}

/// Lê e converte variáveis, com mensagens de erro claras.
class _LeitorDeVariaveis {
  _LeitorDeVariaveis(this._arquivo, this._sistema);

  final DotEnv _arquivo;
  final Map<String, String> _sistema;

  String? _bruto(String chave) {
    final valor = (_sistema[chave] ?? _arquivo[chave])?.trim();
    return (valor == null || valor.isEmpty) ? null : valor;
  }

  StateError _faltando(String chave) => StateError(
    'A variável $chave não está definida. Você criou o arquivo .env? '
    '(na pasta backend: Copy-Item .env.example .env)',
  );

  String texto(String chave, {String? padrao}) =>
      _bruto(chave) ?? padrao ?? (throw _faltando(chave));

  int inteiro(String chave, {required int padrao}) {
    final valor = _bruto(chave);
    if (valor == null) return padrao;
    return int.tryParse(valor) ??
        (throw StateError(
          '$chave deve ser um número inteiro (atual: "$valor").',
        ));
  }

  double decimal(String chave, {required double padrao}) {
    final valor = _bruto(chave);
    if (valor == null) return padrao;
    return double.tryParse(valor.replaceAll(',', '.')) ??
        (throw StateError('$chave deve ser um número (atual: "$valor").'));
  }

  bool booleano(String chave, {required bool padrao}) {
    final valor = _bruto(chave)?.toLowerCase();
    if (valor == null) return padrao;
    if (const ['true', '1', 'sim'].contains(valor)) return true;
    if (const ['false', '0', 'nao', 'não'].contains(valor)) return false;
    throw StateError('$chave deve ser true ou false (atual: "$valor").');
  }
}
