# ADR-011 — Walking skeleton, fatias verticais por pessoa e repositórios Fake

- Status: Aceita
- Data: 2026-09-15

## Contexto
- São 5 pessoas que nunca trabalharam juntas no GitHub e nunca editaram o mesmo código ao mesmo tempo.
- O professor avalia pelo GitHub, então o histórico precisa mostrar a contribuição de cada um.
- Se o app depender do backend pronto para começar, quem faz telas fica parado.

## Decisão
1. **Walking skeleton (Sprint 0)**: o repositório começa com a fundação pronta (modelos, infraestrutura, roteador, tema, componentes) e todas as telas como placeholders "em construção". O app navega de ponta a ponta e a API responde `GET /` consultando o banco.
2. **Contratos primeiro**: modelos, endpoints, interfaces de repositório e construtores das páginas são definidos antes. Cada pessoa programa contra o contrato.
3. **Fatias verticais**: cada pessoa implementa uma funcionalidade inteira (repositório MySQL → Service → rotas → testes, ou ViewModel → página → testes) em arquivos próprios, em uma branch, entregue por Pull Request.
4. **Repositórios Fake**: cada interface de repositório tem uma implementação em memória. Com `--dart-define=USAR_FAKE=true`, o app roda sem backend.
5. **Ferramentas de apoio**: `tool/seed.dart` (dados de exemplo) e `tool/gerar_token.dart` (token de teste) permitem testar rotas protegidas antes do login existir.

## Alternativas consideradas
- **Entregar todo o código pronto no primeiro commit**: o GitHub mostraria um único autor, e o grupo não aprenderia.
- **Dividir por camada** (uma pessoa só no banco, outra só nas telas): gera dependência em cadeia e ninguém vê a funcionalidade inteira funcionando.

## Consequências
- Positivas: trabalho paralelo de verdade; conflitos raros; integração contínua desde o primeiro dia; histórico de contribuição individual.
- Cuidados: arquivos de fundação (roteador, `Dependencias`, `main.dart`, `pubspec.yaml`) só mudam em PR combinado; o código completo de cada fatia está na trilha e deve ser **entendido**, não só copiado.
