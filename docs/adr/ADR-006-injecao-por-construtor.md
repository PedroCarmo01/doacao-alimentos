# ADR-006 — Injeção de dependência por construtor + raiz de composição

- Status: Aceita
- Data: 2026-09-15

## Contexto
ViewModels e Services precisam de repositórios, e repositórios precisam do cliente HTTP ou do banco. Se cada classe criar as próprias dependências (`final repo = DoacaoRepositoryApi()` dentro do ViewModel), não dá para trocar por um Fake em testes nem rodar o app sem backend.

## Decisão
- **App**: cada classe recebe as dependências **pelo construtor**, tipadas pela **interface** (`DoacaoRepository`, não `DoacaoRepositoryApi`). Um único objeto, `Dependencias` (a *Composition Root*), cria tudo no `main.dart`: `Dependencias.api()` ou `Dependencias.fake()`. O `AppRouter` repassa a cada página o que ela precisa.
- **Backend**: o `main.dart` disponibiliza a infraestrutura (`Database`, `Env`, `TokenService`, `Relogio`) com `provider` do Dart Frog. O `_middleware.dart` de cada pasta monta os Services da própria fatia.

## Alternativas consideradas
- **Pacote `provider` / `get_it`**: funcionam, mas escondem de onde vêm as dependências; para quem está aprendendo, o construtor explícito é mais claro.
- **Singletons globais**: acoplamento alto e testes difíceis.

## Consequências
- Positivas: aplica o princípio da Inversão de Dependência (o "D" do SOLID); testes simples (basta passar um Fake no construtor); app funciona offline no modo Fake.
- Cuidados: um pouco mais de parâmetros nos construtores. O roteador e a `Dependencias` são arquivos de fundação e só mudam via PR combinado com o grupo.
