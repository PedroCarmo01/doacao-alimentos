# app/ — Aplicativo Flutter (MVVM)

App da plataforma de doação de alimentos. Arquitetura **MVVM** com classes do próprio Flutter (`ChangeNotifier` + `ListenableBuilder`), injeção de dependência por construtor e repositórios com duas implementações: **API** (backend real) e **Fake** (dados em memória, sem servidor).

- Por que MVVM e não Riverpod: [ADR-005](../../docs/adr/ADR-005-app-mvvm-changenotifier.md)
- Passo a passo de como o app foi construído: [trilha/16 — App: fundamentos](../../trilha/16-app-fundamentos.md)

## Estrutura

```text
app/lib/
├── main.dart                 escolhe API ou Fake e inicia o app
├── app.dart                  MaterialApp + tema + rotas
├── core/                     infraestrutura do app
│   ├── config/               API_URL, USAR_FAKE, nome do app, intervalo de atualização
│   ├── dependencias.dart     raiz de composição: Dependencias.api() / .fake()
│   ├── api/                  ApiClient (http + token + erros) e ApiException
│   ├── erros/                mensagens de erro amigáveis
│   ├── mvvm/                 ViewModelBase (ocupado, erro, executar)
│   ├── notificacoes/         notificações locais e destino ao tocar
│   ├── preferencias/         preferências do aparelho (ex.: já viu as boas-vindas)
│   ├── sessao/               quem está logado e armazenamento seguro do token
│   ├── routing/              AppRoutes (nomes) e AppRouter (cria as telas)
│   ├── theme/                cores e tema
│   └── utils/                formatação de datas/distâncias e rota no mapa
├── data/                     DADOS: um arquivo por recurso = interface + Api + Fake
│   ├── auth/  doacoes/  reservas/  chat/  comunidade/  perfil/
│   ├── notificacoes/  documentos/  sistema/  fotos/  localizacao/ (GPS e CEP)
│   └── fake/                 "backend de mentira" em memória, com as mesmas regras
├── shared/widgets/           componentes reutilizáveis (botão, campo, card, contador,
│                             estados de carregando/erro/vazio, selo, fotos...)
└── features/                 TELAS: cada pasta tem páginas (View) e ViewModels
    ├── abertura/   tela de abertura e boas-vindas
    ├── auth/       login, cadastro em passos e termos
    ├── doador/     publicar doação, detalhe, confirmar retirada com código
    ├── ong/        doações próximas, reservas, retirada em andamento
    ├── mapa/       mapa com as doações ao redor
    ├── chat/       conversas e chat de cada retirada
    ├── comunidade/ painel de impacto e feed de publicações
    ├── perfil/     perfil, edição, raio de busca e avisos
    └── navegacao/  casca com a barra inferior
```

Cada tela é um par **`*_page.dart`** (View) + **`*_view_model.dart`** (ViewModel).

## Rodar

```bash
flutter pub get
flutter run --dart-define=USAR_FAKE=true                      # sem servidor, dados fictícios
flutter run --dart-define=API_URL=http://10.0.2.2:8080        # com o backend (emulador Android)
```

No modo Fake a senha de todos os usuários é `senha123` (mesmos e-mails do seed do backend; a lista está no [README principal](../../README.md#usuários-de-teste)). Para subir o backend e o banco, veja o README principal ou [`../backend/README.md`](../backend/README.md).

No VS Code, os perfis prontos estão em *Run and Debug* (`Ctrl+Shift+D`): dados fictícios, API local no emulador, API local no celular físico e Chrome.

## Testes e análise

```bash
flutter analyze
flutter test
```

## Regras (valem para todas as telas)

1. A **View** não chama a API, não guarda regra de negócio e não usa `setState` para dados: ela lê o ViewModel.
2. O **ViewModel** estende `ViewModelBase`, recebe as dependências pelo construtor (tipadas pela interface) e usa `executar(...)` nas ações.
3. A página cria o ViewModel no `initState` e chama `dispose()` no `dispose`.
4. Validações de formulário usam `ValidadorUsuario` e `ValidadorDoacao` do `shared_models` (as mesmas do backend).
5. As telas que carregam listas ou detalhes tratam os três estados: carregando, erro (com "tentar de novo") e lista vazia (`shared/widgets/estados.dart`).
