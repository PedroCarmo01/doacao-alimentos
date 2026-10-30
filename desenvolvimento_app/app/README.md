# app/ — Aplicativo Flutter (MVVM)

App da plataforma de doação de alimentos. Arquitetura **MVVM** com classes do próprio Flutter (`ChangeNotifier` + `ListenableBuilder`), injeção de dependência por construtor e repositórios com duas implementações: **API** (backend real) e **Fake** (dados em memória).

- Passo a passo para iniciantes: [trilha/16 — App: fundamentos](../../trilha/16-app-fundamentos.md)
- Por que MVVM e não Riverpod: [ADR-005](../../docs/adr/ADR-005-app-mvvm-changenotifier.md)

## Estrutura

```text
app/lib/
├── main.dart                      escolhe API ou Fake e inicia o app
├── app.dart                       MaterialApp + tema + rotas
├── core/                          FUNDAÇÃO (pronta)
│   ├── config/app_config.dart     API_URL, USAR_FAKE, nome do app, intervalo do aviso
│   ├── dependencias.dart          raiz de composição: Dependencias.api() / .fake()
│   ├── api/                       ApiClient (http + token + erros) e ApiException
│   ├── erros/erro_amigavel.dart   interface ErroAmigavel + ErroDeRegra
│   ├── mvvm/view_model_base.dart  classe-mãe dos ViewModels (ocupado, erro, executar)
│   ├── sessao/                    Sessao (quem está logado) e ArmazenamentoToken
│   ├── routing/                   AppRoutes (nomes) e AppRouter (cria as telas)
│   ├── theme/app_theme.dart       cores e tema
│   └── utils/formatador.dart      datas, durações e distâncias para exibir
├── data/                          FUNDAÇÃO: um arquivo por recurso = interface + Api + Fake
│   ├── auth/auth_repository.dart
│   ├── doacoes/doacao_repository.dart
│   ├── reservas/reserva_repository.dart
│   ├── sistema/sistema_repository.dart      health check (GET /)
│   ├── localizacao/localizacao_service.dart GPS (geolocator) + Fake
│   └── fake/banco_fake.dart                 "backend de mentira" com as mesmas regras
├── shared/widgets/                componentes reutilizáveis (botão, campo, card, contador...)
└── features/                      TELAS — cada pasta tem um dono
    ├── auth/      Pessoa 1 (escolha_perfil já pronta como exemplo; login e cadastro a fazer)
    ├── doador/    Pessoa 2
    ├── ong/       Pessoa 5
    └── mapa/      Pessoa 4
```

Cada tela é um par **`*_page.dart`** (View) + **`*_view_model.dart`** (ViewModel). A `escolha_perfil` é o exemplo completo a ser copiado.

## Primeira vez

As pastas nativas (`android/`) são geradas uma única vez, no Sprint 0, por quem cuida da infraestrutura ([trilha/10](../../trilha/10-sprint-0-esqueleto-funcional.md)). Depois disso, cada pessoa só precisa de:

```powershell
cd desenvolvimento_app/app
flutter pub get
```

## Rodar (VS Code)

Abra a aba **Run and Debug** (`Ctrl+Shift+D`), escolha o perfil e aperte F5:

| Perfil | Quando usar |
|---|---|
| **App — dados fictícios (sem backend)** | Fazer telas sem depender do backend |
| **App — API local (emulador)** | Backend rodando no seu PC + emulador Android |
| **App — API local (celular físico)** | Troque o IP no `launch.json` pelo IP do seu PC |
| **App — Chrome (API local)** | PC fraco para emulador; útil para trabalhar no visual |

Pelo terminal:

```powershell
flutter run --dart-define=USAR_FAKE=true
flutter run --dart-define=API_URL=http://10.0.2.2:8080
```

No modo Fake a senha de todos os usuários é `senha123` (mesmos e-mails do seed do backend).

## Testes

```powershell
flutter test
flutter analyze
```

## Regras (valem para todas as telas)

1. A **View** não chama a API, não guarda regra de negócio e não usa `setState` para dados: ela lê o ViewModel.
2. O **ViewModel** estende `ViewModelBase`, recebe as dependências pelo construtor (tipadas pela interface) e usa `executar(...)` nas ações.
3. A página cria o ViewModel no `initState` e chama `dispose()` no `dispose`.
4. Validações de formulário usam `ValidadorUsuario` e `ValidadorDoacao` do `shared_models` (as mesmas do backend).
5. **Não altere** os construtores das páginas, o `AppRouter` nem a `Dependencias` sem combinar com o grupo.
