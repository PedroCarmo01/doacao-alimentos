import 'contas_de_exemplo.dart';
import 'gravador_de_exemplos.dart';

/// As 2 doações do seed (as MESMAS do modo Fake do app, em
/// `app/lib/data/fake/exemplos_fake.dart`):
///
/// 1. "Mantimentos não perecíveis" (Mercado Bom Preço): RESERVADA pela ONG
///    Mãos Amigas, retirada em andamento (código 4821) e com chat.
/// 2. "Pão francês do dia" (Padaria Pão Quente): DISPONÍVEL.
///
/// O Instituto Prato Cheio aceitou as duas mais cedo e deixou o prazo
/// acabar: são as 2 desistências dele (RN22–RN24). Por isso ele fica
/// bloqueado nas duas e não vê o pão francês na lista.
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

  Future<void> criar() async {
    final mantimentos = await _ex.doacao(
      doadorId: _contas.mercado,
      titulo: 'Mantimentos não perecíveis',
      descricao: 'Arroz, feijão, macarrão, farinha de milho, açúcar e óleo.',
      categoria: 'mercearia',
      quantidade: 120,
      unidade: 'kg',
      pesoKg: 120,
      conservacao: 'ambiente',
      validade: hoje.add(const Duration(days: 30)),
      inicio: agora.subtract(const Duration(hours: 3)),
      fim: agora.add(const Duration(hours: 5)),
      local: ContasDeExemplo.localMercado,
      endereco: 'Rua Principal, 100 - Centro',
      status: 'reservada',
      criadaEm: agora.subtract(const Duration(hours: 3)),
    );
    await _ex.foto(mantimentos, 'mantimentos.jpg');

    final paes = await _ex.doacao(
      doadorId: _contas.padaria,
      titulo: 'Pão francês do dia',
      descricao: 'Pães assados hoje, separados em 4 caixas.',
      categoria: 'padaria',
      quantidade: 4,
      unidade: 'caixas',
      pesoKg: 12,
      conservacao: 'ambiente',
      validade: hoje.add(const Duration(days: 1)),
      inicio: agora.subtract(const Duration(hours: 2)),
      fim: agora.add(const Duration(hours: 4)),
      local: ContasDeExemplo.localPadaria,
      endereco: 'Avenida das Flores, 250',
      status: 'disponivel',
      criadaEm: agora.subtract(const Duration(hours: 2)),
    );
    await _ex.foto(paes, 'paes.jpg');

    // As 2 desistências do Prato Cheio, antes de a Mãos Amigas aceitar.
    await _desistencia(mantimentos, const Duration(minutes: 150));
    await _desistencia(paes, const Duration(minutes: 105));
    await _retiradaEmAndamento(mantimentos);
  }

  /// O Prato Cheio aceitou há [tempo], deixou o prazo de 1 h acabar e
  /// ficou bloqueado para esta doação (RN22). Conta como desistência (RN24).
  Future<void> _desistencia(int doacao, Duration tempo) async {
    final aceitaEm = agora.subtract(tempo);
    final venceuEm = aceitaEm.add(const Duration(hours: 1));
    final reserva = await _ex.reserva(
      doacaoId: doacao,
      ongId: _contas.pratoCheio,
      status: 'expirada',
      codigo: '2468',
      reservadaEm: aceitaEm,
      expiraEm: venceuEm,
      encerradaEm: venceuEm,
      contaDesistencia: true,
    );
    await _ex.bloqueio(
      ongId: _contas.pratoCheio,
      doacaoId: doacao,
      em: venceuEm,
    );
    // As mensagens automáticas que o backend grava no aceite e no fim do
    // prazo.
    await _ex.mensagem(
      reservaId: reserva,
      autorId: null,
      texto: 'Instituto Prato Cheio aceitou a doação.',
      em: aceitaEm,
    );
    await _ex.mensagem(
      reservaId: reserva,
      autorId: null,
      texto: 'O prazo da retirada acabou.',
      em: venceuEm,
    );
  }

  /// Mãos Amigas está retirando os mantimentos agora (código 4821), com uma
  /// conversa curta no chat combinando a retirada.
  Future<void> _retiradaEmAndamento(int mantimentos) async {
    final aceitaEm = agora.subtract(const Duration(minutes: 10));
    final reserva = await _ex.reserva(
      doacaoId: mantimentos,
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
      autorId: _contas.mercado,
      texto: 'Olá! Separamos as caixas com os mantimentos no estoque.',
      em: aceitaEm.add(const Duration(minutes: 1)),
    );
    await _ex.mensagem(
      reservaId: reserva,
      autorId: _contas.maosAmigas,
      texto: 'Obrigado! Estou a caminho de carro, chego em uns 20 minutos.',
      em: aceitaEm.add(const Duration(minutes: 2)),
    );
    await _ex.mensagem(
      reservaId: reserva,
      autorId: _contas.mercado,
      texto: 'Combinado. Pode entrar pelo portão lateral e procurar o Carlos.',
      em: aceitaEm.add(const Duration(minutes: 3)),
      lida: false,
    );
  }
}
