import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/sessao/sessao.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../shared/widgets/em_construcao.dart';

/// TELA: Login (doador ou ONG) — PLACEHOLDER do Sprint 0.
///
/// Responsável: Pessoa 1. Passo a passo: trilha/17-app-autenticacao.md
/// ATENÇÃO: mantenha o CONSTRUTOR. Ele é o contrato usado pelo AppRouter.
class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    required this.tipo,
    required this.auth,
    required this.sessao,
  });

  final TipoUsuario tipo;
  final AuthRepository auth;
  final Sessao sessao;

  @override
  Widget build(BuildContext context) => EmConstrucao(
    titulo: 'Entrar como ${tipo.rotulo}',
    responsavel: 'Pessoa 1',
    etapa: 'trilha/17-app-autenticacao.md',
  );
}
