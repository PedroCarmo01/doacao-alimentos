# ADR-005 — App em MVVM com `ChangeNotifier` (sem Riverpod)

- Status: Aceita
- Data: 2026-09-15

## Contexto
O projeto exige Programação Orientada a Objetos. A proposta inicial usava Riverpod, cujo estilo (providers globais, `ref.watch`) é mais funcional que orientado a objetos. Além disso, a API do Riverpod mudou bastante na versão 3, o que deixa os tutoriais disponíveis inconsistentes para iniciantes.

## Decisão
Adotar **MVVM** (Model–View–ViewModel), como recomenda o guia oficial de arquitetura do Flutter:
- **View** (`*_page.dart`): widgets; só desenha a tela e repassa as ações do usuário.
- **ViewModel** (`*_view_model.dart`): classe que estende `ViewModelBase` (que por sua vez estende `ChangeNotifier`). Guarda o estado da tela e as ações; avisa a View quando algo muda.
- **Model / Repository** (`lib/data/`): obtém e envia dados (API ou Fake).

A View escuta o ViewModel com `ListenableBuilder`, que faz parte do próprio Flutter.

## Alternativas consideradas
- **Riverpod**: poderoso, mas menos orientado a objetos e com API em transição.
- **BLoC**: muito usado no mercado, mas exige muitos conceitos ao mesmo tempo (eventos, estados, streams).
- **`setState` em todas as telas**: simples, porém mistura regra, dados e UI; difícil de testar.

## Consequências
- Positivas: classes com responsabilidade clara (fácil de representar em diagrama UML); padrão Observer explícito (`ChangeNotifier`); ViewModels testáveis sem tela; nenhum pacote extra.
- Cuidados: cada página deve chamar `viewModel.dispose()` no próprio `dispose()`; a `ViewModelBase` já evita o erro de notificar depois de descartado.
