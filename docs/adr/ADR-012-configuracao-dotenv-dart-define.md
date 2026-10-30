# ADR-012 — Configuração: `.env` no backend e `--dart-define` no app

- Status: Aceita
- Data: 2026-09-15

## Contexto
O backend precisa de segredos (senha do banco, segredo do JWT) que não podem ir para o Git. O app precisa saber o endereço da API, que muda conforme o lugar onde roda (emulador, celular físico ou Chrome).

## Decisão
- **Backend**: arquivo `desenvolvimento_app/backend/.env` (fora do Git), lido pela classe `Env` com o pacote `dotenv`. As variáveis do sistema operacional têm prioridade (útil na CI e em deploy). O `.env.example` é versionado como modelo.
- **App**: valores definidos na compilação com `--dart-define` e lidos por `AppConfig` (`String.fromEnvironment`). No VS Code, os perfis de execução do `.vscode/launch.json` já passam os valores (API local, celular físico, modo Fake).

## Alternativas consideradas
- **`.env` dentro do app (`flutter_dotenv`)**: o arquivo seria empacotado dentro do APK; não serve para segredos e exige mais um pacote.
- **Valores fixos no código**: obrigaria editar código para trocar de emulador para celular.

## Consequências
- Positivas: nenhum segredo no repositório; trocar de ambiente é escolher outro perfil no VS Code.
- Cuidados: o app **não guarda segredos**, só endereços. Lembrem de copiar o `.env.example` para `.env` em cada máquina.
