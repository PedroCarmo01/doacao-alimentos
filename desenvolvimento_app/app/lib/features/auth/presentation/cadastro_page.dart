import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/localizacao/localizacao_service.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Cadastro (doador ou ONG) — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 1. Passo a passo: trilha/17-app-autenticacao.md
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class CadastroPage extends StatelessWidget {
  const CadastroPage({
    super.key,
    required this.tipo,
    required this.auth,
    required this.sessao,
    required this.localizacao,
  });

  final TipoUsuario tipo;
  final AuthRepository auth;
  final Sessao sessao;
  final LocalizacaoService localizacao;

  @override
  Widget build(BuildContext context) => EmConstrucao(
        titulo: 'Cadastro de ${tipo.rotulo}',
        responsavel: 'Pessoa 1',
        etapa: 'trilha/17-app-autenticacao.md',
      );
}
