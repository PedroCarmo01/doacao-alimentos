import 'package:shared_models/shared_models.dart';

import 'chat_fake.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';

/// As doações de exemplo do modo Fake: as MESMAS do seed do backend
/// (`backend/tool/seed/doacoes_de_exemplo.dart`), com as fotos de exemplo
/// guardadas em `assets/exemplos/`.
class ExemplosFake {
  ExemplosFake(this._doacoes, this._contas, this._chat, {required this.agora});

  final DoacoesFake _doacoes;
  final ContasFake _contas;
  final ChatFake _chat;
  final DateTime agora;

  late final _mercado = _contas.porEmail('mercado@exemplo.com');
  late final _padaria = _contas.porEmail('padaria@exemplo.com');
  late final _feirante = _contas.porEmail('feirante@exemplo.com');
  late final _maosAmigas = _contas.porEmail('maosamigas@exemplo.com');
  late final _pratoCheio = _contas.porEmail('pratocheio@exemplo.com');
  late final _suspensa = _contas.porEmail('suspensa@exemplo.com');

  void criar() {
    _disponivel(
      _mercado,
      'Frutas e verduras do dia',
      CategoriaAlimento.hortifruti,
      5,
      Unidade.caixas,
      25,
      6,
      foto: 'frutas.jpg',
      descricao: 'Retirar pela porta lateral, falar com o Carlos.',
    );
    _disponivel(
      _mercado,
      'Iogurtes perto do vencimento',
      CategoriaAlimento.laticinios,
      24,
      Unidade.unidades,
      4.8,
      8,
      conservacao: Conservacao.refrigerado,
      foto: 'iogurtes.jpg',
    );
    _disponivel(
      _mercado,
      'Frios fatiados',
      CategoriaAlimento.carnesFrios,
      4,
      Unidade.kg,
      4,
      4,
      conservacao: Conservacao.refrigerado,
      foto: 'frios.jpg',
    );
    _disponivel(
      _padaria,
      'Marmitas do almoço',
      CategoriaAlimento.refeicoesProntas,
      20,
      Unidade.unidades,
      8,
      3,
      foto: 'marmitas.jpg',
      preparadoEm: agora.subtract(const Duration(minutes: 30)),
    );
    _disponivel(
      _feirante,
      'Verduras da feira',
      CategoriaAlimento.hortifruti,
      3,
      Unidade.caixas,
      15,
      5,
    );
    _retiradaEmAndamento();
    _historico();
  }

  Doacao _disponivel(
    Conta doador,
    String titulo,
    CategoriaAlimento categoria,
    double quantidade,
    Unidade unidade,
    double pesoKg,
    int horas, {
    Conservacao conservacao = Conservacao.ambiente,
    String? foto,
    String? descricao,
    DateTime? preparadoEm,
    DateTime? inicio,
    StatusDoacao status = StatusDoacao.disponivel,
  }) {
    final comeco = inicio ?? agora.subtract(const Duration(minutes: 30));
    final doacao = Doacao(
      id: _doacoes.novoId(),
      doadorId: doador.usuario.id,
      titulo: titulo,
      descricao: descricao,
      categoria: categoria,
      quantidade: quantidade,
      unidade: unidade,
      pesoKg: pesoKg,
      conservacao: conservacao,
      validade: Calendario.somenteData(agora.add(const Duration(days: 1))),
      preparadoEm: preparadoEm,
      janelaInicio: comeco,
      janelaFim: comeco.add(Duration(hours: horas)),
      endereco: doador.perfil.endereco,
      latitude: doador.perfil.latitude,
      longitude: doador.perfil.longitude,
      status: status,
      criadoEm: comeco,
      fotos: foto == null ? const [] : ['assets/exemplos/$foto'],
    );
    _doacoes.salvar(doacao);
    return doacao;
  }

  /// Mãos Amigas está retirando as cestas do mercado (código 4821).
  void _retiradaEmAndamento() {
    final cestas = _disponivel(
      _mercado,
      'Cestas de mercearia',
      CategoriaAlimento.mercearia,
      10,
      Unidade.caixas,
      40,
      5,
      status: StatusDoacao.reservada,
    );
    final aceitaEm = agora.subtract(const Duration(minutes: 10));
    _doacoes.reservas.add(
      Reserva(
        id: _doacoes.novoId(),
        doacaoId: cestas.id,
        ongId: _maosAmigas.usuario.id,
        status: StatusReserva.ativa,
        reservadoEm: aceitaEm,
        // 60 min, como no seed (o prazo curto do Fake vale para as novas).
        expiraEm: aceitaEm.add(const Duration(hours: 1)),
        codigoRetirada: '4821',
        tituloDoacao: cestas.titulo,
        nomeOng: _maosAmigas.perfil.nomeOrganizacao,
      ),
    );
    _doacoes.salvar(cestas);
    // A conversa de exemplo, como no seed.
    final reserva = _doacoes.reservas.last;
    _chat.doSistema(
      reserva.id,
      'ONG Mãos Amigas aceitou a doação.',
      em: aceitaEm,
    );
    _chat.deExemplo(
      reserva.id,
      _maosAmigas.usuario.id,
      'Estou a caminho',
      aceitaEm.add(const Duration(minutes: 2)),
    );
    _chat.deExemplo(
      reserva.id,
      _mercado.usuario.id,
      'Pode entrar pelo portão lateral',
      aceitaEm.add(const Duration(minutes: 3)),
    );
  }

  /// 2 concluídas e 3 expiradas (desistências do Prato Cheio e da Casa
  /// Esperança, RN22–RN24).
  void _historico() {
    Doacao antiga(String titulo, int diasAtras, StatusDoacao status) =>
        _disponivel(
          _mercado,
          titulo,
          CategoriaAlimento.mercearia,
          30,
          Unidade.kg,
          30,
          6,
          inicio: agora.subtract(Duration(days: diasAtras)),
          status: status,
        );

    _encerrada(
      antiga('Arroz e feijão', 6, StatusDoacao.concluida),
      _maosAmigas,
      StatusReserva.concluida,
    );
    _encerrada(
      antiga('Enlatados variados', 3, StatusDoacao.concluida),
      _pratoCheio,
      StatusReserva.concluida,
    );
    final expiradas = [
      antiga('Macarrão e molho', 12, StatusDoacao.expirada),
      antiga('Biscoitos', 8, StatusDoacao.expirada),
      antiga('Farinha e açúcar', 4, StatusDoacao.expirada),
    ];
    for (final doacao in expiradas) {
      if (doacao != expiradas.last) {
        _encerrada(doacao, _pratoCheio, StatusReserva.expirada);
      }
      _encerrada(doacao, _suspensa, StatusReserva.expirada);
    }
  }

  void _encerrada(Doacao doacao, Conta ong, StatusReserva status) {
    final aceitaEm = doacao.janelaInicio;
    _doacoes.reservas.add(
      Reserva(
        id: _doacoes.novoId(),
        doacaoId: doacao.id,
        ongId: ong.usuario.id,
        status: status,
        reservadoEm: aceitaEm,
        expiraEm: aceitaEm.add(const Duration(hours: 1)),
        encerradaEm: aceitaEm.add(const Duration(minutes: 40)),
        contouDesistencia: status == StatusReserva.expirada, // RN24
        tituloDoacao: doacao.titulo,
        nomeOng: ong.perfil.nomeOrganizacao,
      ),
    );
    if (status == StatusReserva.expirada) {
      _doacoes.bloqueios.add('${ong.usuario.id}-${doacao.id}'); // RN22
    }
  }
}
