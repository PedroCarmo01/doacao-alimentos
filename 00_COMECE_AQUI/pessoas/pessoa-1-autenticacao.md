# Pessoa 1 — Login e cadastro

**Sua missão:** fazer as pessoas **entrarem no sistema com segurança**. Você cuida do cadastro (doador e ONG), do login, do "continuar logado" e do "sair", no servidor e no app.

**Histórias:** HU01 (cadastro) e HU02 (login). **Requisitos:** RF01–RF07 ([docs/02](../../docs/02-requisitos.md)).

## Sua sequência

| # | Etapa | O que você entrega | Feito |
|---|---|---|---|
| 1 | Trilha 01 a 10 (com todos) | ambiente pronto e Sprint 0 rodando | [ ] |
| 2 | [11 — Backend: fundamentos](../../trilha/11-backend-fundamentos.md) | entender rotas, middlewares e camadas | [ ] |
| 3 | [12 — Backend: autenticação](../../trilha/12-backend-autenticacao.md) | `POST /auth/cadastro`, `POST /auth/login`, `GET /auth/me` + 5 testes | [ ] |
| 4 | [16 — App: fundamentos](../../trilha/16-app-fundamentos.md) | entender MVVM e a receita de tela | [ ] |
| 5 | [17 — App: login e cadastro](../../trilha/17-app-autenticacao.md) | telas de login e cadastro + 7 testes | [ ] |
| 6 | [21](../../trilha/21-integracao-e-testes.md) e [22](../../trilha/22-documentacao-e-entrega.md) | integração, revisão do `docs/08` (Autenticação) e `docs/17` | [ ] |

## Seus arquivos (só você cria e edita)

```text
desenvolvimento_app/backend/lib/auth/
desenvolvimento_app/backend/routes/auth/
desenvolvimento_app/backend/test/auth/
desenvolvimento_app/app/lib/features/auth/presentation/   (login_* e cadastro_*)
desenvolvimento_app/app/test/features/auth/
```

Você também é o "guardião" do `shared_models` (está no `CODEOWNERS`): se alguém precisar mudar um modelo, você revisa.

## Dependências

- **Você depende de:** só do Sprint 0. Comece o backend sem esperar ninguém.
- **Dependem de você:** todos, no **modo API** (sem login real, ninguém testa ponta a ponta). Enquanto isso, os colegas usam o modo Fake e o `gerar_token.dart`. Por isso, tente entregar o backend (etapa 12) primeiro, ainda no Sprint 1.

## Com quem você precisa se alinhar

| Com | Sobre | Quando |
|---|---|---|
| P4 | a localização do cadastro é o centro da busca e do mapa (ordem latitude, longitude; GPS do emulador) | antes da tela de cadastro |
| P2 e P5 | o botão **Sair** igual nas duas telas iniciais | antes das telas iniciais |
| todos | avisar quando o login do backend for mesclado (todos passam a testar no modo API) | no dia do merge |

Detalhes: [03 — Alinhamentos](../03-alinhamentos-entre-pessoas.md).

## O que você precisa saber explicar na apresentação

- Por que a senha **não é guardada** (hash bcrypt, sal) e como o login confere.
- O que é um **JWT**, o que tem dentro (só `uid` e `tipo`) e por que não colocar dados sensíveis.
- Por que o login errado sempre tem **a mesma mensagem**.
- Por que a **mesma validação** roda no app e no backend (`ValidadorUsuario`).
- Onde o token fica guardado no celular (`flutter_secure_storage` → Keystore).

## Dicas

- Seu primeiro PR pode ser só o repositório + o teste: PRs pequenos são revisados mais rápido.
- Use o `api.http` (seção AUTENTICAÇÃO) para testar cada rota assim que ela existir.
- Ao terminar, ajude a Pessoa 2 ou a 5 a testar no modo API.
