# 01 — Primeira reunião (kickoff)

Roteiro pronto para a **primeira reunião** do grupo (cerca de 1 hora, de preferência por chamada com tela compartilhada). Ao final, todos saem sabendo **quem faz o quê** e **o que fazer na primeira semana**.

## Antes da reunião (líder)

- [ ] Ler o [README desta pasta](README.md) e a [trilha/01](../trilha/01-entendendo-o-projeto.md)
- [ ] Pedir para todos abrirem esta pasta antes da chamada

## Pauta

### 1. O projeto (10 min)

Compartilhe o [README desta pasta](README.md), seções 1 e 2:

- o que é o app ("iFood da doação") e os ODS 2 e 12;
- o ciclo: anúncio → reserva com prazo → retirada **ou** expiração;
- **já existe uma fundação pronta** e a trilha traz o código de cada parte, explicado.

Pergunte: *todos entenderam a ideia? alguma dúvida do conceito?*

### 2. Como vamos trabalhar (10 min)

Leiam juntos as [regras do grupo](02-regras-do-grupo.md). Destaques:

- ninguém programa direto na `main`: cada tarefa numa **branch** + **Pull Request** revisado;
- cada pessoa cria arquivos **só nas próprias pastas**;
- travou mais de 1 hora? **pede ajuda** no grupo.

### 3. Dividir as 5 pessoas (15 min)

| Pessoa | Parte | Perfil que combina | Guia |
|---|---|---|---|
| 1 | Login e cadastro (backend + app) | quem quer entender segurança (senha, token) | [pessoa-1](pessoas/pessoa-1-autenticacao.md) |
| 2 | Doador (backend + app) | quem gosta de formulários e regras | [pessoa-2](pessoas/pessoa-2-doador.md) |
| 3 | Reservas e expiração (backend) | quem gosta de lógica e banco de dados (é a parte mais desafiadora) | [pessoa-3](pessoas/pessoa-3-reservas.md) |
| 4 | Infraestrutura, proximidade e mapa | quem é organizado e gosta de configurar coisas; lidera o Sprint 0 com o líder | [pessoa-4](pessoas/pessoa-4-infra-mapa.md) |
| 5 | Telas da ONG (app) | quem gosta de visual e experiência do usuário | [pessoa-5](pessoas/pessoa-5-telas-ong.md) |

> As Pessoas **3 e 5 fazem dupla**: a 3 faz as regras de reserva no servidor e a 5 faz as telas que usam essas regras.
>
> O **líder** pode ser qualquer uma das cinco pessoas (ele também tem uma parte). Ele é o "dono do produto": prioriza as tarefas e revisa os arquivos de fundação.

### 4. Ambiente (10 min)

- Todos vão instalar o ambiente pela [trilha/03](../trilha/03-ambiente-windows-vscode.md).
- Marquem uma **chamada de instalação** (2 a 3 h) para fazerem **juntos**: quem trava recebe ajuda na hora.
- Quem tiver computador fraco: avise agora (plano B: celular físico via USB ou o app no Chrome).

### 5. Combinados finais (15 min)

Preencham a ata abaixo e salvem no grupo de conversa (ou como a primeira issue do GitHub).

## Ata

```text
REUNIÃO DE KICKOFF
Data: ___/___/______
Presentes: ____________________________________________

Líder (dono do produto): ______________________________

Divisão:
- Pessoa 1 (login e cadastro): __________  GitHub: @__________
- Pessoa 2 (doador): __________            GitHub: @__________
- Pessoa 3 (reservas, servidor): __________ GitHub: @__________
- Pessoa 4 (infra, proximidade, mapa): ____ GitHub: @__________
- Pessoa 5 (telas da ONG): __________      GitHub: @__________

Grupo de conversa: ______________________________
Planning (início de cada sprint): ________ (dia/hora)
Review + retrospectiva (fim de cada sprint): ________ (dia/hora)
Daily assíncrona: até ____ h, no grupo (fiz / vou fazer / travei em)
Scrum Master do Sprint 0: __________
Chamada de instalação do ambiente: ___/___ às ____ h
Prazo final da entrega: ___/___/______
Política da disciplina sobre uso de IA: ______________________
```

## Depois da reunião (cada pessoa)

1. Ler o **seu** guia em [pessoas/](pessoas/).
2. Ler a trilha [01](../trilha/01-entendendo-o-projeto.md) e [02](../trilha/02-processo-e-planejamento.md).
3. Instalar o ambiente na chamada combinada ([trilha/03](../trilha/03-ambiente-windows-vscode.md)).
4. Criar a conta no GitHub (se ainda não tiver) e mandar o usuário para o líder.
