import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_routes.dart';
import '../../core/sessao/sessao.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../data/doacoes/doacao_repository.dart';
import '../../shared/widgets/foto_da_doacao.dart';
import 'mapa_view_model.dart';

/// T21 — Mapa (botão central da ONG): OpenStreetMap centrado na ONG, com o
/// círculo do raio e um marcador verde por doação. Tocar num marcador mostra
/// um cartão com o resumo e "Ver detalhes".
class MapaPage extends StatefulWidget {
  const MapaPage({super.key, required this.doacoes, required this.sessao});

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  late final MapaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MapaViewModel(doacoes: widget.doacoes, sessao: widget.sessao);
    _viewModel.carregar();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  static LatLng _ponto(Coordenadas c) => LatLng(c.latitude, c.longitude);

  Future<void> _abrir(Doacao doacao) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detalheDoacaoOng,
      arguments: doacao.id,
    );
    if (mounted) _viewModel.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de doações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar o mapa',
            icon: const Icon(Icons.refresh),
            onPressed: _viewModel.carregar,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Stack(
          children: [
            _mapa(),
            if (_viewModel.ocupado) const LinearProgressIndicator(),
            if (_viewModel.erro != null) _erro(_viewModel.erro!),
            if (_viewModel.selecionada != null)
              _CartaoDaDoacao(
                doacao: _viewModel.selecionada!,
                aoFechar: () => _viewModel.selecionar(null),
                aoVerDetalhes: () => _abrir(_viewModel.selecionada!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapa() {
    final vm = _viewModel;
    return FlutterMap(
      options: MapOptions(
        initialCenter: _ponto(vm.centro),
        initialZoom: vm.zoomInicial,
        onTap: (_, _) => vm.selecionar(null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConfig.identificadorApp,
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: _ponto(vm.centro),
              radius: vm.raioKm * 1000, // em metros
              useRadiusInMeter: true,
              color: AppColors.verde.withValues(alpha: 0.08),
              borderColor: AppColors.verde,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _ponto(vm.centro),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.home,
                color: AppColors.azul,
                size: 36,
                semanticLabel: 'Sua ONG',
              ),
            ),
            for (final doacao in vm.doacoes)
              Marker(
                point: _ponto(doacao.coordenadas),
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: IconButton(
                  tooltip: doacao.titulo,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.location_pin,
                    color: AppColors.verde,
                    size: 44,
                  ),
                  onPressed: () => vm.selecionar(doacao),
                ),
              ),
          ],
        ),
        // Créditos do OpenStreetMap: obrigatórios pela licença dos mapas.
        const SimpleAttributionWidget(source: Text('OpenStreetMap')),
      ],
    );
  }

  Widget _erro(String mensagem) => Positioned(
    top: 8,
    left: 8,
    right: 8,
    child: Material(
      color: AppColors.erro,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        title: Text(mensagem, style: const TextStyle(color: Colors.white)),
        trailing: TextButton(
          onPressed: _viewModel.carregar,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Tentar novamente'),
        ),
      ),
    ),
  );
}

/// Cartão com o resumo da doação tocada no mapa.
class _CartaoDaDoacao extends StatelessWidget {
  const _CartaoDaDoacao({
    required this.doacao,
    required this.aoFechar,
    required this.aoVerDetalhes,
  });

  final Doacao doacao;
  final VoidCallback aoFechar;
  final VoidCallback aoVerDetalhes;

  @override
  Widget build(BuildContext context) {
    final distancia = doacao.distanciaKm;
    return Positioned(
      left: 16,
      right: 16,
      // Acima da barra inferior (o corpo passa por trás dela).
      bottom: 110,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FotoDaDoacao(
                caminho: doacao.fotos.firstOrNull,
                categoria: doacao.categoria,
                tamanho: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      doacao.titulo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${doacao.quantidadeTexto}'
                      '${distancia == null ? '' : ' • ${Formatador.distancia(distancia)}'}',
                    ),
                    TextButton(
                      key: const Key('ver_detalhes'),
                      onPressed: aoVerDetalhes,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Ver detalhes'),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                icon: const Icon(Icons.close),
                onPressed: aoFechar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
