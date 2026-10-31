// Roteiro de ponta a ponta (etapa 8): percorre as regras do app contra o
// servidor DE VERDADE (MySQL) e mostra OK ou FALHOU em cada passo.
//
// Como usar (PowerShell, na pasta backend):
//   1. dart run tool/seed.dart          (dados de exemplo do zero)
//   2. dart_frog dev                    (servidor em http://127.0.0.1:8080)
//   3. dart run tool/roteiro_ponta_a_ponta.dart
//
// O roteiro MUDA os dados (publica, aceita, confirma). Para rodar de novo,
// recrie o seed antes. As regras que dependem de esperar o tempo passar
// (RN21, RN22 por expiração, RN24, RN29) estão nos testes automatizados e
// no passo a passo manual de docs/relatorio-de-testes.md.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> argumentos) async {
  final roteiro = Roteiro(
    argumentos.isEmpty ? 'http://127.0.0.1:8080' : argumentos.first,
  );
  await roteiro.executar();
  exit(roteiro.falhas == 0 ? 0 : 1);
}

/// A resposta de uma chamada: o status HTTP e o JSON (ou `null`).
class Resposta {
  Resposta(this.status, this.json);

  final int status;
  final Object? json;

  /// Um campo do objeto JSON (`null` se não houver).
  Object? operator [](String chave) {
    final corpo = json;
    return corpo is Map ? corpo[chave] : null;
  }
}

/// O roteiro: cada passo confere uma regra e conta as falhas.
class Roteiro {
  Roteiro(this.base);

  final String base;
  final Map<String, String> _tokens = {};
  int falhas = 0;

  // ---------------------------------------------------------- ferramentas

  Future<Resposta> chamar(
    String metodo,
    String caminho, {
    String? quem,
    Object? corpo,
  }) async {
    final requisicao = http.Request(metodo, Uri.parse('$base$caminho'));
    if (quem != null) {
      requisicao.headers['Authorization'] = 'Bearer ${_tokens[quem]}';
    }
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }
    final resposta = await http.Response.fromStream(await requisicao.send());
    final texto = utf8.decode(resposta.bodyBytes);
    return Resposta(
      resposta.statusCode,
      texto.isEmpty ? null : jsonDecode(texto),
    );
  }

  void conferir(String regra, String descricao, bool passou, [Object? info]) {
    if (!passou) falhas++;
    stdout.writeln(
      '${passou ? 'OK     ' : 'FALHOU '} $regra: $descricao'
      '${passou || info == null ? '' : '  ($info)'}',
    );
  }

  Future<void> entrar(String apelido) async {
    final r = await chamar(
      'POST',
      '/auth/login',
      corpo: {'email': '$apelido@exemplo.com', 'senha': 'senha123'},
    );
    _tokens[apelido] = '${r['token']}';
    conferir('RN05', 'login de $apelido', r.status == 200, r.status);
  }

  /// Os dados de uma doação válida, com o horário de retirada aberto.
  static Map<String, Object> _doacao(String titulo) {
    final agora = DateTime.now().toUtc();
    return {
      'titulo': titulo,
      'categoria': 'padaria',
      'quantidade': 30,
      'unidade': 'unidades',
      'pesoKg': 6,
      'conservacao': 'ambiente',
      'validade': _dia(agora.add(const Duration(days: 1))),
      'janelaInicio': agora.toIso8601String(),
      'janelaFim': agora.add(const Duration(hours: 3)).toIso8601String(),
      'declaracaoAlimentosProprios': true,
    };
  }

  /// Uma doação nova da padaria. Devolve o id (ou -1 se não deu).
  Future<int> padariaPublica(String titulo) async {
    final r = await chamar(
      'POST',
      '/doacoes',
      quem: 'padaria',
      corpo: _doacao(titulo),
    );
    final doacao = r['doacao'];
    return doacao is Map ? doacao['id'] as int : -1;
  }

  static String _dia(DateTime d) =>
      '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';

  // --------------------------------------------------------------- passos

  Future<void> executar() async {
    stdout.writeln('Roteiro de ponta a ponta em $base\n');
    final saude = await chamar('GET', '/');
    if (saude.status != 200) {
      stdout.writeln('O servidor não respondeu. Ele está rodando?');
      falhas++;
      return;
    }
    for (final apelido in [
      'mercado',
      'padaria',
      'maosamigas',
      'pratocheio',
      'distante',
      'suspensa',
    ]) {
      await entrar(apelido);
    }
    // O painel ANTES de tudo, para conferir no fim o que mudou.
    _impactoInicial = await chamar(
      'GET',
      '/comunidade/impacto',
      quem: 'mercado',
    );
    await contas();
    await doacoesEProximidade();
    await retirada();
    await comunidade();
    stdout.writeln(
      '\n${falhas == 0 ? 'Tudo certo!' : '$falhas passo(s) falharam.'}',
    );
  }

  Future<void> contas() async {
    final invalido = await chamar(
      'POST',
      '/auth/cadastro',
      corpo: {
        'tipo': 'ong',
        'nome': 'Teste',
        'email': 'roteiro@exemplo.com',
        'senha': 'senha123',
        'nomeOrganizacao': 'ONG Teste',
        'documento': '11111111111111',
        'latitude': -23.52,
        'longitude': -46.18,
        'aceitouTermos': true,
      },
    );
    conferir(
      'RN02',
      'CNPJ com dígitos errados é recusado',
      invalido.status == 400 || invalido.status == 422,
      invalido.status,
    );
    final repetido = await chamar(
      'POST',
      '/auth/login',
      corpo: {'email': 'mercado@exemplo.com', 'senha': 'errada'},
    );
    conferir(
      'RN05',
      'senha errada não entra',
      repetido.status == 401,
      repetido.status,
    );
  }

  late int _paes;
  late Resposta _impactoInicial;

  Future<void> doacoesEProximidade() async {
    final ontem = await chamar(
      'POST',
      '/doacoes',
      quem: 'padaria',
      corpo: {
        'titulo': 'Vencido',
        'categoria': 'padaria',
        'quantidade': 1,
        'unidade': 'unidades',
        'pesoKg': 1,
        'conservacao': 'ambiente',
        'validade': _dia(DateTime.now().subtract(const Duration(days: 2))),
        'janelaInicio': DateTime.now().toUtc().toIso8601String(),
        'janelaFim': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 2))
            .toIso8601String(),
        'declaracaoAlimentosProprios': true,
      },
    );
    conferir(
      'RN10',
      'validade vencida é recusada',
      ontem.status == 400,
      ontem.status,
    );
    final daOng = await chamar(
      'POST',
      '/doacoes',
      quem: 'maosamigas',
      corpo: _doacao('Doação de uma ONG'),
    );
    conferir(
      'RN10',
      'ONG não publica doação',
      daOng.status == 403,
      daOng.status,
    );

    _paes = await padariaPublica('Pães do roteiro');
    conferir('RN10', 'a padaria publica', _paes > 0, _paes);

    final perto = await chamar('GET', '/proximas', quem: 'maosamigas');
    final longe = await chamar('GET', '/proximas', quem: 'distante');
    conferir(
      'RN11',
      'a ONG perto vê a doação nova',
      jsonEncode(perto.json).contains('"id":$_paes,'),
    );
    conferir(
      'RN11',
      'a ONG a 45 km não vê',
      !jsonEncode(longe.json).contains('"id":$_paes,'),
    );
    final aviso = await chamar(
      'GET',
      '/notificacoes?depois=0',
      quem: 'pratocheio',
    );
    conferir(
      'RN11',
      'a ONG perto recebeu o aviso "doação nova"',
      jsonEncode(aviso.json).contains('Pães do roteiro'),
    );
  }

  late int _reserva;

  Future<void> retirada() async {
    final suspensa = await chamar(
      'POST',
      '/reservas',
      quem: 'suspensa',
      corpo: {'doacaoId': _paes},
    );
    conferir(
      'RN24',
      'ONG suspensa não aceita',
      suspensa['erro'] is Map &&
          '${(suspensa['erro'] as Map)['codigo']}' == 'ONG_SUSPENSA',
      suspensa.status,
    );

    // RN20: as duas no mesmo instante; só uma pode ganhar.
    final corrida = await Future.wait([
      chamar(
        'POST',
        '/reservas',
        quem: 'maosamigas',
        corpo: {'doacaoId': _paes},
      ),
      chamar(
        'POST',
        '/reservas',
        quem: 'pratocheio',
        corpo: {'doacaoId': _paes},
      ),
    ]);
    final status = [for (final r in corrida) r.status]..sort();
    conferir(
      'RN20',
      'duas ONGs ao mesmo tempo: só uma fica',
      status.join(',') == '201,409',
      status,
    );
    final vencedora = corrida.first.status == 201 ? 'maosamigas' : 'pratocheio';
    final ganhou = corrida.firstWhere((r) => r.status == 201);
    _reserva = ganhou['id'] as int;
    final codigo = '${ganhou['codigoRetirada']}';
    conferir(
      'RN26',
      'a ONG recebe o código de 4 dígitos',
      RegExp(r'^\d{4}$').hasMatch(codigo),
      codigo,
    );

    final paraDoador = await chamar('GET', '/doacoes/$_paes', quem: 'padaria');
    conferir(
      'RN26',
      'o doador não recebe o código',
      !jsonEncode(paraDoador.json).contains('codigoRetirada'),
    );

    final aceita = await chamar(
      'GET',
      '/notificacoes?depois=0',
      quem: 'padaria',
    );
    conferir(
      'Seção 9',
      'o doador foi avisado do aceite',
      jsonEncode(aceita.json).contains('doacaoAceita'),
    );

    final mensagem = await chamar(
      'POST',
      '/conversas/$_reserva/mensagens',
      quem: vencedora,
      corpo: {'texto': 'Estou a caminho'},
    );
    conferir(
      'RN30',
      'a ONG da retirada conversa com o doador',
      mensagem.status == 201,
      mensagem.status,
    );
    final intrusa = await chamar(
      'GET',
      '/conversas/$_reserva/mensagens',
      quem: 'distante',
    );
    conferir(
      'RN30',
      'outra ONG não lê a conversa',
      intrusa.status == 404,
      intrusa.status,
    );

    final semMotivo = await chamar(
      'DELETE',
      '/doacoes/$_paes',
      quem: 'padaria',
    );
    conferir(
      'RN12',
      'cancelar reservada sem motivo é recusado',
      semMotivo.status == 400,
      semMotivo.status,
    );

    final errado = await chamar(
      'POST',
      '/reservas/$_reserva/confirmar',
      quem: 'padaria',
      corpo: {'codigo': codigo == '0000' ? '1111' : '0000'},
    );
    conferir(
      'RN27',
      'código errado é recusado',
      errado.status == 400,
      errado.status,
    );
    final certo = await chamar(
      'POST',
      '/reservas/$_reserva/confirmar',
      quem: 'padaria',
      corpo: {'codigo': codigo},
    );
    conferir(
      'RN27',
      'código certo conclui a retirada',
      certo['status'] == 'concluida',
      certo.status,
    );

    final depois = await chamar(
      'POST',
      '/conversas/$_reserva/mensagens',
      quem: 'padaria',
      corpo: {'texto': 'Obrigado!'},
    );
    conferir(
      'RN31',
      'depois da retirada o chat é só leitura',
      depois.status == 409,
      depois.status,
    );

    // RN23: aceitar e desistir logo em seguida não conta.
    final outra = await padariaPublica('Pães da tolerância');
    final aceite = await chamar(
      'POST',
      '/reservas',
      quem: 'pratocheio',
      corpo: {'doacaoId': outra},
    );
    final desistencia = await chamar(
      'DELETE',
      '/reservas/${aceite['id']}',
      quem: 'pratocheio',
    );
    conferir(
      'RN23',
      'desistir em menos de 5 min não conta',
      desistencia['contouDesistencia'] == false,
      desistencia.json,
    );

    // RN25: no máximo 2 retiradas ao mesmo tempo (a Mãos Amigas já tem as
    // cestas do exemplo).
    final a = await padariaPublica('Pães A');
    final b = await padariaPublica('Pães B');
    final primeira = await chamar(
      'POST',
      '/reservas',
      quem: 'maosamigas',
      corpo: {'doacaoId': a},
    );
    final terceira = await chamar(
      'POST',
      '/reservas',
      quem: 'maosamigas',
      corpo: {'doacaoId': b},
    );
    conferir(
      'RN25',
      'a 3ª retirada ao mesmo tempo é recusada',
      primeira.status == 201 && terceira.status == 409,
      [primeira.status, terceira.status],
    );
    final comMotivo = await chamar(
      'DELETE',
      '/doacoes/$a',
      quem: 'padaria',
      corpo: {'motivo': 'Acabou o estoque'},
    );
    conferir(
      'RN12',
      'cancelar reservada com motivo, sem punir a ONG',
      comMotivo.status == 204,
      comMotivo.status,
    );
  }

  Future<void> comunidade() async {
    final antes = _impactoInicial;
    final publicacao = await chamar(
      'POST',
      '/comunidade/publicacoes',
      quem: 'padaria',
      corpo: {
        'texto': 'Os pães do roteiro alimentaram 10 famílias.',
        'doacaoId': _paes,
        'familiasAjudadas': 10,
      },
    );
    conferir(
      'RN40',
      'publicar sobre uma doação concluída',
      publicacao.status == 201,
      publicacao.status,
    );
    final id = publicacao['id'];
    final depois = await chamar('GET', '/comunidade/impacto', quem: 'mercado');
    conferir(
      'Impacto',
      'o painel somou as famílias e os kg',
      (depois['familiasAjudadas'] as int) -
                  (antes['familiasAjudadas'] as int) ==
              10 &&
          (depois['doacoesConcluidas'] as int) >
              (antes['doacoesConcluidas'] as int),
    );

    await chamar('POST', '/comunidade/publicacoes/$id/apoio', quem: 'mercado');
    final duasVezes = await chamar(
      'POST',
      '/comunidade/publicacoes/$id/apoio',
      quem: 'mercado',
    );
    conferir(
      'RN41',
      'apoiar duas vezes conta uma',
      duasVezes['apoios'] == 1,
      duasVezes['apoios'],
    );

    for (final quem in ['mercado', 'maosamigas', 'distante']) {
      await chamar(
        'POST',
        '/comunidade/publicacoes/$id/denuncia',
        quem: quem,
        corpo: {'motivo': 'outro'},
      );
    }
    final feed = await chamar(
      'GET',
      '/comunidade/publicacoes',
      quem: 'padaria',
    );
    conferir(
      'RN42',
      '3 denúncias escondem a publicação',
      !jsonEncode(feed.json).contains('"id":$id,'),
    );
  }
}
