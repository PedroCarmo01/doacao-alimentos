# 20 — App: mapa das doações próximas

> **Quem:** Pessoa 4. **Tempo:** 2 a 3 dias. **Branch:** `feat/mapa-app`.
> **Pré-requisito:** [16 — App: fundamentos](16-app-fundamentos.md) e o backend de proximidade ([14](14-backend-proximidade.md)). Comece no **modo Fake** com `maosamigas@exemplo.com` / `senha123`.
> **Alinhe antes:** com a **Pessoa 5** (o mapa abre o detalhe dela e é aberto pela lista dela) e com a **Pessoa 1** (centro do mapa = perfil do login). Ver [00_COMECE_AQUI/03 — Alinhamentos](../00_COMECE_AQUI/03-alinhamentos-entre-pessoas.md).

## O que vamos construir

Uma tela com um mapa do **OpenStreetMap** mostrando:

- um marcador azul na localização da **ONG** (vem do perfil, na `Sessao`);
- um marcador verde para cada **doação disponível** perto dela (a mesma lista da tela inicial da ONG);
- ao tocar num marcador de doação, um cartão com o resumo e o botão **Ver detalhes**.

```text
app/
├── lib/features/mapa/presentation/
│   ├── mapa_page.dart          ← substituir o placeholder
│   └── mapa_view_model.dart    ← novo
└── test/features/mapa/
    └── mapa_view_model_test.dart ← novo
```

## Vocabulário

| Termo | Em palavras simples |
|---|---|
| **OpenStreetMap (OSM)** | Um "Wikipedia dos mapas": gratuito, sem chave paga. Em troca, exige que o app **mostre os créditos** ("© OpenStreetMap contributors") |
| **Tile (ladrilho)** | O mapa chega em quadradinhos de imagem (256×256). O `flutter_map` baixa e monta os quadradinhos conforme você arrasta |
| **Zoom** | Nível de aproximação: 3 = continente, 13 = bairro, 18 = rua |
| **`LatLng`** | O tipo de coordenada que o `flutter_map` entende (pacote `latlong2`). Nosso `Coordenadas` vira `LatLng(lat, lng)` |
| **Marker** | O "alfinete" no mapa |
| **Bottom sheet** | O painel que sobe da parte de baixo da tela |

> **Regras de uso dos tiles do OSM:** (1) mostrar a atribuição na tela; (2) identificar o app com `userAgentPackageName`; (3) uso leve (é o nosso caso: demonstração). Os dois primeiros estão no código abaixo. Não apague!

---

## Passo 1 — MapaViewModel

```dart
// arquivo: app/lib/features/mapa/presentation/mapa_view_model.dart
import 'package:shared_models/shared_models.dart';

import '../../../core/mvvm/view_model_base.dart';
import '../../../core/sessao/sessao.dart';
import '../../../data/doacoes/doacao_repository.dart';

class MapaViewModel extends ViewModelBase {
  MapaViewModel({
    required DoacaoRepository doacoes,
    required Sessao sessao,
  })  : _repositorio = doacoes,
        _sessao = sessao;

  final DoacaoRepository _repositorio;
  final Sessao _sessao;

  List<Doacao> _doacoes = const [];
  Doacao? _selecionada;

  List<Doacao> get doacoes => _doacoes;

  /// A doação cujo marcador foi tocado (ou `null`).
  Doacao? get selecionada => _selecionada;

  /// Centro do mapa: a localização cadastrada da ONG.
  /// Sem perfil (não deveria acontecer, a rota é protegida), usa o centro
  /// de Mogi das Cruzes.
  Coordenadas get centro =>
      _sessao.perfil?.coordenadas ?? const Coordenadas(-23.5235, -46.1870);

  String get nomeOrganizacao => _sessao.perfil?.nomeOrganizacao ?? 'Você';

  Future<bool> carregar() => executar(() async {
        _doacoes = await _repositorio.listarProximas();
        // Se a selecionada saiu da lista (outra ONG reservou), some o cartão.
        final id = _selecionada?.id;
        _selecionada = _doacoes.where((d) => d.id == id).firstOrNull;
      });

  void selecionar(Doacao? doacao) {
    _selecionada = doacao;
    notificar();
  }
}
```

## Passo 2 — MapaPage

```dart
// arquivo: app/lib/features/mapa/presentation/mapa_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/sessao/sessao.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/doacoes/doacao_repository.dart';
import '../../../shared/widgets/doacao_card.dart';
import 'mapa_view_model.dart';

/// TELA: Mapa de doações próximas.
/// O CONSTRUTOR é o contrato com o AppRouter: não mude.
class MapaPage extends StatefulWidget {
  const MapaPage({
    super.key,
    required this.doacoes,
    required this.sessao,
  });

  final DoacaoRepository doacoes;
  final Sessao sessao;

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  late final MapaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = MapaViewModel(doacoes: widget.doacoes, sessao: widget.sessao);
    _vm.carregar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// Nosso modelo → tipo do flutter_map.
  static LatLng _ponto(Coordenadas c) => LatLng(c.latitude, c.longitude);

  Future<void> _abrirDetalhe(Doacao doacao) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detalheDoacaoOng,
      arguments: doacao.id,
    );
    _vm.carregar(); // pode ter reservado: o marcador some
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de doações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _vm.carregar,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _ponto(_vm.centro),
                initialZoom: 14,
                // tocar no mapa (fora dos marcadores) fecha o cartão
                onTap: (_, __) => _vm.selecionar(null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Identificação do app, exigida pela política do OSM.
                  userAgentPackageName: AppConfig.identificadorApp,
                ),
                MarkerLayer(
                  markers: [
                    // A ONG
                    Marker(
                      point: _ponto(_vm.centro),
                      width: 44,
                      height: 44,
                      child: Tooltip(
                        message: _vm.nomeOrganizacao,
                        child: const Icon(
                          Icons.home_filled,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ),
                    // As doações
                    for (final doacao in _vm.doacoes)
                      Marker(
                        point: _ponto(doacao.coordenadas),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _vm.selecionar(doacao),
                          child: Semantics(
                            label: 'Doação: ${doacao.titulo}',
                            button: true,
                            child: Icon(
                              Icons.location_on,
                              size: 44,
                              color: _vm.selecionada?.id == doacao.id
                                  ? AppColors.laranja
                                  : AppColors.verde,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Créditos OBRIGATÓRIOS do OpenStreetMap.
                // (o símbolo © é acrescentado automaticamente)
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            if (_vm.ocupado) const LinearProgressIndicator(),
            if (_vm.erro != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Material(
                  color: AppColors.erro,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _vm.erro!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            // Resumo no topo: quantas doações há no mapa.
            if (!_vm.ocupado && _vm.erro == null)
              Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  avatar: const Icon(Icons.location_on, color: AppColors.verde),
                  label: Text(
                    _vm.doacoes.length == 1
                        ? '1 doação perto de você'
                        : '${_vm.doacoes.length} doações perto de você',
                  ),
                ),
              ),
            // Cartão da doação selecionada.
            if (_vm.selecionada != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DoacaoCard(
                      doacao: _vm.selecionada!,
                      onTap: () => _abrirDetalhe(_vm.selecionada!),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () => _abrirDetalhe(_vm.selecionada!),
                        child: const Text('Ver detalhes'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

> **Por que `Stack`?** Ele empilha widgets um **por cima** do outro: o mapa embaixo e, por cima, a barra de progresso, o aviso de erro, o contador e o cartão. `Positioned` diz onde cada um fica.

> **Por que o mapa não "pula" de volta para o centro?** `initialCenter` só vale na primeira vez. Quando o ViewModel notifica, o `FlutterMap` é redesenhado, mas mantém a posição que o usuário arrastou.

## Passo 3 — Testar na mão

| Teste | Esperado |
|---|---|
| Modo Fake, `maosamigas@`, ícone de mapa | mapa de Mogi das Cruzes, casa azul e 3 marcadores verdes |
| Créditos | "© OpenStreetMap contributors" visível (ícone ⓘ no canto) |
| Tocar num marcador verde | ele fica laranja e aparece o cartão |
| Tocar no mapa vazio | o cartão some |
| "Ver detalhes" → Reservar → voltar | o marcador dessa doação sumiu |
| `distante@` | casa azul em São Paulo, chip "0 doações perto de você" |
| Celular sem internet | o mapa fica cinza, mas os marcadores aparecem (os dados vêm da API, os tiles da internet) |

> **Emulador sem mapa (tudo cinza)?** O emulador precisa de internet. Teste abrir o Chrome dentro do emulador. Se for proxy da rede da faculdade, use o 4G do celular como roteador.

## Passo 4 — Teste automatizado

O ViewModel é testado normalmente. A página do mapa **não** tem teste de widget: ela tenta baixar tiles da internet, o que não funciona nos testes. Isso é uma decisão consciente: registre no PR.

```dart
// arquivo: app/test/features/mapa/mapa_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_app/core/dependencias.dart';
import 'package:summit_app/data/fake/banco_fake.dart';
import 'package:summit_app/features/mapa/presentation/mapa_view_model.dart';

void main() {
  late Dependencias deps;

  setUp(() async {
    deps = Dependencias.fake(
      banco: BancoFake(atrasoDeRede: Duration.zero, simularNovasDoacoes: false),
    );
    final resposta = await deps.auth.entrar(
      const DadosLogin(email: 'maosamigas@exemplo.com', senha: 'senha123'),
    );
    await deps.sessao.iniciar(resposta);
  });

  test('centro do mapa é a localização da ONG', () {
    final vm = MapaViewModel(doacoes: deps.doacoes, sessao: deps.sessao);

    expect(vm.centro, const Coordenadas(-23.5180, -46.1850));
  });

  test('carrega as doações próximas e seleciona uma', () async {
    final vm = MapaViewModel(doacoes: deps.doacoes, sessao: deps.sessao);

    await vm.carregar();
    vm.selecionar(vm.doacoes.first);

    expect(vm.doacoes, isNotEmpty);
    expect(vm.selecionada, vm.doacoes.first);
  });

  test('a selecionada some se outra ONG reservar', () async {
    final vm = MapaViewModel(doacoes: deps.doacoes, sessao: deps.sessao);
    await vm.carregar();
    final alvo = vm.doacoes.first;
    vm.selecionar(alvo);

    await deps.reservas.reservar(alvo.id); // a própria ONG reserva
    await vm.carregar();

    expect(vm.selecionada, isNull);
    expect(vm.doacoes.any((d) => d.id == alvo.id), isFalse);
  });
}
```

## Passo 5 — Pull Request

```powershell
git add desenvolvimento_app/app/lib/features/mapa desenvolvimento_app/app/test/features/mapa
git commit -m "feat(mapa): mapa das doações próximas com OpenStreetMap"
git push -u origin feat/mapa-app
```

## O que pode dar errado

| Sintoma | Causa | Solução |
|---|---|---|
| `The named parameter 'child' isn't defined` no `Marker` | Versão do `flutter_map` diferente da 7 | Confira o `pubspec.lock`; não atualize pacotes sem combinar |
| Mapa cinza e erro `403` no console | Faltou `userAgentPackageName` | Mantenha a linha do passo 2 |
| Marcadores no meio do oceano | Latitude e longitude trocadas | `LatLng(latitude, longitude)`, nessa ordem |
| Mapa na Califórnia | Perfil cadastrado com o GPS do emulador sem posição | Refaça o cadastro com a posição definida (etapa 17) |

## Checklist

- [ ] As 7 linhas da tabela do passo 3 conferidas
- [ ] Atribuição do OpenStreetMap visível
- [ ] 3 testes passando
- [ ] PR mesclado

> **Para a apresentação:** saiba explicar por que o centro vem do perfil (e não do GPS na hora), o que é um tile e por que a atribuição é obrigatória.

Próximo para a Pessoa 4: [21 — Integração e testes](21-integracao-e-testes.md) (você cuida da CI e do banco de demonstração).
