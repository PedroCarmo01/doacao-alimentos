import 'package:shared_models/shared_models.dart';

import 'gravador_de_exemplos.dart';

/// Os 7 usuários do seed (a mesma lista de usuários de teste do README).
///
/// Os CNPJs e o CPF são FICTÍCIOS: os 2 últimos dígitos são calculados pelo
/// ValidadorDocumento, então passam na conferência (RN02). O BancoFake do
/// app usa os mesmos números.
class ContasDeExemplo {
  int mercado = 0;
  int padaria = 0;
  int feirante = 0;
  int maosAmigas = 0;
  int pratoCheio = 0;
  int suspensa = 0;

  static const localMercado = Coordenadas(-23.5229, -46.1880);
  static const localPadaria = Coordenadas(-23.5262, -46.1932);
  static const localFeirante = Coordenadas(-23.5205, -46.1902);

  /// Cria as contas e devolve os ids, para ligar doações e publicações.
  static Future<ContasDeExemplo> criar(
    GravadorDeExemplos ex,
    DateTime agora,
  ) async {
    final criadaEm = agora.subtract(const Duration(days: 60));
    final contas = ContasDeExemplo();
    await contas._criarDoadores(ex, criadaEm);
    await contas._criarOngs(ex, agora, criadaEm);
    return contas;
  }

  Future<void> _criarDoadores(GravadorDeExemplos ex, DateTime criadaEm) async {
    mercado = await ex.conta(
      tipo: TipoUsuario.doador,
      estabelecimento: TipoEstabelecimento.supermercado,
      responsavel: 'Gerente do Mercado',
      email: 'mercado@exemplo.com',
      organizacao: 'Mercado Bom Preço',
      razaoSocial: 'MERCADO BOM PRECO LTDA (FICTICIO)',
      documento: ValidadorDocumento.completarCnpj('904500010001'),
      endereco: 'Rua Principal, 100 - Centro',
      local: localMercado,
      criadaEm: criadaEm,
    );
    padaria = await ex.conta(
      tipo: TipoUsuario.doador,
      estabelecimento: TipoEstabelecimento.padaria,
      responsavel: 'Dono da Padaria',
      email: 'padaria@exemplo.com',
      organizacao: 'Padaria Pão Quente',
      razaoSocial: 'PADARIA PAO QUENTE LTDA (FICTICIO)',
      documento: ValidadorDocumento.completarCnpj('904500020001'),
      endereco: 'Avenida das Flores, 250',
      local: localPadaria,
      criadaEm: criadaEm,
    );
    feirante = await ex.conta(
      tipo: TipoUsuario.doador,
      estabelecimento: TipoEstabelecimento.feira,
      responsavel: 'Seu Zé da Feira',
      email: 'feirante@exemplo.com',
      organizacao: 'Banca do Zé',
      // CPF não tem consulta pública: fica "pendente" (ver RN03).
      documento: ValidadorDocumento.completarCpf('904500030'),
      verificacao: Verificacao.pendente,
      endereco: 'Feira do Mercadão, banca 12',
      infoExtra: 'Feira do Mercadão — terças e sábados',
      local: localFeirante,
      criadaEm: criadaEm,
    );
  }

  Future<void> _criarOngs(
    GravadorDeExemplos ex,
    DateTime agora,
    DateTime criadaEm,
  ) async {
    maosAmigas = await ex.conta(
      tipo: TipoUsuario.ong,
      responsavel: 'Coordenação Mãos Amigas',
      email: 'maosamigas@exemplo.com',
      organizacao: 'ONG Mãos Amigas',
      razaoSocial: 'ASSOCIACAO MAOS AMIGAS (FICTICIO)',
      documento: ValidadorDocumento.completarCnpj('904600010001'),
      endereco: 'Rua da Solidariedade, 45',
      local: const Coordenadas(-23.5180, -46.1850),
      familias: 120,
      transporte: Transporte.carro,
      infoExtra: 'Retiramos de segunda a sábado, das 9h às 18h',
      criadaEm: criadaEm,
    );
    pratoCheio = await ex.conta(
      tipo: TipoUsuario.ong,
      responsavel: 'Coordenação Prato Cheio',
      email: 'pratocheio@exemplo.com',
      organizacao: 'Instituto Prato Cheio',
      razaoSocial: 'INSTITUTO PRATO CHEIO (FICTICIO)',
      documento: ValidadorDocumento.completarCnpj('904600020001'),
      endereco: 'Travessa do Bem, 12',
      local: const Coordenadas(-23.5400, -46.2100),
      familias: 60,
      transporte: Transporte.van,
      criadaEm: criadaEm,
    );
    suspensa = await ex.conta(
      tipo: TipoUsuario.ong,
      responsavel: 'Coordenação Esperança',
      email: 'suspensa@exemplo.com',
      organizacao: 'Casa Esperança',
      razaoSocial: 'CASA ESPERANCA (FICTICIO)',
      documento: ValidadorDocumento.completarCnpj('904600030001'),
      endereco: 'Rua das Acácias, 300',
      local: const Coordenadas(-23.5300, -46.1950),
      transporte: Transporte.aPe,
      // RN24: suspensa por 48 h; faltam 30 h.
      suspensaAte: agora.add(const Duration(hours: 30)),
      criadaEm: criadaEm,
    );
    await ex.conta(
      tipo: TipoUsuario.ong,
      responsavel: 'Coordenação Distante',
      email: 'distante@exemplo.com',
      organizacao: 'Associação Distante',
      razaoSocial: 'ASSOCIACAO DISTANTE (FICTICIO)',
      documento: ValidadorDocumento.completarCnpj('904600040001'),
      endereco: 'Praça da Sé - São Paulo',
      local: const Coordenadas(-23.5505, -46.6333),
      criadaEm: criadaEm,
    );
  }
}
