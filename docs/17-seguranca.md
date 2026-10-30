# 17 — Segurança

O que o projeto faz para ser seguro, e por quê. Usamos como referência a [OWASP Top 10](https://owasp.org/Top10/), a lista das falhas mais comuns em aplicações.

## Resumo

| Risco | O que fizemos | Onde |
|---|---|---|
| Senha vazada do banco | só **hash bcrypt** com sal; a senha nunca é gravada nem devolvida | `SenhaService`, `usuarios.senha_hash` |
| Descobrir quem tem conta | login com **mensagem única** "E-mail ou senha incorretos." | `AuthService.entrar` |
| Token falsificado | JWT **assinado** com `JWT_SEGREDO` (mín. 32 caracteres), com **expiração** (12 h) | `TokenService`, `Env` |
| Token roubado do celular | guardado no **armazenamento seguro** (Keystore do Android) | `ArmazenamentoTokenSeguro` |
| Dados sensíveis no token | o token tem só `uid` e `tipo` (ele é assinado, **não** criptografado: qualquer um lê) | `TokenService.gerar` |
| Rota esquecida sem login | **seguro por padrão**: `exigirAutenticacao()` no `_middleware` da pasta protege todas as rotas dela | `routes/doacoes`, `proximas`, `reservas` |
| ONG fazendo ação de doador | **autorização por papel**: `usuario.exigirTipo(...)` → 403 | Services |
| Ver/alterar recurso de outro usuário | checagem de **dono** em todo Service; "não é seu" responde **404** (não revela que o id existe) | Services |
| SQL Injection | **100%** das queries com parâmetros `:nome` | repositórios MySQL |
| Entrada maliciosa ou malformada | validação no backend (o app valida só para ajudar o usuário); JSON malformado → 400 | `ValidadorUsuario`, `ValidadorDoacao`, `LeitorJson`, `lerJson` |
| Detalhe interno vazando | erro inesperado responde `ERRO_INTERNO` genérico; a pilha só aparece no terminal | `tratarErros` |
| Segredos no Git | `.env` no `.gitignore`; só o `.env.example` (sem segredos) é versionado | `.gitignore` |
| Banco com poder demais | usuário `summit_app` só com `SELECT/INSERT/UPDATE/DELETE` (privilégio mínimo) | `database/criar_usuario.sql` |
| Conexão com o banco em texto claro | **TLS** ligado por padrão (`DB_TLS=true`) | `Database.conectar` |
| API exposta na rede sem querer | escuta só em `127.0.0.1` por padrão; rede local só com `ESCUTAR_NA_REDE=true` | `main.dart` |
| HTTP sem TLS no app | `usesCleartextTraffic` liberado **só no build de debug** | `android/app/src/debug/AndroidManifest.xml` (trilha 10) |
| Regra crítica dependendo só do código | "uma reserva ativa por doação" garantida também pelo **índice único** | `schema.sql` |

## Controle de acesso

| Ação | Quem pode |
|---|---|
| Criar, listar, cancelar doação | doador (só as **próprias**; cancelar só se `disponivel`) |
| Ver detalhe da doação | doador dono; ONG se a doação pode ser reservada **ou** se ela mesma reservou |
| Buscar doações próximas | ONG (centro = o **próprio** perfil) |
| Reservar, listar reservas, desistir | ONG (só as **próprias**) |
| Confirmar retirada | ONG dona da reserva **ou** doador dono da doação |

## CORS

Só importa se o app rodar no navegador (`flutter run -d chrome`). Em desenvolvimento, `CORS_ORIGEM=*`. Num servidor público, troque pela origem exata.

## Privacidade e LGPD (noções)

- Coletamos o mínimo: nome, e-mail, telefone opcional e a **localização da organização** (não da pessoa).
- A ONG vê o endereço da doação (necessário para retirar); a localização da ONG não é mostrada a outros usuários.
- O app pede permissão de localização só no cadastro, com explicação na tela.
- Em produção, seria necessário uma política de privacidade e a opção de excluir a conta (ver [roadmap](20-roadmap.md)).

## Se um segredo vazar

1. Gere um novo (`JWT_SEGREDO` ou senha do banco) e troque no `.env` (e no MySQL com `ALTER USER`).
2. Todos os tokens antigos deixam de valer ao trocar o `JWT_SEGREDO`: os usuários entram de novo.
3. Apagar o commit não basta: o segredo continua no histórico. **Troque o segredo.**

## Evoluções possíveis (fora do MVP)

- Limitar tentativas de login por IP (*rate limiting*).
- HTTPS no servidor publicado ([19 — Deploy](19-deploy.md)).
- Renovação de token (*refresh token*).
