import 'package:flutter/material.dart';

import '../../core/preferencias/preferencias.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/localizacao/localizacao_service.dart';
import '../../shared/widgets/primary_button.dart';
import 'boas_vindas_view_model.dart';

/// T2 — Boas-vindas: 3 telas deslizáveis com "Pular" (só na primeira vez).
class BoasVindasPage extends StatefulWidget {
  const BoasVindasPage({
    super.key,
    required this.preferencias,
    required this.localizacao,
  });

  final Preferencias preferencias;
  final LocalizacaoService localizacao;

  @override
  State<BoasVindasPage> createState() => _BoasVindasPageState();
}

class _BoasVindasPageState extends State<BoasVindasPage> {
  late final BoasVindasViewModel _viewModel;
  final _paginas = PageController();

  /// Qual das 3 telas está aparecendo. É estado só da TELA (não é dado do
  /// app), por isso pode ficar aqui com `setState`.
  int _atual = 0;

  static const _telas = [
    _Tela(
      icone: Icons.volunteer_activism,
      titulo: 'Alimento bom não vai para o lixo',
      texto:
          'Mercados, feiras, padarias e restaurantes anunciam o que sobrou. '
          'ONGs próximas recebem e levam para quem precisa.',
    ),
    _Tela(
      icone: Icons.sync_alt,
      titulo: 'Doador anuncia, ONG retira',
      texto:
          '1. O doador publica a doação com fotos.\n'
          '2. A primeira ONG que aceitar tem um prazo para buscar.\n'
          '3. Na retirada, os dois confirmam com um código de 4 números.',
    ),
    _Tela(
      icone: Icons.location_on,
      titulo: 'Precisamos de duas permissões',
      texto:
          'Localização: para achar doações e ONGs perto de você.\n\n'
          'Notificações: para avisar na hora quando surgir uma doação nova '
          'ou a sua for aceita.',
    ),
  ];

  bool get _naUltima => _atual == _telas.length - 1;

  @override
  void initState() {
    super.initState();
    _viewModel = BoasVindasViewModel(
      preferencias: widget.preferencias,
      localizacao: widget.localizacao,
    );
  }

  @override
  void dispose() {
    _paginas.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _concluir({required bool pedirPermissoes}) async {
    await _viewModel.concluir(pedirPermissoes: pedirPermissoes);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _avancar() {
    if (_naUltima) {
      _concluir(pedirPermissoes: true);
      return;
    }
    _paginas.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _concluir(pedirPermissoes: false),
                child: const Text('Pular'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                onPageChanged: (indice) => setState(() => _atual = indice),
                children: _telas,
              ),
            ),
            _Pontos(total: _telas.length, atual: _atual),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => PrimaryButton(
                  texto: _naUltima ? 'Permitir e continuar' : 'Próximo',
                  carregando: _viewModel.ocupado,
                  onPressed: _avancar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tela extends StatelessWidget {
  const _Tela({required this.icone, required this.titulo, required this.texto});

  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.verdeClaro,
            child: Icon(icone, size: 64, color: AppColors.verde),
          ),
          const SizedBox(height: 32),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Os pontinhos que mostram em qual das telas a pessoa está.
class _Pontos extends StatelessWidget {
  const _Pontos({required this.total, required this.atual});

  final int total;
  final int atual;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tela ${atual + 1} de $total',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == atual ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == atual ? AppColors.verde : AppColors.cinza,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
