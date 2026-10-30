import 'package:shared_models/shared_models.dart';

import 'contas_de_exemplo.dart';
import 'gravador_de_exemplos.dart';

/// As doações do seed: 5 disponíveis, 1 sendo retirada (com chat),
/// 2 concluídas e 3 que expiraram porque ONGs não buscaram.
///
/// Categoria, unidade, conservação e status são os valores dos ENUM do banco.
class DoacoesDeExemplo {
  DoacoesDeExemplo(
    this._ex,
    this._contas, {
    required this.agora,
    required this.hoje,
    required this.prazoReserva,
  });

  final GravadorDeExemplos _ex;
  final ContasDeExemplo _contas;
  final DateTime agora;
  final DateTime hoje;
  final Duration prazoReserva;

  /// Ids das doações concluídas (a Comunidade fala delas).
  final List<int> concluidas = [];

  Future<void> criar() async {
    await _criarDisponiveis();
    await _criarRetiradaEmAndamento();
    await _criarHistorico();
  }

  Future<void> _criarDisponiveis() async {
    await _disponivel(
      doador: _contas.mercado,
      titulo: 'Frutas e verduras do dia',
      categoria: 'hortifruti',
      quantidade: 5,
      unidade: 'caixas',
      pesoKg: 25,
      horas: 6,
      descricao: 'Retirar pela porta lateral, falar com o Carlos.',
    );
    await _disponivel(
      doador: _contas.mercado,
      titulo: 'Iogurtes perto do vencimento',
      categoria: 'laticinios',
      quantidade: 24,
      unidade: 'unidades',
      pesoKg: 4.8,
      horas: 8,
      conservacao: 'refrigerado',
    );
    await _disponivel(
      doador: _contas.mercado,
      titulo: 'Frios fatiados',
      categoria: 'carnesFrios',
      quantidade: 4,
      unidade: 'kg',
      pesoKg: 4,
      horas: 4,
      conservacao: 'refrigerado',
    );
    await _disponivel(
      doador: _contas.padaria,
      titulo: 'Marmitas do almoço',
      categoria: 'refeicoesProntas',
      quantidade: 20,
      unidade: 'unidades',
      pesoKg: 8,
      // Refeição pronta: retirada até 4 h depois do preparo.
      horas: 3,
      preparadoEm: agora.subtract(const Duration(minutes: 30)),
    );
    await _disponivel(
      doador: _contas.feirante,
      titulo: 'Verduras da feira',
      categoria: 'hortifruti',
      quantidade: 3,
      unidade: 'caixas',
      pesoKg: 15,
      horas: 5,
    );
  }

  Future<int> _disponivel({
    required int doador,
    required String titulo,
    required String categoria,
    required double quantidade,
    required String unidade,
    required double pesoKg,
    required int horas,
    String conservacao = 'ambiente',
    String? descricao,
    DateTime? preparadoEm,
  }) {
    return _ex.doacao(
      doadorId: doador,
      titulo: titulo,
      categoria: categoria,
      quantidade: quantidade,
      unidade: unidade,
      pesoKg: pesoKg,
      conservacao: conservacao,
      validade: hoje.add(const Duration(days: 1)),
      preparadoEm: preparadoEm,
      inicio: agora.subtract(const Duration(minutes: 30)),
      fim: agora.add(Duration(hours: horas)),
      local: _localDe(doador),
      status: 'disponivel',
      criadaEm: agora.subtract(const Duration(minutes: 30)),
      descricao: descricao,
    );
  }

  /// Mãos Amigas está retirando as cestas do mercado agora (código 4821),
  /// com uma conversa no chat da doação.
  Future<void> _criarRetiradaEmAndamento() async {
    final aceitaEm = agora.subtract(const Duration(minutes: 10));
    final cestas = await _ex.doacao(
      doadorId: _contas.mercado,
      titulo: 'Cestas de mercearia',
      categoria: 'mercearia',
      quantidade: 10,
      unidade: 'caixas',
      pesoKg: 40,
      conservacao: 'ambiente',
      validade: hoje.add(const Duration(days: 30)),
      inicio: agora.subtract(const Duration(minutes: 30)),
      fim: agora.add(const Duration(hours: 5)),
      local: ContasDeExemplo.localMercado,
      status: 'reservada',
      criadaEm: agora.subtract(const Duration(minutes: 30)),
    );
    final reserva = await _ex.reserva(
      doacaoId: cestas,
      ongId: _contas.maosAmigas,
      status: 'ativa',
      codigo: '4821',
      reservadaEm: aceitaEm,
      expiraEm: aceitaEm.add(prazoReserva),
    );
    await _ex.mensagem(
      reservaId: reserva,
      autorId: null,
      texto: 'ONG Mãos Amigas aceitou a doação.',
      em: aceitaEm,
    );
    await _ex.mensagem(
      reservaId: reserva,
      autorId: _contas.maosAmigas,
      texto: 'Estou a caminho',
      em: aceitaEm.add(const Duration(minutes: 2)),
    );
    await _ex.mensagem(
      reservaId: reserva,
      autorId: _contas.mercado,
      texto: 'Pode entrar pelo portão lateral',
      em: aceitaEm.add(const Duration(minutes: 3)),
      lida: false,
    );
  }

  /// 2 doações concluídas e 3 expiradas, todas do mercado.
  Future<void> _criarHistorico() async {
    final arroz = await _antiga('Arroz e feijão', 6, 'concluida');
    final enlatados = await _antiga('Enlatados variados', 3, 'concluida');
    await _retiradaConcluida(arroz, _contas.maosAmigas, 6);
    await _retiradaConcluida(enlatados, _contas.pratoCheio, 3);
    concluidas.addAll([arroz, enlatados]);

    // RN22–RN24: Prato Cheio deixou 2 prazos acabarem; Casa Esperança, 3.
    const diasAtras = [12, 8, 4];
    final titulos = ['Macarrão e molho', 'Biscoitos', 'Farinha e açúcar'];
    for (var i = 0; i < titulos.length; i++) {
      final doacao = await _antiga(titulos[i], diasAtras[i], 'expirada');
      if (i < 2) await _desistencia(doacao, _contas.pratoCheio, diasAtras[i]);
      await _desistencia(doacao, _contas.suspensa, diasAtras[i]);
    }
  }

  Future<int> _antiga(String titulo, int diasAtras, String status) {
    final dia = agora.subtract(Duration(days: diasAtras));
    return _ex.doacao(
      doadorId: _contas.mercado,
      titulo: titulo,
      categoria: 'mercearia',
      quantidade: 30,
      unidade: 'kg',
      pesoKg: 30,
      conservacao: 'ambiente',
      validade: hoje,
      inicio: dia,
      fim: dia.add(const Duration(hours: 6)),
      local: ContasDeExemplo.localMercado,
      status: status,
      criadaEm: dia,
    );
  }

  Future<void> _retiradaConcluida(int doacao, int ong, int diasAtras) async {
    final aceitaEm = agora.subtract(Duration(days: diasAtras));
    await _ex.reserva(
      doacaoId: doacao,
      ongId: ong,
      status: 'concluida',
      codigo: '1357',
      reservadaEm: aceitaEm,
      expiraEm: aceitaEm.add(const Duration(hours: 1)),
      encerradaEm: aceitaEm.add(const Duration(minutes: 40)),
    );
  }

  /// A ONG aceitou, deixou o prazo acabar e ficou bloqueada para a doação.
  Future<void> _desistencia(int doacao, int ong, int diasAtras) async {
    final aceitaEm = agora.subtract(Duration(days: diasAtras));
    final venceuEm = aceitaEm.add(const Duration(hours: 1));
    await _ex.reserva(
      doacaoId: doacao,
      ongId: ong,
      status: 'expirada',
      codigo: '2468',
      reservadaEm: aceitaEm,
      expiraEm: venceuEm,
      encerradaEm: venceuEm,
      contaDesistencia: true,
    );
    await _ex.bloqueio(ongId: ong, doacaoId: doacao, em: venceuEm);
  }

  Coordenadas _localDe(int doador) {
    if (doador == _contas.padaria) return ContasDeExemplo.localPadaria;
    if (doador == _contas.feirante) return ContasDeExemplo.localFeirante;
    return ContasDeExemplo.localMercado;
  }
}
