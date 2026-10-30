# ADR-009 — Autenticação com JWT + bcrypt; token no armazenamento seguro

- Status: Aceita
- Data: 2026-09-15

## Contexto
Existem dois tipos de usuário (doador e ONG) com permissões diferentes. O app é mobile, então não há cookies de navegador.

## Decisão
- A senha é guardada como **hash bcrypt** (`SenhaService`).
- No login, o backend emite um **JWT** com `uid` e `tipo`, válido por 12 horas (`TokenService`). O segredo fica no `.env` (`JWT_SEGREDO`, com no mínimo 32 caracteres).
- Rotas protegidas exigem `Authorization: Bearer <token>`. O middleware `exigirAutenticacao()` valida o token e disponibiliza o `UsuarioAutenticado`.
- A autorização por tipo (`usuario.exigirTipo(TipoUsuario.ong)`) e por **propriedade** (a doação é desse doador?) é feita nos Services.
- No app, o token fica no `flutter_secure_storage`, que usa o Keystore do Android.

## Alternativas consideradas
- **Sessão no servidor**: exigiria uma tabela de sessões e não traria ganho para um app mobile.
- **`shared_preferences` para o token**: salva em texto puro no aparelho.

## Consequências
- Positivas: API sem estado e padrão de mercado; um token roubado expira sozinho.
- Cuidados: não dá para revogar um JWT antes de expirar (aceitável no escopo); o app deve encerrar a sessão quando receber erro 401.
