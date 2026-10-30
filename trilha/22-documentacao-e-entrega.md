# 22 — Documentação e entrega no GitHub

> **Quem:** todos (o líder coordena). **Tempo:** 3 dias (semana 8).
> **Pré-requisito:** [21 — Integração e testes](21-integracao-e-testes.md) concluída e tag `v0.9.0` publicada.

O professor vai avaliar **o que está no GitHub**: o código, o histórico de commits e PRs de cada pessoa, a documentação e a release. Esta etapa deixa tudo isso apresentável e prepara a apresentação.

## Vocabulário

| Termo | Em palavras simples |
|---|---|
| **README** | A "capa" do repositório: é a primeira coisa que aparece no GitHub |
| **Tag** | Um marcador com nome (`v1.0.0`) num commit específico, para sempre |
| **Release** | Uma tag com página bonita no GitHub: notas, arquivos para baixar (o APK) |
| **APK** | O arquivo instalável do app Android |
| **Versionamento semântico (SemVer)** | `MAIOR.MENOR.CORREÇÃO`: `1.0.0` é a primeira versão completa; `1.0.1` corrige um bug |

---

## Passo 1 — Distribuir as tarefas (todo mundo escreve um pouco)

Cada pessoa abre **uma issue e um PR** com a sua parte da documentação. Assim, todos aparecem no histórico da documentação também.

| Pessoa | Entrega |
|---|---|
| Líder | `README.md` final (passo 2), release (passo 5), roteiro da apresentação (passo 7) |
| P1 | Seção "Autenticação" em `docs/08-backend-apis.md` conferida com o código; `docs/17-seguranca.md` revisado |
| P2 | Manual do usuário — doador (`docs/manual-do-usuario.md`, seção Doador, com prints) |
| P3 | `docs/12-partes-complexas.md`: concorrência e expiração com as suas palavras; seção Reservas do `docs/08` conferida |
| P4 | `docs/07-banco-de-dados.md` e `database/` conferidos; CI verde; APK de release (passo 4) |
| P5 | Manual do usuário — ONG (mesma página, seção ONG, com prints); `docs/relatorio-de-testes.md` da etapa 21 |

> **Prints:** no emulador, use o ícone de câmera da barra lateral. Salve em `docs/img/` com nomes como `ong-detalhe-reservado.png` e use no Markdown: `![Detalhe reservado](img/ong-detalhe-reservado.png)`.

## Passo 2 — O README final

Abra o `README.md` da raiz e confira se ele responde, nesta ordem:

1. **O que é** o projeto, em 2 ou 3 frases (e os ODS 2 e 12).
2. **Prints** das telas principais (3 ou 4 imagens lado a lado).
3. **Tecnologias** e por quê (link para `docs/adr/`).
4. **Como rodar** em 5 passos curtos (link para a [trilha/03](03-ambiente-windows-vscode.md) e [10](10-sprint-0-esqueleto-funcional.md)).
5. **Usuários de teste** (os e-mails do seed e a senha `senha123`).
6. **Estrutura de pastas** resumida.
7. **Equipe**: nome, GitHub e a fatia de cada pessoa.
8. **Uso de IA** (passo 3).
9. **Licença** (se o professor pedir).

Teste o README com alguém de fora do grupo: a pessoa entende o que é o projeto em 1 minuto?

## Passo 3 — Declarar o uso de IA

A base do projeto (fundação, documentação e a trilha com código de exemplo) foi gerada com apoio de ferramentas de IA. **Confiram a política da disciplina** e, se for exigido ou recomendado, deixem isso claro no README. Sugestão de texto:

```markdown
## Uso de inteligência artificial

A estrutura inicial do repositório, parte da documentação e os exemplos de
código da pasta `trilha/` foram produzidos com apoio de ferramentas de IA
generativa e revisados pelo grupo. Cada integrante implementou, testou e é
capaz de explicar o código da própria fatia, conforme o histórico de commits
e Pull Requests.
```

> Isso também é o motivo de a trilha insistir em **digitar e entender**: na apresentação, o professor pode pedir que qualquer pessoa explique qualquer trecho da sua fatia.

## Passo 4 — Gerar o APK

A Pessoa 4 gera o APK de **release** (versão final, otimizada). Antes, decida para onde o APK vai apontar:

| Cenário | `API_URL` |
|---|---|
| Apresentação com o backend no notebook do grupo, na mesma rede Wi-Fi | `http://<IP do notebook>:8080` (e `ESCUTAR_NA_REDE=true`) |
| Só demonstração offline | use `USAR_FAKE=true` |
| Backend publicado na internet (opcional, [docs/19](../docs/19-deploy.md)) | `https://...` |

```powershell
cd desenvolvimento_app\app
flutter build apk --release --dart-define=USAR_FAKE=true
```

O arquivo fica em `build\app\outputs\flutter-apk\app-release.apk`.

> **Atenção ao HTTP:** o build de release **bloqueia** `http://` (configuramos o "cleartext" só no debug, etapa 10). Para um APK de release apontando para `http://<IP>`, a opção mais simples é apresentar com o **build de debug** (`flutter build apk --debug --dart-define=API_URL=http://<IP>:8080`). Para a versão "de verdade", use HTTPS ([docs/19](../docs/19-deploy.md)).

> O `build/` está no `.gitignore`: o APK **não** vai para o Git, vai para a **release** (passo 5).

## Passo 5 — Versão 1.0.0 e release no GitHub

1. Atualize o `CHANGELOG.md`: mova os itens de "Não lançado" para `## [1.0.0] — <data>`.
2. Mescle esse PR. Depois, na `main` atualizada:

```powershell
git switch main
git pull
git tag -a v1.0.0 -m "Versão 1.0.0: entrega final"
git push origin v1.0.0
```

3. No GitHub: aba **Releases** → **Draft a new release** → escolha a tag `v1.0.0`.
4. Título: `v1.0.0 — Entrega final`. Clique em **Generate release notes** (o GitHub lista os PRs e os autores).
5. Arraste o `app-release.apk` para a área de anexos.
6. **Publish release**.

## Passo 6 — Dar acesso ao professor

1. *Settings → Collaborators → Add people* → usuário do GitHub do professor, com permissão **Read** (ou a que ele pedir).
2. Se o repositório for ficar público depois da avaliação, revise antes: nenhum `.env`, senha ou dado pessoal.
3. Confira que a aba **Insights → Contributors** mostra os 5 integrantes com commits.

## Passo 7 — Roteiro da apresentação (15 a 20 min)

| Tempo | Quem | O quê |
|---|---|---|
| 2 min | Líder | Problema (fome x desperdício), ODS 2 e 12, solução em uma frase |
| 3 min | P1 | Arquitetura: monorepo, `shared_models`, MVVM no app, camadas no backend (use os diagramas da [trilha/07](07-arquitetura-e-poo.md)) |
| 2 min | P1 | Demo: cadastro e login; onde fica o token; por que a senha não é guardada |
| 2 min | P2 | Demo: nova doação (validade e declaração), minhas doações |
| 3 min | P5 + P3 | Demo: ONG vê a doação **nova** aparecer; reserva com contador; **duas ONGs ao mesmo tempo** |
| 2 min | P3 | Explicação: transação, `FOR UPDATE`, índice único; **reserva expirando sozinha** (prazo de 2 min) |
| 2 min | P4 | Demo: mapa; explicação da busca por proximidade em duas etapas |
| 2 min | P4 | GitHub: quadro do Projects, PRs revisados, CI verde, release |
| 2 min | Todos | Testes (números da etapa 21), o que fariam a seguir (push real, WebSocket, fotos) |

**Ensaiem pelo menos duas vezes** com o cronômetro. Tenham um **plano B**: o APK no modo Fake instalado em um celular, caso a rede da faculdade não colabore.

Perguntas que o professor provavelmente vai fazer:

- Onde estão os quatro pilares da POO no projeto? ([trilha/07](07-arquitetura-e-poo.md))
- O que acontece se duas ONGs reservarem ao mesmo tempo?
- Por que as datas ficam em UTC?
- Por que não usaram Docker / Riverpod / WebSocket? (ADRs)
- Como vocês dividiram o trabalho e resolveram conflitos?
- Mostre um teste e explique o que ele prova.

## Passo 8 — Limpeza final

- [ ] Apagar branches antigas no GitHub (*Branches → ícone da lixeira*)
- [ ] Nenhum `TODO(` esquecido no código (busque com `Ctrl+Shift+F`), exceto os combinados
- [ ] `AppConfig.nomeApp` com o nome definitivo do app
- [ ] Issues fechadas ou com o label `futuro`
- [ ] Quadro do Projects com tudo em **Pronto**

## Checklist final da entrega

- [ ] README completo, com prints e equipe
- [ ] Uso de IA declarado (se exigido)
- [ ] `docs/manual-do-usuario.md` e `docs/relatorio-de-testes.md`
- [ ] `CHANGELOG.md` com a versão 1.0.0
- [ ] Tag `v1.0.0` e release com o APK
- [ ] Professor com acesso ao repositório
- [ ] Os 5 integrantes aparecem em *Insights → Contributors*
- [ ] Apresentação ensaiada duas vezes, com plano B

Parabéns: vocês construíram um sistema completo, do banco à tela, em equipe, com o mesmo processo usado em empresas.

Consulta rápida de comandos: [apêndice C](apendice-c-comandos.md).
