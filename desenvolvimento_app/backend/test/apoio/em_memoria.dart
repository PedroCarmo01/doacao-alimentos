import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/auth/usuario_repository.dart';
import 'package:summit_backend/core/seguranca/senha_service.dart';
import 'package:summit_backend/perfil/perfil_repository.dart';

/// Versões em memória (sem MySQL) usadas pelos testes dos Services.
///
/// POLIMORFISMO: implementam as MESMAS interfaces das classes MySQL, então
/// o Service não percebe a diferença.

/// Senha "hash" = senha invertida. Rápido e suficiente para testar regras
/// (o bcrypt real é lento de propósito e deixaria os testes demorados).
class SenhaServiceFake implements SenhaService {
  const SenhaServiceFake();

  @override
  String gerarHash(String senha) => senha.split('').reversed.join();

  @override
  bool confere(String senha, String hash) => gerarHash(senha) == hash;
}

/// Guarda contas numa lista e também faz o papel do [PerfilRepository]
/// (as duas tabelas, `usuarios` e `perfis`, ficam juntas aqui).
class ContasEmMemoria implements UsuarioRepository, PerfilRepository {
  final List<UsuarioComSenha> registros = [];

  Conta? conta(int id) =>
      registros.where((r) => r.conta.usuario.id == id).firstOrNull?.conta;

  @override
  Future<bool> emailEmUso(String email) async =>
      registros.any((r) => r.conta.usuario.email == email);

  @override
  Future<bool> documentoEmUso(String documento) async =>
      registros.any((r) => r.conta.perfil.documento == documento);

  @override
  Future<Conta> criar(
    DadosCadastro dados, {
    required String senhaHash,
    required DateTime criadoEm,
    required Verificacao verificacao,
    String? razaoSocial,
  }) async {
    final id = registros.length + 1;
    final nova = Conta(
      usuario: Usuario(
        id: id,
        nome: dados.nome,
        email: dados.email,
        tipo: dados.tipo,
      ),
      perfil: Perfil(
        usuarioId: id,
        nomeOrganizacao: dados.nomeOrganizacao,
        tipoDocumento: dados.tipoDocumento,
        documento: dados.documento,
        verificacao: verificacao,
        razaoSocial: razaoSocial,
        tipoEstabelecimento: dados.tipoEstabelecimento,
        telefone: dados.telefone,
        latitude: dados.latitude,
        longitude: dados.longitude,
        transporte: dados.transporte,
      ),
    );
    registros.add(UsuarioComSenha(conta: nova, senhaHash: senhaHash));
    return nova;
  }

  @override
  Future<UsuarioComSenha?> buscarPorEmail(String email) async =>
      registros.where((r) => r.conta.usuario.email == email).firstOrNull;

  @override
  Future<Conta?> buscarConta(int usuarioId) async => conta(usuarioId);

  @override
  Future<void> atualizar(int usuarioId, DadosPerfil dados) async {
    final indice = registros.indexWhere((r) => r.conta.usuario.id == usuarioId);
    final antigo = registros[indice];
    final perfil = antigo.conta.perfil;
    registros[indice] = UsuarioComSenha(
      senhaHash: antigo.senhaHash,
      conta: Conta(
        usuario: antigo.conta.usuario.copyWith(nome: dados.nome),
        perfil: Perfil(
          usuarioId: usuarioId,
          nomeOrganizacao: dados.nomeOrganizacao,
          tipoDocumento: perfil.tipoDocumento,
          documento: perfil.documento,
          verificacao: perfil.verificacao,
          telefone: dados.telefone,
          latitude: dados.latitude,
          longitude: dados.longitude,
          familiasAtendidas: dados.familiasAtendidas,
          transporte: dados.transporte,
          buscaAtiva: dados.buscaAtiva,
          raioKm: dados.raioKm,
        ),
      ),
    );
  }

  @override
  Future<List<PerfilPendente>> pendentesDeVerificacao({
    required int limite,
  }) async => [
    for (final r in registros)
      if (!r.conta.perfil.ehVerificada &&
          r.conta.perfil.tipoDocumento == TipoDocumento.cnpj)
        PerfilPendente(
          usuarioId: r.conta.usuario.id,
          tipo: r.conta.usuario.tipo,
          cnpj: r.conta.perfil.documento,
        ),
  ].take(limite).toList();

  /// RN24: usado pelo `ReservasEmMemoria.suspender`.
  void suspender(int usuarioId, DateTime ate) =>
      alterarPerfil(usuarioId, {'suspensaAte': ate.toUtc().toIso8601String()});

  /// Troca campos do perfil (pelos nomes do JSON), para montar cenários.
  void alterarPerfil(int usuarioId, Map<String, dynamic> campos) {
    final indice = registros.indexWhere((r) => r.conta.usuario.id == usuarioId);
    final antigo = registros[indice];
    final json = {...antigo.conta.perfil.toJson(), ...campos};
    registros[indice] = UsuarioComSenha(
      senhaHash: antigo.senhaHash,
      conta: Conta(
        usuario: antigo.conta.usuario,
        perfil: Perfil.fromJson(json),
      ),
    );
  }

  /// Ids marcados como verificados pelo job (os testes conferem).
  final List<int> verificados = [];

  @override
  Future<void> marcarVerificada(
    int usuarioId, {
    required String razaoSocial,
  }) async => verificados.add(usuarioId);
}

/// Situações da Receita usadas nos testes (CNPJs fictícios, dígitos certos).
abstract final class CnpjsDeTeste {
  /// Associação ATIVA (natureza 3999): pode ser ONG.
  static final associacao = ValidadorDocumento.completarCnpj('904600010001');

  /// Empresa ATIVA (natureza 2062): pode ser doador, não ONG.
  static final empresa = ValidadorDocumento.completarCnpj('904500010001');

  /// Empresa BAIXADA: ninguém pode usar.
  static final baixada = ValidadorDocumento.completarCnpj('904500020001');

  /// Não existe na Receita.
  static final inexistente = ValidadorDocumento.completarCnpj('904500090001');

  /// Válido, mas a "BrasilAPI" está fora do ar para ele.
  static final semResposta = ValidadorDocumento.completarCnpj('904600090001');

  static InfoCnpj info(
    String cnpj, {
    String situacao = 'ATIVA',
    int? natureza,
  }) => InfoCnpj(
    cnpj: cnpj,
    razaoSocial: 'RAZAO SOCIAL $cnpj',
    situacao: situacao,
    codigoNaturezaJuridica: natureza,
  );

  static List<InfoCnpj> get receita => [
    info(associacao, natureza: 3999),
    info(empresa, natureza: 2062),
    info(baixada, situacao: 'BAIXADA', natureza: 2062),
  ];
}
