import 'package:flutter/material.dart';

import '../../features/abertura/abertura_page.dart';
import '../../features/abertura/boas_vindas_page.dart';
import '../../features/auth/cadastro/cadastro_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/termos_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/doador/confirmar_retirada_page.dart';
import '../../features/doador/detalhe_doacao_doador_page.dart';
import '../../features/doador/nova_doacao_page.dart';
import '../../features/navegacao/casca_page.dart';
import '../../features/ong/detalhe_doacao_ong_page.dart';
import '../../features/ong/minhas_reservas_page.dart';
import '../../features/ong/retirada_page.dart';
import '../dependencias.dart';
import 'app_routes.dart';

/// Cria a tela de cada rota e entrega a ela as dependências de que precisa.
///
/// As telas recebem só as interfaces de que precisam (nunca a
/// `Dependencias` inteira): assim fica claro do que cada uma depende.
class AppRouter {
  AppRouter(this._dependencias);

  final Dependencias _dependencias;

  /// Rotas que abrem sem login.
  static const _rotasPublicas = {
    AppRoutes.inicio,
    AppRoutes.boasVindas,
    AppRoutes.login,
    AppRoutes.cadastro,
    AppRoutes.termos,
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
      AppRoutes.inicio => AberturaPage(
        auth: d.auth,
        sessao: d.sessao,
        preferencias: d.preferencias,
      ),
      AppRoutes.boasVindas => BoasVindasPage(
        preferencias: d.preferencias,
        localizacao: d.localizacao,
        notificacoes: d.mostrador,
      ),
      AppRoutes.login => LoginPage(
        auth: d.auth,
        sessao: d.sessao,
        aviso: argumento is String ? argumento : null,
      ),
      AppRoutes.cadastro => CadastroPage(
        auth: d.auth,
        sessao: d.sessao,
        documentos: d.documentos,
        localizacao: d.localizacao,
        cep: d.cep,
      ),
      AppRoutes.termos => const TermosPage(),
      AppRoutes.casca => CascaPage(dependencias: d),
      // Argumento opcional: `int` = editar esta doação.
      AppRoutes.novaDoacao => NovaDoacaoPage(
        doacoes: d.doacoes,
        seletor: d.seletorDeFotos,
        sessao: d.sessao,
        relogio: d.relogio,
        doacaoId: argumento is int ? argumento : null,
      ),
      AppRoutes.detalheDoacaoDoador => DetalheDoacaoDoadorPage(
        doacaoId: _id(argumento),
        doacoes: d.doacoes,
        reservas: d.reservas,
        relogio: d.relogio,
      ),
      AppRoutes.detalheDoacaoOng => DetalheDoacaoOngPage(
        doacaoId: _id(argumento),
        doacoes: d.doacoes,
        reservas: d.reservas,
        sessao: d.sessao,
        relogio: d.relogio,
      ),
      AppRoutes.minhasReservas => MinhasReservasPage(
        reservas: d.reservas,
        relogio: d.relogio,
      ),
      AppRoutes.retirada => RetiradaPage(
        reservaId: _id(argumento),
        reservas: d.reservas,
        doacoes: d.doacoes,
        relogio: d.relogio,
      ),
      AppRoutes.chat => ChatPage(
        reservaId: _id(argumento),
        chat: d.chat,
        sessao: d.sessao,
        receptor: d.receptor,
      ),
      AppRoutes.confirmarRetirada => ConfirmarRetiradaPage(
        reservaId: _id(argumento),
        reservas: d.reservas,
      ),
      _ => const _PaginaNaoEncontrada(),
    };
  }

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
