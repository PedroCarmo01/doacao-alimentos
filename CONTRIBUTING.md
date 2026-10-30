# Como contribuir

Regras curtas para 5 pessoas trabalharem no mesmo repositório sem atrapalhar umas às outras. O passo a passo detalhado (com comandos e prints do VS Code) está em [trilha/04 — Git e GitHub do zero](trilha/04-git-e-github-do-zero.md).

## Fluxo de trabalho

1. Pegue (ou crie) uma **issue** no quadro do GitHub Projects e atribua a você.
2. Atualize a `main` e crie uma **branch** a partir dela:
   ```powershell
   git switch main
   git pull
   git switch -c feat/12-login-backend
   ```
3. Programe em **commits pequenos**, seguindo a convenção abaixo.
4. Antes de abrir o PR, rode a tarefa do VS Code **"Tudo: verificar antes do PR"** (formatação, análise e testes).
5. Envie a branch e abra o **Pull Request** com "Fecha #12" na descrição.
6. Um colega revisa. Ajuste o que for pedido.
7. Com a aprovação e a CI verde, faça **Squash and merge** e apague a branch.

## Nomes de branch

`tipo/numero-da-issue-descricao-curta`, por exemplo `feat/12-login-backend`, `fix/30-contador-negativo`, `docs/41-manual-usuario`.

## Mensagens de commit (Conventional Commits)

```text
feat: adiciona rota de login
fix: corrige expiração de reserva no fuso -3
test: cobre reserva concorrente no ReservaService
docs: atualiza contrato de GET /proximas
refactor: extrai validação de janela para o shared_models
chore: atualiza pubspec.lock
```

Verbo no presente, em português, e uma ideia por commit.

## Arquivos de fundação

Estes arquivos são usados por todos. Só mude em um PR **combinado com o grupo**:

- `desenvolvimento_app/app/lib/core/**` e `lib/data/**`
- `desenvolvimento_app/app/lib/app.dart`, `lib/main.dart`
- `desenvolvimento_app/backend/main.dart`, `routes/_middleware.dart`, `routes/index.dart`, `lib/core/**`
- todos os `pubspec.yaml` e `pubspec.lock`
- `database/schema.sql` (mudanças de banco entram como migração; veja `database/migracoes/README.md`)

## Definição de Pronto

Uma tarefa só está pronta quando:

- [ ] faz o que os critérios de aceite da issue pedem;
- [ ] tem testes para as regras de negócio;
- [ ] passa na CI (formatação, análise e testes);
- [ ] foi revisada e aprovada por outra pessoa;
- [ ] não contém `.env`, senhas ou tokens;
- [ ] a documentação foi atualizada, se necessário.

## Nunca

- Commitar direto na `main`.
- Subir o `.env`.
- Usar `git push --force` na `main`.
- Editar o arquivo de outra pessoa sem combinar.
