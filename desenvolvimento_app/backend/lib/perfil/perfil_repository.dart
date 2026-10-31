import 'package:shared_models/shared_models.dart';

/// Um perfil cujo CNPJ ainda não foi conferido na BrasilAPI (RN03).
class PerfilPendente {
  const PerfilPendente({
    required this.usuarioId,
    required this.tipo,
    required this.cnpj,
  });

  final int usuarioId;
  final TipoUsuario tipo;
  final String cnpj;
}

/// CONTRATO de acesso à tabela `perfis` (edição e verificação).
///
/// O `PerfilService` e o `DocumentoService` dependem desta interface, não
/// do MySQL: nos testes usamos uma versão em memória.
abstract interface class PerfilRepository {
  /// Grava os dados editáveis do perfil e o nome do responsável.
  Future<void> atualizar(int usuarioId, DadosPerfil dados);

  /// T50: quais avisos a pessoa quer receber.
  Future<void> atualizarAvisos(int usuarioId, PreferenciasDeAviso avisos);

  /// Perfis com CNPJ e "verificação pendente", no máximo [limite].
  Future<List<PerfilPendente>> pendentesDeVerificacao({required int limite});

  /// RN03: marca o perfil como verificado e guarda a razão social oficial.
  Future<void> marcarVerificada(int usuarioId, {required String razaoSocial});
}
