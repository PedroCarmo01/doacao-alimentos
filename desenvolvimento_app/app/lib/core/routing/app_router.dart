import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../features/auth/presentation/cadastro_page.dart';
import '../../features/auth/presentation/escolha_perfil_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/doador/presentation/detalhe_doacao_doador_page.dart';
import '../../features/doador/presentation/home_doador_page.dart';
import '../../features/doador/presentation/nova_doacao_page.dart';
import '../../features/mapa/presentation/mapa_page.dart';
import '../../features/ong/presentation/detalhe_doacao_ong_page.dart';
import '../../features/ong/presentation/home_ong_page.dart';
import '../../features/ong/presentation/minhas_reservas_page.dart';
import '../dependencias.dart';
import 'app_routes.dart';

/// Cria a tela de cada rota e entrega a ela as dependências de que precisa.
///
/// Os CONSTRUTORES das páginas são o "contrato" entre a fundação e cada
/// pessoa: quem implementa uma tela troca o conteúdo do arquivo, mas mantém o
/// construtor. Assim ninguém precisa editar este arquivo (evita conflitos).
///
/// Arquivo de FUNDAÇÃO: altere só em PR combinado com o grupo.
class AppRouter {
  AppRouter(this._dependencias);

  final Dependencias _dependencias;

  static const _rotasPublicas = {
    AppRoutes.inicio,
    AppRoutes.login,
    AppRoutes.cadastro,
  };

  Route<void> gerar(RouteSettings configuracao) {
    final pedida = configuracao.name ?? AppRoutes.inicio;

    // Proteção de rotas: sem login, só as rotas públicas abrem.
    final liberada =
        _rotasPublicas.contains(pedida) || _dependencias.sessao.logado;
    final nome = liberada ? pedida : AppRoutes.inicio;

    // A tela é criada UMA vez, fora do builder (o builder pode ser chamado
    // de novo pelo Flutter; não queremos dois ViewModels para a mesma tela).
    final tela = _criarTela(nome, configuracao.arguments);
    return MaterialPageRoute<void>(
      builder: (_) => tela,
      settings: RouteSettings(name: nome, arguments: configuracao.arguments),
    );
  }

  Widget _criarTela(String nome, Object? argumento) {
    final d = _dependencias;
    return switch (nome) {
      AppRoutes.inicio =>
        EscolhaPerfilPage(sistema: d.sistema, auth: d.auth, sessao: d.sessao),
      AppRoutes.login =>
        LoginPage(tipo: _tipo(argumento), auth: d.auth, sessao: d.sessao),
      AppRoutes.cadastro => CadastroPage(
          tipo: _tipo(argumento),
          auth: d.auth,
          sessao: d.sessao,
          localizacao: d.localizacao,
        ),
      AppRoutes.inicioDoador =>
        HomeDoadorPage(doacoes: d.doacoes, sessao: d.sessao),
      AppRoutes.novaDoacao => NovaDoacaoPage(
          doacoes: d.doacoes,
          sessao: d.sessao,
          relogio: d.relogio,
        ),
      AppRoutes.detalheDoacaoDoador => DetalheDoacaoDoadorPage(
          doacaoId: _id(argumento),
          doacoes: d.doacoes,
          reservas: d.reservas,
          relogio: d.relogio,
        ),
      AppRoutes.inicioOng => HomeOngPage(doacoes: d.doacoes, sessao: d.sessao),
      AppRoutes.detalheDoacaoOng => DetalheDoacaoOngPage(
          doacaoId: _id(argumento),
          doacoes: d.doacoes,
          reservas: d.reservas,
          relogio: d.relogio,
        ),
      AppRoutes.minhasReservas =>
        MinhasReservasPage(reservas: d.reservas, relogio: d.relogio),
      AppRoutes.mapa => MapaPage(doacoes: d.doacoes, sessao: d.sessao),
      _ => const _PaginaNaoEncontrada(),
    };
  }

  static TipoUsuario _tipo(Object? argumento) =>
      argumento is TipoUsuario ? argumento : TipoUsuario.doador;

  static int _id(Object? argumento) => argumento is int ? argumento : 0;
}

class _PaginaNaoEncontrada extends StatelessWidget {
  const _PaginaNaoEncontrada();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Página não encontrada')),
        body: const Center(child: Text('Esta rota não existe.')),
      );
}
