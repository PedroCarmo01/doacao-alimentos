import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('Usuario', () {
    test('converte para JSON e volta sem perder dados', () {
      final json = {
        'id': 1,
        'nome': 'Maria Souza',
        'email': 'maria@exemplo.com',
        'tipo': 'doador',
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.tipo, TipoUsuario.doador);
      expect(usuario.ehDoador, isTrue);
      expect(usuario.toJson(), json);
    });

    test('campo obrigatório ausente gera FormatException clara', () {
      expect(
        () => Usuario.fromJson({'id': 1, 'nome': 'X', 'tipo': 'ong'}),
        throwsA(
          isA<FormatException>().having(
            (erro) => erro.message,
            'mensagem',
            contains('"email"'),
          ),
        ),
      );
    });

    test('tipo desconhecido é rejeitado', () {
      expect(
        () => Usuario.fromJson({
          'id': 1,
          'nome': 'X',
          'email': 'x@exemplo.com',
          'tipo': 'administrador',
        }),
        throwsFormatException,
      );
    });
  });

  group('Doacao', () {
    final doacao = Doacao(
      id: 10,
      doadorId: 1,
      titulo: 'Frutas do dia',
      categoria: CategoriaAlimento.hortifruti,
      quantidade: 5,
      unidade: Unidade.caixas,
      pesoKg: 25,
      conservacao: Conservacao.ambiente,
      fotos: const ['abc.jpg'],
      validade: DateTime.utc(2026, 9, 20),
      janelaInicio: DateTime.utc(2026, 9, 15, 14),
      janelaFim: DateTime.utc(2026, 9, 15, 20),
      latitude: -23.5229,
      longitude: -46.1880,
      status: StatusDoacao.disponivel,
      criadoEm: DateTime.utc(2026, 9, 15, 13),
    );

    test('JSON usa camelCase, validade AAAA-MM-DD e instantes em UTC', () {
      final json = doacao.toJson();

      expect(json['doadorId'], 1);
      expect(json['validade'], '2026-09-20');
      expect(json['janelaInicio'], '2026-09-15T14:00:00.000Z');
      expect(json['categoria'], 'hortifruti');
    });

    test('ida e volta pelo JSON preserva os valores', () {
      final copia = Doacao.fromJson(doacao.toJson());

      expect(copia.id, doacao.id);
      expect(copia.validade, doacao.validade);
      expect(copia.janelaFim, doacao.janelaFim);
      expect(copia.categoria, doacao.categoria);
      expect(copia.fotos, ['abc.jpg']);
      expect(copia.unidade, Unidade.caixas);
    });

    test('quantidadeTexto junta número e unidade', () {
      expect(doacao.quantidadeTexto, '5 caixas');
    });

    test('RN12: edita só disponível; cancela disponível ou reservada', () {
      final reservada = doacao.copyWith(status: StatusDoacao.reservada);
      final concluida = doacao.copyWith(status: StatusDoacao.concluida);

      expect(doacao.podeSerEditada, isTrue);
      expect(doacao.cancelamentoExigeMotivo, isFalse);
      expect(reservada.podeSerEditada, isFalse);
      expect(reservada.podeSerCancelada, isTrue);
      expect(reservada.cancelamentoExigeMotivo, isTrue);
      expect(concluida.podeSerCancelada, isFalse);
    });

    test('RN13: expirada vai para o histórico', () {
      expect(StatusDoacao.expirada.ativa, isFalse);
      expect(StatusDoacao.reservada.ativa, isTrue);
    });

    test('só pode ser reservada se disponível e com a janela aberta', () {
      final durante = DateTime.utc(2026, 9, 15, 15);
      final depois = DateTime.utc(2026, 9, 15, 21);

      expect(doacao.podeSerReservada(durante), isTrue);
      expect(doacao.podeSerReservada(depois), isFalse);
      expect(
        doacao
            .copyWith(status: StatusDoacao.reservada)
            .podeSerReservada(durante),
        isFalse,
      );
    });
  });

  group('Reserva', () {
    final reserva = Reserva(
      id: 7,
      doacaoId: 10,
      ongId: 3,
      status: StatusReserva.ativa,
      reservadoEm: DateTime.utc(2026, 9, 15, 14),
      expiraEm: DateTime.utc(2026, 9, 15, 16),
    );

    test('tempo restante nunca é negativo', () {
      expect(
        reserva.tempoRestante(DateTime.utc(2026, 9, 15, 15)),
        const Duration(hours: 1),
      );
      expect(
        reserva.tempoRestante(DateTime.utc(2026, 9, 15, 17)),
        Duration.zero,
      );
    });

    test('fica vencida quando o prazo passa', () {
      expect(reserva.estaVencida(DateTime.utc(2026, 9, 15, 15)), isFalse);
      expect(reserva.estaVencida(DateTime.utc(2026, 9, 15, 16)), isTrue);
    });

    test('RN23: tolerância de 5 min contada a partir do aceite', () {
      const cinco = Duration(minutes: 5);
      final aceite = reserva.reservadoEm;
      expect(
        reserva.dentroDaTolerancia(
          aceite.add(const Duration(minutes: 5)),
          cinco,
        ),
        isTrue,
      );
      expect(
        reserva.dentroDaTolerancia(
          aceite.add(const Duration(minutes: 6)),
          cinco,
        ),
        isFalse,
      );
    });

    test('RN26: semCodigo tira o código e mantém o resto', () {
      final comCodigo = Reserva.fromJson({
        ...reserva.toJson(),
        'codigoRetirada': '4821',
      });
      final json = comCodigo.semCodigo().toJson();
      expect(comCodigo.codigoRetirada, '4821');
      expect(json.containsKey('codigoRetirada'), isFalse);
      expect(json['id'], 7);
    });
  });

  group('RegrasDaRetirada', () {
    const regras = RegrasDaRetirada();
    final agora = DateTime.utc(2026, 9, 15, 14);

    test('RN21: prazo de 60 min quando a janela vai além', () {
      expect(
        regras.prazoFinal(
          agora: agora,
          janelaFim: agora.add(const Duration(hours: 3)),
        ),
        agora.add(const Duration(minutes: 60)),
      );
    });

    test('RN21: o prazo nunca passa do fim do horário de retirada', () {
      final fim = agora.add(const Duration(minutes: 20));
      expect(regras.prazoFinal(agora: agora, janelaFim: fim), fim);
    });

    test('vai e volta em JSON', () {
      final volta = RegrasDaRetirada.fromJson(
        const RegrasDaRetirada(prazo: Duration(minutes: 2)).toJson(),
      );
      expect(volta.prazo, const Duration(minutes: 2));
      expect(volta.suspensao, const Duration(hours: 48));
    });
  });

  group('SituacaoDaOng', () {
    SituacaoDaOng com(int desistencias, int ativas) => SituacaoDaOng(
      desistenciasRecentes: desistencias,
      regras: const RegrasDaRetirada(),
      ativas: [
        for (var i = 0; i < ativas; i++)
          Reserva(
            id: i,
            doacaoId: i,
            ongId: 1,
            status: StatusReserva.ativa,
            reservadoEm: DateTime.utc(2026),
            expiraEm: DateTime.utc(2026, 1, 2),
          ),
      ],
    );

    test('RN24: na 2ª desistência avisa que a próxima suspende', () {
      expect(com(1, 0).proximaDesistenciaSuspende, isFalse);
      expect(com(2, 0).proximaDesistenciaSuspende, isTrue);
    });

    test('RN25: duas retiradas em andamento atingem o limite', () {
      expect(com(0, 1).atingiuLimite, isFalse);
      expect(com(0, 2).atingiuLimite, isTrue);
    });

    test('vai e volta em JSON com as retiradas', () {
      final volta = SituacaoDaOng.fromJson(com(2, 1).toJson());
      expect(volta.ativas, hasLength(1));
      expect(volta.desistenciasRecentes, 2);
    });
  });

  group('RespostaAutenticacao', () {
    test('lê o JSON plano com token, usuario e perfil', () {
      final resposta = RespostaAutenticacao.fromJson({
        'token': 'abc.def.ghi',
        'usuario': {
          'id': 3,
          'nome': 'Ana',
          'email': 'ana@exemplo.com',
          'tipo': 'ong',
        },
        'perfil': {
          'usuarioId': 3,
          'nomeOrganizacao': 'ONG Mãos Amigas',
          'tipoDocumento': 'cnpj',
          'documento': '11222333000181',
          'verificacao': 'verificada',
          'latitude': -23.51,
          'longitude': -46.18,
          'buscaAtiva': true,
          'raioKm': 10,
        },
      });

      expect(resposta.token, 'abc.def.ghi');
      expect(resposta.conta.usuario.ehOng, isTrue);
      expect(resposta.conta.perfil.nomeOrganizacao, 'ONG Mãos Amigas');
      expect(resposta.conta.perfil.ehVerificada, isTrue);
    });
  });

  group('Perfil', () {
    test('ida e volta pelo JSON preserva os campos novos', () {
      final perfil = Perfil(
        usuarioId: 7,
        nomeOrganizacao: 'Feira do Zé',
        tipoDocumento: TipoDocumento.cpf,
        documento: '12345678909',
        tipoEstabelecimento: TipoEstabelecimento.feira,
        latitude: -23.5,
        longitude: -46.1,
        infoExtra: 'Feira de sábado',
        suspensaAte: DateTime.utc(2026, 11, 12, 17),
      );

      final copia = Perfil.fromJson(perfil.toJson());

      expect(copia.toJson(), perfil.toJson());
      expect(copia.verificacao, Verificacao.pendente); // padrão
      expect(copia.raioKm, Perfil.raioPadraoKm);
    });

    test('RN24: suspensa só enquanto suspensaAte está no futuro', () {
      final perfil = Perfil(
        usuarioId: 1,
        nomeOrganizacao: 'ONG',
        tipoDocumento: TipoDocumento.cnpj,
        documento: '11222333000181',
        latitude: 0,
        longitude: 0,
        suspensaAte: DateTime.utc(2026, 11, 12, 17),
      );

      expect(perfil.estaSuspensa(DateTime.utc(2026, 11, 12, 16)), isTrue);
      expect(perfil.estaSuspensa(DateTime.utc(2026, 11, 12, 18)), isFalse);
    });
  });

  group('InfoCnpj', () {
    InfoCnpj info({String situacao = 'ATIVA', int? natureza = 3999}) =>
        InfoCnpj(
          cnpj: '11222333000181',
          razaoSocial: 'ASSOCIACAO EXEMPLO',
          nomeFantasia: '',
          situacao: situacao,
          codigoNaturezaJuridica: natureza,
        );

    test('RN03: natureza jurídica 3xxx é entidade sem fins lucrativos', () {
      expect(info().semFinsLucrativos, isTrue);
      expect(info(natureza: 2062).semFinsLucrativos, isFalse);
      expect(info(natureza: null).semFinsLucrativos, isFalse);
    });

    test('RN03: só a situação ATIVA conta como ativa', () {
      expect(info().ativa, isTrue);
      expect(info(situacao: 'BAIXADA').ativa, isFalse);
    });

    test('sem nome fantasia, sugere a razão social', () {
      expect(info().nomeSugerido, 'ASSOCIACAO EXEMPLO');
    });
  });
}
