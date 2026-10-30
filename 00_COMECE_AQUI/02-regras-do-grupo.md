# 02 — Regras do grupo

Combinados simples para o trabalho fluir. Não é burocracia: são hábitos que evitam código perdido, conflitos e gente travada em silêncio.

## Desenvolvimento (Git e GitHub)

1. **Nunca programe direto na `main`.** Cada tarefa tem a sua branch (`feat/12-login-backend`).
2. **Toda mudança entra por Pull Request**, revisado por pelo menos 1 colega, com a CI verde.
3. **PRs pequenos e frequentes.** 5 PRs pequenos são melhores que 1 gigante.
4. **`git pull` antes de começar** a trabalhar no dia.
5. **Crie arquivos só nas suas pastas.** Os arquivos de **fundação** (`core/`, `data/`, roteador, `main.dart`, `pubspec.yaml`) só mudam em PR combinado com o grupo.
6. **Nunca suba o `.env`**, senhas ou tokens.
7. Antes de abrir o PR, rode a tarefa do VS Code **"Tudo: verificar antes do PR"**.

Passo a passo: [trilha/04](../trilha/04-git-e-github-do-zero.md). Regras curtas: [CONTRIBUTING.md](../CONTRIBUTING.md).

### Mensagens de commit

```text
feat:     nova funcionalidade        feat(auth): tela de login
fix:      correção de bug            fix(reservas): prazo passava da janela
test:     testes                     test(doacoes): cobre doação vencida
docs:     documentação               docs: manual do usuário da ONG
refactor: melhoria sem mudar o comportamento
chore:    configuração
```

## Ritmo (Scrum adaptado)

| Quando | O quê | Duração |
|---|---|---|
| Início de cada sprint (2 semanas) | **Planning**: escolher as issues da sprint | 1 h |
| Todo dia, até o horário combinado | **Daily** no grupo: *fiz / vou fazer / travei em* (3 linhas) | 2 min |
| Fim de cada sprint | **Review**: cada um mostra a sua parte funcionando | 30 min |
| Logo depois da review | **Retrospectiva**: manter / melhorar / parar | 15 min |

Detalhes: [trilha/02](../trilha/02-processo-e-planejamento.md).

## Convivência

1. **Travou? Fale.** Mais de 1 hora no mesmo erro = pedir ajuda.
2. **A nota é do grupo.** Quem terminar antes ajuda quem está atrasado (em **dupla**, sem pegar o teclado do colega: o histórico precisa mostrar quem fez).
3. **Revisão é sobre o código, não sobre a pessoa.** Comente com sugestão concreta e gentileza.
4. **Decisões grandes** (trocar biblioteca, mudar estrutura) são combinadas no grupo e registradas num ADR ([docs/adr](../docs/adr/README.md)).
5. **Cada um entende o próprio código.** O código da trilha está pronto para ajudar, mas na apresentação qualquer pessoa pode ser perguntada sobre a sua parte.

## Como pedir ajuda

Mande no grupo:

1. o que você estava tentando fazer;
2. o comando exato que rodou;
3. a **mensagem de erro completa** (texto ou print);
4. o que você já tentou.

Antes, procure a mensagem em [docs/22 — Troubleshooting](../docs/22-troubleshooting.md) e na tabela "O que pode dar errado" da etapa da trilha.

## Definição de "pronto"

Uma tarefa só está pronta quando:

- [ ] faz o que a issue pede (critérios de aceite);
- [ ] tem testes para as regras de negócio;
- [ ] passou na CI;
- [ ] foi revisada e aprovada por outra pessoa;
- [ ] não tem `.env`, senha ou token;
- [ ] a documentação foi atualizada, se necessário.

## Nunca

- Subir código quebrado para a `main`.
- Deixar tudo para a última semana.
- Sumir sem avisar que travou.
- Mexer na parte de outra pessoa sem combinar.
- Commitar o `.env`.
