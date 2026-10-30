import 'package:shared_models/shared_models.dart';

/// Conta + hash da senha. Só existe DENTRO do backend: o hash nunca vai
/// para o app (por isso não é um modelo do shared_models).
class UsuarioComSenha {
  const UsuarioComSenha({required this.conta, required this.senhaHash});

  final Conta conta;
  final String senhaHash;
}

/// CONTRATO de acesso aos usuários. O AuthService depende desta interface,
/// não do MySQL: nos testes usamos uma versão em memória.
abstract interface class UsuarioRepository {
  /// RN04: e-mail único.
  Future<bool> emailEmUso(String email);

  /// RN04: CNPJ/CPF único (só números).
  Future<bool> documentoEmUso(String documento);

  /// Grava usuário e perfil juntos (transação) e devolve a conta criada.
  ///
  /// [verificacao] e [razaoSocial] vêm da consulta à BrasilAPI (RN03).
  Future<Conta> criar(
    DadosCadastro dados, {
    required String senhaHash,
    required DateTime criadoEm,
    required Verificacao verificacao,
    String? razaoSocial,
  });

  Future<UsuarioComSenha?> buscarPorEmail(String email);

  Future<Conta?> buscarConta(int usuarioId);
}
