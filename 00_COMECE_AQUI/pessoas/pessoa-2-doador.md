# Pessoa 2 — Doador

**Sua missão:** permitir que mercados, padarias e feiras **anunciem o excedente** com segurança alimentar (sem vencidos, com declaração) e **acompanhem** o que aconteceu com cada doação.

**Histórias:** HU03 (publicar), HU04 (minhas doações), HU05 (cancelar) e o lado do doador da HU10 (confirmar retirada). **Requisitos:** RF09–RF15.

## Sua sequência

| # | Etapa | O que você entrega | Feito |
|---|---|---|---|
| 1 | Trilha 01 a 10 (com todos) | ambiente pronto e Sprint 0 rodando | [ ] |
| 2 | [11 — Backend: fundamentos](../../trilha/11-backend-fundamentos.md) | entender rotas, middlewares e camadas | [ ] |
| 3 | [13 — Backend: doações](../../trilha/13-backend-doacoes.md) | `POST/GET /doacoes`, `GET/DELETE /doacoes/{id}` + 7 testes | [ ] |
| 4 | [16 — App: fundamentos](../../trilha/16-app-fundamentos.md) | entender MVVM e a receita de tela | [ ] |
| 5 | [18 — App: telas do doador](../../trilha/18-app-doador.md) | minhas doações, nova doação, detalhe + 7 testes | [ ] |
| 6 | [21](../../trilha/21-integracao-e-testes.md) e [22](../../trilha/22-documentacao-e-entrega.md) | integração; manual do usuário (doador) com prints | [ ] |

## Seus arquivos

```text
desenvolvimento_app/backend/lib/doacoes/
desenvolvimento_app/backend/routes/doacoes/
desenvolvimento_app/backend/test/doacoes/
desenvolvimento_app/app/lib/features/doador/presentation/
desenvolvimento_app/app/test/features/doador/
```

## Dependências

- **Você depende de:** Sprint 0. Para testar o backend antes do login existir: `dart run tool/gerar_token.dart 1 doador`. Para as telas, o modo Fake.
- **Dependem de você:** a ONG (Pessoas 3, 4 e 5) precisa de doações no banco para testar no modo API. O seed já cria algumas, então ninguém fica parado.

## Com quem você precisa se alinhar

| Com | Sobre | Quando |
|---|---|---|
| P3 | o seu `GET /doacoes/{id}` devolve a **reserva ativa** (tabela da P3); o botão Confirmar retirada chama a rota da P3 | quando a P3 começar a etapa 15 |
| P4 | doação sem latitude/longitude usa a do perfil e precisa aparecer no `GET /proximas` | quando as etapas 13 e 14 estiverem prontas |
| P3 e P5 | **quem a ONG pode ver** no detalhe da doação (inclusive o 404 depois da retirada) — conversa a três | início do Sprint 2 |
| P5 | qualquer mudança no `DoacaoCard` (usado nas duas telas iniciais) | antes de mudar |

Detalhes: [03 — Alinhamentos](../03-alinhamentos-entre-pessoas.md).

## O que você precisa saber explicar

- Por que "hoje" depende do **fuso horário** (22h em Brasília já é o dia seguinte em UTC).
- Por que o cancelamento faz **duas checagens** (no Service e no `UPDATE ... WHERE status = 'disponivel'`).
- Por que a regra "pode ser cancelada?" mora no **modelo** `Doacao` (encapsulamento).
- Por que o banco guarda **UTC** e o app converte só para mostrar.

## Dicas

- No formulário, teste os casos de erro antes do caso feliz: é onde estão as regras do escopo.
- Use o `RefreshIndicator` (puxar para atualizar) para conferir que a lista está sempre certa.
