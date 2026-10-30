# 14 — Backend: doações próximas da ONG

> **Quem:** Pessoa 4. **Tempo:** 2 a 3 dias. **Branch:** `feat/proximidade-backend`.
> **Pré-requisito:** [11](11-backend-fundamentos.md). Token de teste: `dart run tool/gerar_token.dart 3 ong` (o id 3 é a ONG Mãos Amigas no seed).

## O que vamos construir

| Rota | Quem | Faz | Resposta |
|---|---|---|---|
| `GET /proximas?raioKm=5` | ONG | doações que ainda podem ser reservadas, dentro do raio, da mais perto para a mais longe | `200` `{"doacoes": [...]}` com `distanciaKm` e `nomeDoador` |

- O **centro** da busca é a localização cadastrada no **perfil** da ONG (não vem do app: a ONG não consegue "fingir" estar em outro lugar).
- `raioKm` é opcional. Sem ele, vale `RAIO_PADRAO_KM` do `.env`. Ele é limitado entre **0,5 e 50 km** (protege o servidor de buscas enormes).
- Doador chamando: `403`.

```text
backend/
├── lib/proximidade/
│   ├── area_de_busca.dart
│   ├── proximidade_repository.dart
│   ├── proximidade_repository_mysql.dart
│   └── proximidade_service.dart
├── routes/proximas/
│   ├── _middleware.dart
│   └── index.dart
└── test/proximidade/
    └── proximidade_service_test.dart
```

## Conceito: como calcular "perto"

A distância entre dois pontos na superfície da Terra é calculada pela **fórmula de Haversine** (já implementada em `Geo.distanciaKm`, no `shared_models`). Calcular Haversine para **todas** as doações do banco funcionaria no projeto, mas não escala. Fazemos em **duas etapas**:

1. **Filtro grosso no SQL (caixa delimitadora):** um retângulo de latitude/longitude que contém o círculo do raio. É uma comparação simples (`BETWEEN`) e usa o índice `idx_doacoes_localizacao`.
2. **Filtro fino no Dart:** para as poucas candidatas, calcula a distância exata com Haversine, descarta as que estão nos "cantos" do retângulo e ordena.

```text
       lngMin            lngMax
latMax ┌───────────────────┐
       │    .-'''''-.      │   ← o SQL traz tudo dentro do retângulo
       │  /           \    │
       │ |   ONG  •    |   │   ← o Dart mantém só o que está no círculo
       │  \           /    │
       │    '-.....-'      │
latMin └───────────────────┘
```

1 grau de latitude ≈ **111,32 km** em qualquer lugar. 1 grau de longitude ≈ 111,32 × cos(latitude) km (os meridianos se aproximam perto dos polos).

## Passo 1 — A caixa delimitadora (objeto de valor)

```dart
// arquivo: backend/lib/proximidade/area_de_busca.dart
import 'dart:math' as math;

import 'package:shared_models/shared_models.dart';

/// Retângulo de latitude/longitude que contém o círculo de busca.
///
/// Objeto de VALOR imutável: criado uma vez, nunca alterado.
class AreaDeBusca {
  const AreaDeBusca({
    required this.latitudeMin,
    required this.latitudeMax,
    required this.longitudeMin,
    required this.longitudeMax,
  });

  /// Construtor nomeado ("factory"): esconde a matemática de quem usa.
  factory AreaDeBusca.aoRedor(Coordenadas centro, double raioKm) {
    const kmPorGrauLatitude = 111.32;
    final deltaLatitude = raioKm / kmPorGrauLatitude;
    final cosseno = math.cos(centro.latitude * math.pi / 180).abs();
    // Perto dos polos o cosseno tende a zero; o max evita divisão por zero.
    final deltaLongitude = raioKm / (kmPorGrauLatitude * math.max(cosseno, 0.01));
    return AreaDeBusca(
      latitudeMin: centro.latitude - deltaLatitude,
      latitudeMax: centro.latitude + deltaLatitude,
      longitudeMin: centro.longitude - deltaLongitude,
      longitudeMax: centro.longitude + deltaLongitude,
    );
  }

  final double latitudeMin;
  final double latitudeMax;
  final double longitudeMin;
  final double longitudeMax;

  bool contem(Coordenadas ponto) =>
      ponto.latitude >= latitudeMin &&
      ponto.latitude <= latitudeMax &&
      ponto.longitude >= longitudeMin &&
      ponto.longitude <= longitudeMax;
}
```

## Passo 2 — Repositório

```dart
// arquivo: backend/lib/proximidade/proximidade_repository.dart
import 'package:shared_models/shared_models.dart';

import 'area_de_busca.dart';

abstract interface class ProximidadeRepository {
  Future<Perfil?> perfilDo(int usuarioId);

  /// Doações `disponivel`, com janela ainda aberta em [agora], dentro da
  /// [area]. Sem ordem definida (quem ordena é o Service).
  Future<List<Doacao>> disponiveisNaArea(AreaDeBusca area, {required DateTime agora});
}
```

```dart
// arquivo: backend/lib/proximidade/proximidade_repository_mysql.dart
import 'package:shared_models/shared_models.dart';

import '../core/db/database.dart';
import '../core/db/mapeador.dart';
import '../core/utils/datas.dart';
import 'area_de_busca.dart';
import 'proximidade_repository.dart';

class ProximidadeRepositoryMysql implements ProximidadeRepository {
  ProximidadeRepositoryMysql(this._db);

  final Database _db;

  @override
  Future<Perfil?> perfilDo(int usuarioId) async {
    final linhas = await _db.consultar(
      '''
      SELECT usuario_id, nome_organizacao, telefone, endereco,
             latitude, longitude
        FROM perfis WHERE usuario_id = :id
      ''',
      {'id': usuarioId},
    );
    return linhas.isEmpty ? null : Mapeador.perfil(linhas.first);
  }

  @override
  Future<List<Doacao>> disponiveisNaArea(
    AreaDeBusca area, {
    required DateTime agora,
  }) async {
    final linhas = await _db.consultar(
      '''
      SELECT d.*, p.nome_organizacao AS nome_doador
        FROM doacoes d
        JOIN perfis p ON p.usuario_id = d.doador_id
       WHERE d.status = 'disponivel'
         AND d.janela_fim > :agora
         AND d.latitude  BETWEEN :latMin AND :latMax
         AND d.longitude BETWEEN :lngMin AND :lngMax
      ''',
      {
        'agora': Datas.paraSql(agora),
        'latMin': area.latitudeMin,
        'latMax': area.latitudeMax,
        'lngMin': area.longitudeMin,
        'lngMax': area.longitudeMax,
      },
    );
    return linhas.map(Mapeador.doacao).toList();
  }
}
```

## Passo 3 — Service

```dart
// arquivo: backend/lib/proximidade/proximidade_service.dart
import 'package:shared_models/shared_models.dart';

import '../core/erros/app_exception.dart';
import '../core/seguranca/usuario_autenticado.dart';
import 'area_de_busca.dart';
import 'proximidade_repository.dart';

class ProximidadeService {
  ProximidadeService({
    required ProximidadeRepository repositorio,
    required Relogio relogio,
    required double raioPadraoKm,
  })  : _repositorio = repositorio,
        _relogio = relogio,
        _raioPadraoKm = raioPadraoKm;

  static const raioMinimoKm = 0.5;
  static const raioMaximoKm = 50.0;

  final ProximidadeRepository _repositorio;
  final Relogio _relogio;
  final double _raioPadraoKm;

  Future<List<Doacao>> proximas(
    UsuarioAutenticado usuario, {
    double? raioKm,
  }) async {
    usuario.exigirTipo(TipoUsuario.ong);

    final perfil = await _repositorio.perfilDo(usuario.id) ??
        (throw const NaoAutenticadoException(
          codigo: 'TOKEN_INVALIDO',
          mensagem: 'Sessão inválida. Entre novamente.',
        ));

    final raio = (raioKm ?? _raioPadraoKm)
        .clamp(raioMinimoKm, raioMaximoKm)
        .toDouble();
    final centro = perfil.coordenadas;
    final agora = _relogio.agora();

    // Etapa 1: filtro grosso no banco.
    final candidatas = await _repositorio.disponiveisNaArea(
      AreaDeBusca.aoRedor(centro, raio),
      agora: agora,
    );

    // Etapa 2: distância exata, filtro do círculo e ordenação.
    final resultado = <Doacao>[];
    for (final doacao in candidatas) {
      if (!doacao.podeSerReservada(agora)) continue;
      final km = Geo.distanciaKm(centro, doacao.coordenadas);
      if (km <= raio) resultado.add(doacao.copyWith(distanciaKm: km));
    }
    resultado.sort((a, b) => a.distanciaKm!.compareTo(b.distanciaKm!));
    return resultado;
  }
}
```

## Passo 4 — Middleware e rota

```dart
// arquivo: backend/routes/proximas/_middleware.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/autenticacao.dart';
import 'package:summit_backend/proximidade/proximidade_repository_mysql.dart';
import 'package:summit_backend/proximidade/proximidade_service.dart';

Handler middleware(Handler handler) {
  return handler
      .use(
        provider<ProximidadeService>(
          (context) => ProximidadeService(
            repositorio: ProximidadeRepositoryMysql(context.read<Database>()),
            relogio: context.read<Relogio>(),
            raioPadraoKm: context.read<Env>().raioPadraoKm.toDouble(),
          ),
        ),
      )
      .use(exigirAutenticacao());
}
```

```dart
// arquivo: backend/routes/proximas/index.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/http/requisicao.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/proximidade/proximidade_service.dart';

/// `GET /proximas?raioKm=5`
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    throw const MetodoNaoPermitidoException();
  }
  final doacoes = await context.read<ProximidadeService>().proximas(
        context.read<UsuarioAutenticado>(),
        raioKm: context.parametroDecimal('raioKm'),
      );
  return Response.json(
    body: {'doacoes': [for (final d in doacoes) d.toJson()]},
  );
}
```

## Passo 5 — Testar na mão

Seção **PROXIMIDADE** do `api.http`, com o token da ONG.

| Teste | Esperado |
|---|---|
| `maosamigas@` sem `raioKm` | doações do seed, ordenadas, com `distanciaKm` |
| `?raioKm=0.1` | raio vira 0,5 km (menos resultados) |
| `?raioKm=abc` | 400 |
| `distante@` (São Paulo) | lista vazia (Mogi fica a ~45 km, fora do padrão de 10 km) |
| token de doador | 403 |
| doação reservada ou cancelada | não aparece |

> Confira uma distância no Google Maps: botão direito no mapa → *Medir distância*. Haversine mede em linha reta, então o valor é um pouco menor do que o trajeto por ruas.

## Passo 6 — Testes automatizados

```dart
// arquivo: backend/test/proximidade/proximidade_service_test.dart
import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/erros/app_exception.dart';
import 'package:summit_backend/core/seguranca/usuario_autenticado.dart';
import 'package:summit_backend/proximidade/area_de_busca.dart';
import 'package:summit_backend/proximidade/proximidade_repository.dart';
import 'package:summit_backend/proximidade/proximidade_service.dart';
import 'package:test/test.dart';

final agora = DateTime.utc(2026, 9, 15, 12);
const centroDaOng = Coordenadas(-23.5180, -46.1850); // Mogi das Cruzes

Doacao doacaoEm(int id, double lat, double lng, {StatusDoacao? status}) =>
    Doacao(
      id: id,
      doadorId: 1,
      titulo: 'Doação $id',
      categoria: CategoriaAlimento.outros,
      quantidade: '1 caixa',
      validade: DateTime.utc(2026, 9, 16),
      janelaInicio: agora,
      janelaFim: agora.add(const Duration(hours: 3)),
      latitude: lat,
      longitude: lng,
      status: status ?? StatusDoacao.disponivel,
      criadoEm: agora,
    );

class ProximidadeRepositoryEmMemoria implements ProximidadeRepository {
  ProximidadeRepositoryEmMemoria(this.doacoes);

  final List<Doacao> doacoes;
  AreaDeBusca? ultimaArea;

  @override
  Future<Perfil?> perfilDo(int usuarioId) async => Perfil(
        usuarioId: usuarioId,
        nomeOrganizacao: 'ONG Mãos Amigas',
        latitude: centroDaOng.latitude,
        longitude: centroDaOng.longitude,
      );

  @override
  Future<List<Doacao>> disponiveisNaArea(
    AreaDeBusca area, {
    required DateTime agora,
  }) async {
    ultimaArea = area;
    return doacoes
        .where((d) => d.estaDisponivel && area.contem(d.coordenadas))
        .toList();
  }
}

void main() {
  const ong = UsuarioAutenticado(id: 3, tipo: TipoUsuario.ong);
  const doador = UsuarioAutenticado(id: 1, tipo: TipoUsuario.doador);

  ProximidadeService criar(List<Doacao> doacoes) => ProximidadeService(
        repositorio: ProximidadeRepositoryEmMemoria(doacoes),
        relogio: RelogioFixo(agora),
        raioPadraoKm: 10,
      );

  test('a caixa de 10 km tem cerca de 0,09 grau de latitude para cada lado',
      () {
    final area = AreaDeBusca.aoRedor(centroDaOng, 10);
    expect(area.latitudeMax - centroDaOng.latitude, closeTo(0.0898, 0.001));
    expect(area.contem(centroDaOng), isTrue);
  });

  test('ordena da mais perto para a mais longe e preenche distanciaKm',
      () async {
    final service = criar([
      doacaoEm(1, -23.5262, -46.1932), // ~1,2 km
      doacaoEm(2, -23.5185, -46.1855), // ~0,07 km
    ]);

    final resultado = await service.proximas(ong);

    expect(resultado.map((d) => d.id), [2, 1]);
    expect(resultado.first.distanciaKm, lessThan(0.2));
  });

  test('descarta o que está fora do raio e o que não está disponível',
      () async {
    final service = criar([
      doacaoEm(1, -23.5505, -46.6333), // São Paulo, ~46 km
      doacaoEm(2, -23.5185, -46.1855, status: StatusDoacao.reservada),
    ]);

    expect(await service.proximas(ong), isEmpty);
  });

  test('limita o raio entre 0,5 e 50 km', () async {
    final repositorio = ProximidadeRepositoryEmMemoria([]);
    final service = ProximidadeService(
      repositorio: repositorio,
      relogio: RelogioFixo(agora),
      raioPadraoKm: 10,
    );

    await service.proximas(ong, raioKm: 5000);
    final deltaKm = (repositorio.ultimaArea!.latitudeMax - centroDaOng.latitude) * 111.32;
    expect(deltaKm, closeTo(50, 0.1));
  });

  test('doador não usa a busca por proximidade', () {
    expect(
      () => criar([]).proximas(doador),
      throwsA(isA<SemPermissaoException>()),
    );
  });
}
```

## Passo 7 — Pull Request

```powershell
git add desenvolvimento_app/backend/lib/proximidade desenvolvimento_app/backend/routes/proximas desenvolvimento_app/backend/test/proximidade
git commit -m "feat(proximidade): busca de doações próximas da ONG"
git push -u origin feat/proximidade-backend
```

## Checklist

- [ ] As 6 linhas da tabela do passo 5 conferidas
- [ ] 5 testes passando
- [ ] Sei explicar por que a busca tem duas etapas e por que o centro vem do perfil
- [ ] PR mesclado

Próximo para a Pessoa 4: [20 — App: mapa](20-app-mapa.md).
