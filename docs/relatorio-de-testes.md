# Relatório de testes

Como o grupo garante que o app faz o que a especificação do grupo pede. São três camadas:

| Camada | O que é | Como rodar | Resultado (31/10/2026) |
|---|---|---|---|
| **1. Testes automatizados** | regras testadas sem banco nem celular (`RelogioFixo` para "avançar o tempo") | tarefa **Tudo: verificar antes do PR** | `shared_models` 75 · backend 129 · app 103 — **todos passando** |
| **2. Roteiro de ponta a ponta** | um script que percorre as regras contra o **servidor de verdade** (MySQL) | `dart run tool/seed.dart` e depois `dart run tool/roteiro_ponta_a_ponta.dart`, com o servidor rodando | **32 passos OK, 0 falhas** (rodado 2 vezes seguidas) |
| **3. Passo a passo manual** | o que só dá para ver no celular (telas, notificação, tempo passando) | seção [Roteiro manual](#roteiro-manual) abaixo | conferido no emulador Pixel 7 (Android 14), etapa por etapa |

## Cobertura das regras de negócio

"Testes" = quantos testes automatizados têm o código da regra no nome (procure por `'RN..:` nos três pacotes). "Roteiro" = o passo do script de ponta a ponta.

### Contas

| RN | Regra (resumo) | Testes | Roteiro | Manual |
|---|---|---|---|---|
| RN01 | conta é ONG **ou** doador | 2 | — | 1 |
| RN02 | CNPJ válido (ONG); CPF só para feirante/produtor/outro | 13 | CNPJ com dígitos errados é recusado | 1 |
| RN03 | CNPJ ativo na BrasilAPI; ONG precisa ser sem fins lucrativos; API fora → pendente | 15 | — (depende da internet) | 1 |
| RN04 | e-mail e documento únicos | 4 | — | 1 |
| RN05 | login vale 30 dias; o app entra sozinho | 5 | login dos 6 usuários; senha errada | 2 |

### Doações

| RN | Regra (resumo) | Testes | Roteiro | Manual |
|---|---|---|---|---|
| RN10 | só doador publica; validade ≥ hoje; declaração | 10 | vencida recusada; ONG não publica; padaria publica | 3 |
| RN11 | ONGs no raio e com busca ativa veem e são avisadas | 3 + grupo "RN11: doação nova" | a ONG perto vê e é avisada; a de 45 km não | 3 |
| RN12 | editar/cancelar disponível; reservada pede motivo, sem punir a ONG | 12 | sem motivo recusado; com motivo aceito | 5 |
| RN13 | janela encerrada → expirada | 2 | — (depende do tempo) | 5 |

### Aceite e retirada

| RN | Regra (resumo) | Testes | Roteiro | Manual |
|---|---|---|---|---|
| RN20 | a primeira ONG fica com a doação | 4 | duas ONGs ao mesmo tempo: só uma fica | 4 |
| RN21 | prazo = menor entre agora + 60 min e o fim da janela | 5 | — (depende do tempo) | 4 |
| RN22 | prazo vencido/desistência: a doação volta e a ONG fica bloqueada | 6 | — (depende do tempo) | 6 |
| RN23 | desistir em até 5 min não conta | 3 | desistir em menos de 5 min não conta | 4 |
| RN24 | 3 desistências em 30 dias → 48 h de suspensão | 9 | ONG suspensa não aceita | 6 |
| RN25 | no máximo 2 retiradas ao mesmo tempo | 3 | a 3ª retirada é recusada | 4 |
| RN26 | código de 4 dígitos só para a ONG | 3 | a ONG recebe o código; o doador não | 4 |
| RN27 | o doador digita o código; 5 erros → 10 min | 11 | código errado recusado; certo conclui | 4 |
| RN28 | "A ONG não compareceu" depois do prazo | 3 | — (depende do tempo) | 6 |
| RN29 | expira a cada 30 s e antes de aceitar | 2 | — (depende do tempo) | 6 |

### Chat e Comunidade

| RN | Regra (resumo) | Testes | Roteiro | Manual |
|---|---|---|---|---|
| RN30 | o chat é só do doador e da ONG da retirada | 7 | a ONG conversa; outra ONG não lê | 7 |
| RN31 | depois da retirada, só leitura por 7 dias | 3 | depois da retirada o chat é só leitura | 7 |
| RN40 | qualquer conta publica; texto obrigatório; até 3 fotos | 8 | publicar sobre uma doação concluída | 8 |
| RN41 | cada conta apoia uma vez | 4 | apoiar duas vezes conta uma | 8 |
| RN42 | 3 denúncias de contas diferentes escondem | 3 | 3 denúncias escondem a publicação | 8 |

Também cobertos: a seção 9 (quem recebe cada notificação: testes em `central_de_notificacoes_test.dart`, `notificacoes_test.dart` e o passo "o doador foi avisado do aceite") e o painel de impacto (passo "o painel somou as famílias e os kg").

## Roteiro manual

**Preparação:** **Backend: recriar dados de exemplo (seed)**. No `backend/.env`, `RESERVA_MINUTOS=2` (para ver o tempo passar). **Backend: iniciar**. Dois emuladores (ou emulador + celular) com **App — API local**. Senha de todos: `senha123`. No fim, volte `RESERVA_MINUTOS=60`.

| # | Passos | Resultado esperado |
|---|---|---|
| 1 | Cadastro de ONG com CPF; depois, com o CNPJ de outra conta; depois, com um CNPJ válido | "ONG precisa de CNPJ"; "já cadastrado"; conta criada (verificada ou pendente, conforme a BrasilAPI) |
| 2 | Entrar com `mercado@`, fechar o app (tirar dos recentes) e abrir de novo | entra sozinho, sem pedir senha |
| 3 | `padaria@`: **Doar** com 2 fotos; tentar validade de ontem; tentar sem a declaração | publica e diz quantas ONGs foram avisadas; o calendário não deixa dia passado; pede a declaração |
| 4 | `maosamigas@` com o app **minimizado**; a padaria publica | em até 15 s o celular da ONG apita "Doação nova a 1,2 km…"; tocar abre o detalhe. `distante@` não vê a doação |
| 5 | `mercado@`: editar uma doação disponível; cancelar outra; cancelar a reservada ("Cestas") sem e com motivo | edita; cancela; sem motivo não deixa; com motivo cancela e a ONG recebe "O doador cancelou… Motivo: …" |
| 6 | `pratocheio@` (2 desistências): **Vou retirar** e esperar 2 min | o aviso diz "mais uma desistência e sua conta será suspensa"; o prazo acaba: a doação volta para as outras ONGs, o doador e a ONG são avisados, e o botão fica "Você está suspensa até…" |
| 7 | `maosamigas@` (faixa laranja) → **Ver** → **Conversar**; `mercado@` responde; `mercado@` confirma com `4821` | mensagens nos dois lados em até 4 s, com "✓ lida"; a T23 vira "Retirada confirmada!"; o chat fica só leitura |
| 8 | `maosamigas@` → **Comunidade** → **Publicar** ligada a "Arroz e feijão", 15 famílias; `mercado@` apoia; 3 contas denunciam outra publicação | o painel sobe 15 famílias; a ONG recebe "Apoio na Comunidade"; a publicação denunciada some |
| 9 | **Perfil**: estatísticas, editar telefone, raio, desligar "Mensagens do chat" | números certos; dados salvos; com "Mensagens" desligado, a mensagem nova não apita |
| 10 | **Plano B:** desligar o servidor e abrir o APK do modo Fake | o app funciona com os mesmos dados de exemplo, sem servidor |

## O que não é testado automaticamente

- A consulta real à **BrasilAPI** (depende da internet): testada com uma versão falsa (`ConsultaCnpjFake`) e à mão no cadastro.
- A **notificação do Android** e o **GPS**: testados com versões em memória (`MostradorEmMemoria`, `LocalizacaoServiceFake`) e à mão no emulador.
- O **tempo de verdade passando** (prazos de 60 min): os testes "avançam o relógio" (`RelogioFixo`); à mão, com `RESERVA_MINUTOS=2`.
