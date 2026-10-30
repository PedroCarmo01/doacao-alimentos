import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'cadastro_view_model.dart';
import 'controladores_do_cadastro.dart';

/// Cadastro, passo 4 — localização: CEP, GPS e um mapa pequeno.
///
/// O ALFINETE FICA PARADO NO MEIO do mapa e a pessoa arrasta o MAPA por
/// baixo dele até o ponto do portão. É o mesmo efeito de arrastar o
/// alfinete, mas mais fácil de acertar com o dedo (e de programar).
/// Para a ONG, esse ponto é o centro da busca; para o doador, o endereço
/// padrão de retirada.
class PassoLocalizacao extends StatelessWidget {
  const PassoLocalizacao({
    super.key,
    required this.viewModel,
    required this.campos,
    required this.mapa,
    required this.aoBuscarCep,
    required this.aoUsarGps,
  });

  final CadastroViewModel viewModel;
  final ControladoresDoCadastro campos;
  final MapController mapa;
  final VoidCallback aoBuscarCep;
  final VoidCallback aoUsarGps;

  /// Centro de Mogi das Cruzes, onde o mapa começa.
  static const centroInicial = Coordenadas(-23.5229, -46.1880);
  static const zoomInicial = 15.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          viewModel.ehOng ? 'Onde fica a ONG?' : 'Onde as ONGs vão retirar?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                key: const Key('campo_cep'),
                label: 'CEP',
                controller: campos.cep,
                prefixIcon: Icons.markunread_mailbox_outlined,
                somenteNumeros: true,
                tamanhoMaximo: 8,
                validator: ValidadorUsuario.cep,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: viewModel.ocupado ? null : aoBuscarCep,
                child: const Text('Buscar'),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          key: const Key('botao_gps'),
          onPressed: viewModel.ocupado ? null : aoUsarGps,
          icon: const Icon(Icons.my_location),
          label: const Text('Usar minha localização'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 16),
        _Mapa(viewModel: viewModel, controlador: mapa),
        const SizedBox(height: 8),
        Text(
          viewModel.coordenadas == null
              ? 'Busque o CEP, use o GPS ou arraste o mapa até o alfinete '
                    'ficar em cima do portão.'
              : 'Ponto marcado. Arraste o mapa para ajustar.',
          style: const TextStyle(color: AppColors.cinza),
        ),
        const SizedBox(height: 16),
        AppTextField(
          key: const Key('campo_endereco'),
          label: 'Endereço com número',
          controller: campos.endereco,
          prefixIcon: Icons.home_outlined,
          acaoDoTeclado: TextInputAction.done,
          validator: (valor) => (valor?.trim() ?? '').isEmpty
              ? 'Informe o endereço com o número.'
              : ValidadorUsuario.textoLivre(valor),
        ),
      ],
    );
  }
}

class _Mapa extends StatelessWidget {
  const _Mapa({required this.viewModel, required this.controlador});

  final CadastroViewModel viewModel;
  final MapController controlador;

  @override
  Widget build(BuildContext context) {
    final inicio = viewModel.coordenadas ?? PassoLocalizacao.centroInicial;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMap(
              mapController: controlador,
              options: MapOptions(
                initialCenter: LatLng(inicio.latitude, inicio.longitude),
                initialZoom: PassoLocalizacao.zoomInicial,
                // Só conta quando a PESSOA arrastou (hasGesture). Quando o
                // app move o mapa (CEP/GPS), o ViewModel já sabe o ponto.
                onPositionChanged: (camera, comGesto) {
                  if (!comGesto) return;
                  viewModel.moverAlfinete(
                    Coordenadas(
                      camera.center.latitude,
                      camera.center.longitude,
                    ),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: AppConfig.identificadorApp,
                ),
                const SimpleAttributionWidget(source: Text('OpenStreetMap')),
              ],
            ),
            // O alfinete desenhado por cima, sempre no centro. O "bico" do
            // ícone fica na parte de baixo, por isso o deslocamento.
            const IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: AppColors.erro,
                  semanticLabel: 'Local marcado',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
