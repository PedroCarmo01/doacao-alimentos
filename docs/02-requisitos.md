# 02 — Requisitos

Cada requisito tem um identificador para ser citado em issues, PRs e testes. As **histórias de usuário** (HU01 a HU13) que implementam estes requisitos estão na [trilha/02](../trilha/02-processo-e-planejamento.md).

## Requisitos funcionais (RF)

### Autenticação e cadastro

| ID | Requisito | Prioridade | HU | Onde |
|---|---|---|---|---|
| RF01 | Cadastro de usuário do tipo **doador**, com dados da organização e localização | MVP | HU01 | trilha 12 e 17 |
| RF02 | Cadastro de usuário do tipo **ONG**, com dados da organização e localização | MVP | HU01 | trilha 12 e 17 |
| RF03 | Login com e-mail e senha | MVP | HU02 | trilha 12 e 17 |
| RF04 | Após o login, abrir a área correta do tipo de usuário | MVP | HU02 | trilha 17 |
| RF05 | Senhas guardadas só como **hash bcrypt** | MVP | HU01 | trilha 12 |
| RF06 | Sair (logout) | MVP | HU02 | trilha 17 |
| RF07 | Continuar logado ao reabrir o app (token salvo e validado em `GET /auth/me`) | MVP | HU02 | trilha 12 e 17 |
| RF08 | Recuperação de senha | Futuro | — | — |

### Doações (doador)

| ID | Requisito | Prioridade | HU | Onde |
|---|---|---|---|---|
| RF09 | Publicar doação com título, categoria, quantidade, validade, janela de retirada e descrição opcional | MVP | HU03 | trilha 13 e 18 |
| RF10 | **Recusar alimento vencido**: validade não pode ser anterior a hoje (no fuso do Brasil) | MVP | HU03 | `ValidadorDoacao` |
| RF11 | **Declaração obrigatória** de que os alimentos estão próprios para consumo | MVP | HU03 | `ValidadorDoacao` |
| RF12 | A doação usa a localização do perfil do doador se nenhuma for informada | MVP | HU03 | trilha 13 |
| RF13 | Listar as próprias doações com o status | MVP | HU04 | trilha 13 e 18 |
| RF14 | Cancelar doação ainda **não reservada** | MVP | HU05 | trilha 13 e 18 |
| RF15 | Ver qual ONG reservou e até quando | MVP | HU08 | trilha 13 e 18 |

### Doações e reservas (ONG)

| ID | Requisito | Prioridade | HU | Onde |
|---|---|---|---|---|
| RF16 | Ver doações **disponíveis** num raio da localização cadastrada, da mais perto para a mais longe, com a distância | MVP | HU06 | trilha 14 e 19 |
| RF17 | Raio configurável (padrão 10 km; limitado entre 0,5 e 50 km) | MVP | HU06 | trilha 14 |
| RF18 | **Aviso** de doação nova com o app aberto (atualização a cada 15 s) | MVP | HU07 | trilha 19 |
| RF19 | Ver as doações próximas num **mapa** | MVP | HU12 | trilha 20 |
| RF20 | **Reservar** uma doação disponível | MVP | HU08 | trilha 15 e 19 |
| RF21 | Ver o **prazo** da reserva com contador regressivo | MVP | HU08 | trilha 19 |
| RF22 | Desistir da reserva (a doação volta a ficar disponível) | MVP | HU11 | trilha 15 e 19 |
| RF23 | Ver as reservas ativas e o **histórico** | MVP | HU13 | trilha 15 e 19 |

### Regras do ciclo de vida

| ID | Requisito | Prioridade | HU | Onde |
|---|---|---|---|---|
| RF24 | Uma doação tem **no máximo uma reserva ativa** (garantido também pelo banco) | MVP | HU08 | trilha 15, `schema.sql` |
| RF25 | Prazo da reserva = `mínimo(agora + RESERVA_MINUTOS, fim da janela)` | MVP | HU08 | trilha 15 |
| RF26 | Reserva vencida **expira automaticamente** e a doação volta a `disponivel` | MVP | HU09 | trilha 15 |
| RF27 | Confirmar retirada (ONG dona da reserva **ou** doador dono da doação) | MVP | HU10 | trilha 15, 18 e 19 |
| RF28 | Nada é apagado: registros mudam de **status** (histórico preservado) | MVP | — | `schema.sql` |

## Requisitos não funcionais (RNF)

| ID | Requisito | Como é atendido |
|---|---|---|
| RNF01 | App para **Android** (iOS desejável, não obrigatório) | Flutter; `flutter create --platforms android` (trilha 10) |
| RNF02 | Respostas da API em menos de 2 s em condições normais | Consultas com índices; busca de proximidade em duas etapas |
| RNF03 | Comunicação em **JSON** sobre HTTP, UTF-8 | Contratos do `shared_models`; `ApiClient` decodifica UTF-8 |
| RNF04 | Segredos fora do Git | `.env` no `.gitignore`; `.env.example` sem segredos |
| RNF05 | Autenticação com **JWT** com expiração (padrão 12 h) | `TokenService` |
| RNF06 | Erros padronizados com mensagem em português | `{"erro": {"codigo", "mensagem"}}`; middleware `tratarErros` |
| RNF07 | Testes automáticos das regras de negócio críticas | Testes de Services e ViewModels; CI a cada PR |
| RNF08 | Código orientado a objetos, em camadas | MVVM no app; rota → service → repository no backend ([trilha/07](../trilha/07-arquitetura-e-poo.md)) |
| RNF09 | Interface em português, acessível (texto além da cor, tooltips, leitor de tela) | Revisão na trilha 21 |
| RNF10 | Datas consistentes entre aparelhos | Tudo em UTC no banco; conversão só na tela ([ADR-010](adr/ADR-010-datas-utc-relogio.md)) |
| RNF11 | Funciona sem backend para desenvolvimento e demonstração | Modo Fake (`USAR_FAKE=true`) |

## Fora de escopo (nesta versão)

- Notificação **push** com o app fechado (Firebase Cloud Messaging).
- WebSocket ([apêndice B](../trilha/apendice-b-websocket-opcional.md)).
- Pagamentos, logística de entrega ou rotas (a retirada é presencial).
- Perfil de administrador, moderação e relatórios.
- Avaliações entre doadores e ONGs; chat.
- Fotos das doações.

Esses itens estão no [roadmap](20-roadmap.md).
