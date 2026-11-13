import 'package:shared_models/shared_models.dart';

import 'chat_fake.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';

/// As doações de exemplo do modo Fake: as MESMAS 2 do seed do backend
/// (`backend/tool/seed/doacoes_de_exemplo.dart`), com as fotos de exemplo
/// guardadas em `assets/exemplos/`.
///
/// 1. "Mantimentos não perecíveis" (Mercado Bom Preço): RESERVADA pela ONG
///    Mãos Amigas, retirada em andamento (código 4821) e com chat.
/// 2. "Pão francês do dia" (Padaria Pão Quente): DISPONÍVEL.
///
/// O Instituto Prato Cheio aceitou as duas mais cedo e deixou o prazo
/// acabar: são as 2 desistências dele (RN22–RN24). Por isso ele fica
/// bloqueado nas duas e não vê o pão francês na lista.
class ExemplosFake {
  ExemplosFake(this._doacoes, this._contas, this._chat, {required this.agora});

  final DoacoesFake _doacoes;
  final ContasFake _contas;
  final ChatFake _chat;
  final DateTime agora;

  late final _mercado = _contas.porEmail('mercado@exemplo.com');
  late final _padaria = _contas.porEmail('padaria@exemplo.com');
  late final _maosAmigas = _contas.porEmail('maosamigas@exemplo.com');
  late final _pratoCheio = _contas.porEmail('pratocheio@exemplo.com');

  void criar() {
    final mantimentos = _doacao(
      _mercado,
      'Mantimentos não perecíveis',
      CategoriaAlimento.mercearia,
      120,
      Unidade.kg,
      120,
      descricao: 'Arroz, feijão, macarrão, farinha de milho, açúcar e óleo.',
      foto: 'mantimentos.jpg',
      inicio: agora.subtract(const Duration(hours: 3)),
      fim: agora.add(const Duration(hours: 5)),
      validade: agora.add(const Duration(days: 30)),
      status: StatusDoacao.reservada,
    );
    final paes = _doacao(
      _padaria,
      'Pão francês do dia',
      CategoriaAlimento.padaria,
      4,
      Unidade.caixas,
      12,
      descricao: 'Pães assados hoje, separados em 4 caixas.',
      foto: 'paes.jpg',
      inicio: agora.subtract(const Duration(hours: 2)),
      fim: agora.add(const Duration(hours: 4)),
      validade: agora.add(const Duration(days: 1)),
    );
    // As 2 desistências do Prato Cheio, antes de a Mãos Amigas aceitar.
    _desistencia(mantimentos, agora.subtract(const Duration(minutes: 150)));
    _desistencia(paes, agora.subtract(const Duration(minutes: 105)));
    _retiradaEmAndamento(mantimentos);
  }

  Doacao _doacao(
    Conta doador,
    String titulo,
    CategoriaAlimento categoria,
    double quantidade,
    Unidade unidade,
    double pesoKg, {
    required String descricao,
    required String foto,
    required DateTime inicio,
    required DateTime fim,
    required DateTime validade,
    StatusDoacao status = StatusDoacao.disponivel,
  }) {
    final doacao = Doacao(
      id: _doacoes.novoId(),
      doadorId: doador.usuario.id,
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      quantidade: quantidade,
      unidade: unidade,
      pesoKg: pesoKg,
      conservacao: Conservacao.ambiente,
      validade: Calendario.somenteData(validade),
      janelaInicio: inicio,
      janelaFim: fim,
      endereco: doador.perfil.endereco,
      latitude: doador.perfil.latitude,
      longitude: doador.perfil.longitude,
      status: status,
      criadoEm: inicio,
      fotos: ['assets/exemplos/$foto'],
    );
    _doacoes.salvar(doacao);
    return doacao;
  }

  /// O Prato Cheio aceitou, deixou o prazo de 1 h acabar e ficou bloqueado
  /// para esta doação (RN22). Conta como desistência (RN24).
  void _desistencia(Doacao doacao, DateTime aceitaEm) {
    final venceuEm = aceitaEm.add(const Duration(hours: 1));
    _doacoes.reservas.add(
      Reserva(
        id: _doacoes.novoId(),
        doacaoId: doacao.id,
        ongId: _pratoCheio.usuario.id,
        status: StatusReserva.expirada,
        reservadoEm: aceitaEm,
        expiraEm: venceuEm,
        encerradaEm: venceuEm,
        contouDesistencia: true,
        tituloDoacao: doacao.titulo,
        nomeOng: _pratoCheio.perfil.nomeOrganizacao,
      ),
    );
    _doacoes.bloqueios.add('${_pratoCheio.usuario.id}-${doacao.id}');
    // As mensagens automáticas que o app grava no aceite e no fim do prazo.
    final reserva = _doacoes.reservas.last;
    _chat.doSistema(
      reserva.id,
      'Instituto Prato Cheio aceitou a doação.',
      em: aceitaEm,
    );
    _chat.doSistema(reserva.id, 'O prazo da retirada acabou.', em: venceuEm);
  }

  /// Mãos Amigas está retirando os mantimentos (código 4821), com uma
  /// conversa curta no chat combinando a retirada.
  void _retiradaEmAndamento(Doacao mantimentos) {
    final aceitaEm = agora.subtract(const Duration(minutes: 10));
    final reserva = Reserva(
      id: _doacoes.novoId(),
      doacaoId: mantimentos.id,
      ongId: _maosAmigas.usuario.id,
      status: StatusReserva.ativa,
      reservadoEm: aceitaEm,
      // 60 min, como no seed (o prazo curto do Fake vale para as novas).
      expiraEm: aceitaEm.add(const Duration(hours: 1)),
      codigoRetirada: '4821',
      tituloDoacao: mantimentos.titulo,
      nomeOng: _maosAmigas.perfil.nomeOrganizacao,
    );
    _doacoes.reservas.add(reserva);
    // Salva de novo para a doação mostrar a ONG e o prazo da reserva.
    _doacoes.salvar(mantimentos);

    // A conversa de exemplo, igual à do seed.
    final mercado = _mercado.usuario.id;
    final ong = _maosAmigas.usuario.id;
    _chat.doSistema(
      reserva.id,
      'ONG Mãos Amigas aceitou a doação.',
      em: aceitaEm,
    );
    _chat.deExemplo(
      reserva.id,
      mercado,
      'Olá! Separamos as caixas com os mantimentos no estoque.',
      aceitaEm.add(const Duration(minutes: 1)),
    );
    _chat.deExemplo(
      reserva.id,
      ong,
      'Obrigado! Estou a caminho de carro, chego em uns 20 minutos.',
      aceitaEm.add(const Duration(minutes: 2)),
    );
    _chat.deExemplo(
      reserva.id,
      mercado,
      'Combinado. Pode entrar pelo portão lateral e procurar o Carlos.',
      aceitaEm.add(const Duration(minutes: 3)),
      lida: false, // a ONG ainda não leu: aparece o número vermelho
    );
  }
}
