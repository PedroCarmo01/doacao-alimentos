# 11 — Fluxos

Os principais fluxos do sistema, do toque na tela até o banco.

## 1. Primeiro acesso e login

```mermaid
sequenceDiagram
    actor U as Usuário
    participant App
    participant API
    participant DB as MySQL
    U->>App: abre o app
    App->>API: GET /
    API->>DB: SELECT 1
    App->>App: token salvo?
    alt tem token
        App->>API: GET /auth/me
        API-->>App: 200 Conta
        App->>U: início do perfil
    else não tem / inválido
        App->>U: escolha do perfil
        U->>App: e-mail + senha
        App->>API: POST /auth/login
        API->>DB: SELECT usuário + perfil
        API->>API: bcrypt confere, gera JWT
        API-->>App: 200 {token, usuario, perfil}
        App->>App: Sessao.iniciar (token no Keystore)
        App->>U: início do perfil
    end
```

## 2. Doador publica uma doação

```mermaid
sequenceDiagram
    actor D as Doador
    participant VM as NovaDoacaoViewModel
    participant API as POST /doacoes
    participant S as DoacaoService
    participant DB as MySQL
    D->>VM: preenche e toca Publicar
    VM->>VM: ValidadorDoacao (mesma regra do backend)
    VM->>API: DadosNovaDoacao + token
    API->>S: criar(usuario, dados)
    S->>S: exige doador, valida (hoje no fuso -3), localização do perfil
    S->>DB: INSERT doacoes (status disponivel)
    API-->>VM: 201 Doacao
    VM-->>D: SnackBar, volta à lista
```

## 3. ONG descobre e reserva

```mermaid
sequenceDiagram
    actor O as ONG
    participant H as HomeOngViewModel
    participant P as GET /proximas
    participant R as POST /reservas
    participant DB as MySQL
    loop a cada 15 s
        H->>P: listarProximas(raioKm)
        P->>DB: caixa de lat/lng + status + janela
        P-->>H: lista com distanciaKm (ordenada)
        H->>H: ids novos? → etiqueta NOVA + SnackBar
    end
    O->>R: reservar(doacaoId)
    R->>DB: BEGIN; SELECT ... FOR UPDATE
    alt ainda disponível
        R->>DB: UPDATE doacoes → reservada; INSERT reserva; COMMIT
        R-->>O: 201 Reserva (contador)
    else outra ONG chegou antes
        R->>DB: ROLLBACK
        R-->>O: 409 DOACAO_INDISPONIVEL
    end
```

## 4. Fim de uma reserva

```mermaid
flowchart TD
    A[Reserva ativa] --> B{O que acontece primeiro?}
    B -- ONG ou doador confirma --> C[POST /reservas/id/retirada<br/>reserva concluida + doação concluida]
    B -- ONG desiste --> D[DELETE /reservas/id<br/>reserva cancelada + doação disponivel]
    B -- prazo acaba --> E[ExpiracaoJob a cada 30 s<br/>reserva expirada + doação disponivel]
    D --> F[Volta para a lista das ONGs]
    E --> F
```

## 5. Estados

| Doação | Significa | Pode ir para |
|---|---|---|
| `disponivel` | ONGs podem reservar (se a janela estiver aberta) | `reservada`, `cancelada` |
| `reservada` | uma ONG está com ela | `disponivel` (expirou / desistiu), `concluida` |
| `concluida` | retirada feita | — |
| `cancelada` | o doador cancelou | — |

| Reserva | Significa | Pode ir para |
|---|---|---|
| `ativa` | prazo correndo | `concluida`, `expirada`, `cancelada` |
| `concluida` | retirada feita | — |
| `expirada` | prazo acabou | — |
| `cancelada` | a ONG desistiu | — |

## 6. Tratamento de erros (qualquer fluxo)

```mermaid
flowchart LR
    S[Service lança<br/>ConflitoException] --> M[tratarErros<br/>409 + JSON]
    M --> AC[ApiClient<br/>ApiException]
    AC --> VM[ViewModelBase.executar<br/>erro = mensagem]
    VM --> V[View mostra o texto]
```

A mensagem que o usuário vê é a mesma que o Service escreveu. No modo Fake, o `BancoFake` lança a mesma `ApiException` com o mesmo código.
