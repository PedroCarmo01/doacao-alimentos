# 21 — Integração e testes

> **Quem:** todos. **Tempo:** 1 semana (Sprint 3).
> **Pré-requisito:** os PRs das fatias (12 a 20) mesclados na `main`.

Até aqui, cada pessoa testou a **sua** parte, quase sempre no modo Fake. Agora juntamos tudo: o app real conversando com o backend real, com o banco real, do começo ao fim. É nesta semana que aparecem os problemas "entre as peças" — por isso ela existe no calendário.

## Vocabulário

| Termo | Em palavras simples |
|---|---|
| **Teste de unidade** | Testa **uma peça** sozinha (um Service, um ViewModel), com Fakes. Rápido. É o que fizemos até agora |
| **Teste de integração** | Testa **as peças juntas** (app + API + banco) |
| **Teste de ponta a ponta (E2E)** | Uma pessoa (ou robô) usa o sistema como o usuário final, do cadastro à retirada |
| **Regressão** | Algo que funcionava e quebrou por causa de uma mudança nova |
| **Cobertura** | Quanto do código foi executado pelos testes (em %) |
| **Bug report** | A issue que descreve um erro de forma que outra pessoa consiga reproduzir |

---

## Passo 1 — Atualizar todas as máquinas

Cada pessoa:

```powershell
git switch main
git pull
```

Depois, no VS Code (`Ctrl+Shift+P` → *Tasks: Run Task*):

1. **Tudo: baixar dependências (pub get)**
2. **Tudo: verificar antes do PR (format + analyze + test)** — tudo precisa passar na `main`
3. Rode o `database/schema.sql` de novo no Workbench (recria as tabelas) e a tarefa **Backend: recriar dados de exemplo (seed)**

> Se a `main` não passa na verificação, **pare tudo** e conserte primeiro. Ninguém abre PR novo em cima de uma `main` quebrada.

## Passo 2 — Ligar o modo API

1. Tarefa **Backend: iniciar (dart_frog dev)**. Espere `API rodando em http://127.0.0.1:8080`.
2. Confira no navegador: <http://localhost:8080/> deve mostrar `"banco":"conectado"`.
3. *Run and Debug* → **App — API local (emulador)** → `F5`.
4. Na tela inicial, o rodapé deve dizer **Servidor online**.

Para testar em **dois aparelhos ao mesmo tempo** (necessário para a concorrência e para o aviso de doação nova):

| Opção | Como |
|---|---|
| Dois emuladores | *Device Manager* do Android Studio → criar um segundo aparelho → abrir os dois. No VS Code, escolha o aparelho no canto inferior direito antes do `F5` |
| Emulador + celular físico | `ESCUTAR_NA_REDE=true` no `.env`, reinicie o backend, use o perfil **App — API local (celular físico)** com o IP do seu PC (`ipconfig` → "Endereço IPv4") |
| Emulador + Chrome | Perfil **App — Chrome (API local)** |

## Passo 3 — Roteiro de teste de ponta a ponta

Façam juntos, em chamada, com uma pessoa compartilhando a tela. Marquem cada linha. Se algo falhar, **não conserte na hora**: registre como issue (passo 5) e siga o roteiro.

> **Dica para a demonstração:** coloque `RESERVA_MINUTOS=2` no `.env` antes de começar, para ver a expiração.

| # | História | Passos | Esperado | OK? |
|---|---|---|---|---|
| 1 | HU01 | Cadastrar um doador novo, com "Usar minha localização" | Entra direto em "Minhas doações" vazia | |
| 2 | HU01 | Cadastrar uma ONG nova, a menos de 10 km do doador | Entra em "Doações próximas" | |
| 3 | HU02 | Fechar o app e abrir de novo (as duas contas) | Pula direto para o início do perfil | |
| 4 | HU02 | Sair; entrar com a senha errada | "E-mail ou senha incorretos." | |
| 5 | HU03 | Doador: nova doação com validade de ontem | Recusada: "Não é permitido doar alimentos vencidos." | |
| 6 | HU03 | Doador: nova doação sem a declaração | Recusada | |
| 7 | HU03 | Doador: nova doação válida | Aparece em "Minhas doações" como Disponível | |
| 8 | HU07 | ONG (com a tela aberta): esperar até 15 s | SnackBar "Nova doação perto de você!" e etiqueta NOVA | |
| 9 | HU06 | ONG: conferir a ordem da lista | Da mais perto para a mais longe, com a distância | |
| 10 | HU12 | ONG: abrir o mapa | Casa azul na ONG e marcador verde na doação nova | |
| 11 | HU08 | ONG: reservar | Contador regressivo | |
| 12 | HU08 | Doador: abrir a doação | "Reservada por <ONG>" com contador | |
| 13 | HU08 | Duas ONGs reservando a mesma doação ao mesmo tempo | Só uma consegue; a outra vê "Outra ONG reservou..." | |
| 14 | HU09 | Esperar o prazo (2 min) sem fazer nada | A reserva vira Expirada; a doação volta para a lista da ONG | |
| 15 | HU11 | ONG: reservar de novo e "Desistir" | A doação volta a ficar disponível | |
| 16 | HU10 | ONG: reservar e "Confirmar retirada" | "Retirada confirmada"; doação Concluída para o doador | |
| 17 | HU13 | ONG: Minhas reservas → Histórico | Expirada, Cancelada e Retirada aparecem | |
| 18 | HU05 | Doador: cancelar uma doação disponível | Status Cancelada; a ONG não a vê mais | |
| 19 | HU05 | Doador: tentar cancelar uma reservada | O botão não aparece | |
| 20 | — | Desligar o backend com o app aberto e puxar a lista | Mensagem "Não foi possível falar com o servidor..." | |
| 21 | — | Ligar o backend de novo e "Tentar novamente" | Volta a funcionar | |

Salve esta tabela preenchida em `docs/relatorio-de-testes.md` (com a data e quem participou). Ela é uma **evidência** de testes para a entrega.

## Passo 4 — Testes automatizados de todo o projeto

```powershell
cd desenvolvimento_app\shared_models; dart test
cd ..\backend; dart test
cd ..\app; flutter test
```

Ou a tarefa **Tudo: verificar antes do PR**. Contagem esperada (aproximada):

| Pacote | Testes |
|---|---|
| `shared_models` | os que já vieram prontos |
| `backend` | `core` + 5 (auth) + 7 (doações) + 5 (proximidade) + 8 (reservas) |
| `app` | `core`/`data`/`escolha_perfil` + 7 (auth) + 7 (doador) + 6 (ONG) + 3 (mapa) |

### Cobertura (opcional, mas bonito na apresentação)

```powershell
cd desenvolvimento_app\app
flutter test --coverage
```

Isso gera `coverage/lcov.info` (já está no `.gitignore`). Para ver em cores dentro do VS Code, instale a extensão **Coverage Gutters** (`ryanluker.vscode-coverage-gutters`) e clique em *Watch* na barra de baixo: linhas verdes foram testadas, vermelhas não.

No backend:

```powershell
cd desenvolvimento_app\backend
dart pub global activate coverage
dart pub global run coverage:test_with_coverage
```

> **Meta realista:** não persiga 100%. O importante é que **as regras de negócio** (Services e ViewModels) estejam cobertas. Telas e SQL são verificados pelo roteiro do passo 3.

## Passo 5 — Registrar bugs como issues

Para cada linha que falhou no passo 3, abra uma issue com o modelo **Bug** (`.github/ISSUE_TEMPLATE/bug.md`):

```markdown
**O que aconteceu:** ao reservar, o contador mostra 05:00:00 em vez de 02:00:00.
**Como reproduzir:**
1. RESERVA_MINUTOS=2 no .env
2. Entrar como maosamigas@exemplo.com
3. Reservar "Pães do dia anterior"
**Esperado:** 00:02:00
**Onde:** app (emulador Pixel 7, Android 14), modo API
**Print/log:** (cole aqui)
```

- Coloque o label `bug` e o da pessoa dona da fatia (`pessoa-3`, por exemplo).
- A correção vai numa branch `fix/<numero>-descricao` e num PR com `Fecha #<numero>`.
- **Escreva um teste que falha por causa do bug antes de corrigir.** Depois da correção, ele passa e o bug nunca mais volta sem ninguém perceber (teste de regressão).

## Passo 6 — Acessibilidade e textos (revisão rápida)

Uma pessoa passa por todas as telas conferindo:

- [ ] Todos os botões de ícone têm `tooltip` (o leitor de tela lê o tooltip)
- [ ] A informação não depende só de cor (as etiquetas de status têm texto)
- [ ] Os textos estão em português, sem "Lorem ipsum", "TODO" ou mensagem técnica para o usuário
- [ ] Com a fonte do Android no tamanho máximo (*Configurações > Tela > Tamanho da fonte*), nada fica cortado de forma que impeça o uso
- [ ] Ative o **TalkBack** no emulador por 5 minutos e tente fazer login e reservar

## Passo 7 — Congelar as funcionalidades

No fim do Sprint 3 (início da semana 8), o grupo combina o **congelamento**: só entram correções de bugs e documentação. Nenhuma funcionalidade nova. Crie a tag:

```powershell
git switch main
git pull
git tag -a v0.9.0 -m "Sprint 3: integração concluída, funcionalidades congeladas"
git push origin v0.9.0
```

## O que pode dar errado

| Sintoma | Causa provável | Solução |
|---|---|---|
| Funciona no Fake e falha na API | Diferença entre o `BancoFake` e o backend | Compare os códigos de erro e o JSON (`api.http`) com o que a tela espera; corrija o lado errado e acrescente um teste |
| `Rota não encontrada no servidor` | Backend antigo rodando ou PR não mesclado | `git pull`, pare e reinicie o backend |
| Horários 3 h diferentes entre doador e ONG | Algum lugar usou `DateTime.now()` sem `toUtc()` ou mostrou UTC sem `Formatador` | Procure por `DateTime.now()` no código: só o `RelogioSistema` pode usar |
| Celular físico não conecta | Firewall do Windows ou `ESCUTAR_NA_REDE=false` | [docs/22-troubleshooting](../docs/22-troubleshooting.md) |
| Testes passam na sua máquina e falham na CI | Arquivo não commitado ou `dart format` não rodado | Rode a tarefa "verificar antes do PR" e `git status` |

## Checklist

- [ ] As 21 linhas do roteiro passaram (ou viraram issues)
- [ ] `docs/relatorio-de-testes.md` com o roteiro preenchido
- [ ] Todos os testes automatizados passando e CI verde
- [ ] Bugs encontrados corrigidos com teste de regressão
- [ ] Revisão de acessibilidade feita
- [ ] Tag `v0.9.0` publicada

Próximo: [22 — Documentação e entrega no GitHub](22-documentacao-e-entrega.md).
