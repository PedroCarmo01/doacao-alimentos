# 15 — Padrões de código

Regras para o código de 5 pessoas parecer escrito por uma só. A CI confere formatação e análise automaticamente; o resto é revisão de código.

## Idioma

- **Português** para nomes do domínio, mensagens, comentários e documentação: `Doacao`, `reservar()`, `podeSerReservada`.
- Inglês só onde o Flutter/Dart exige ou é convenção da linguagem: `build`, `initState`, `toJson`, `fromJson`, `copyWith`, `dispose`.
- Sem acentos em **identificadores** (`Doacao`, não `Doação`); com acentos em **textos** (`'Doação publicada!'`).

## Nomes (Effective Dart)

| Tipo | Estilo | Exemplo |
|---|---|---|
| Classes, enums, typedefs | `UpperCamelCase` | `ReservaService`, `StatusDoacao` |
| Métodos, variáveis, parâmetros | `lowerCamelCase` | `listarProximas`, `raioKm` |
| Arquivos e pastas | `snake_case` | `reserva_service.dart` |
| Constantes | `lowerCamelCase` | `const raioMaximoKm = 50.0;` |
| Privados | prefixo `_` | `_doacoes`, `_buscar()` |
| Booleanos | pergunta | `ocupado`, `estaAtiva`, `podeCancelar`, `ehOng` |
| Rotas do Dart Frog | caminho da URL | `routes/reservas/[id]/retirada.dart` |
| Colunas do banco | `snake_case` | `janela_fim` (no JSON vira `janelaFim`) |

## Formatação e análise

- `dart format` (tarefa "verificar antes do PR"). Não discuta estilo: o formatador decide.
- `dart analyze` / `flutter analyze` sem avisos. Regras em `analysis_options.yaml` (`lints` / `flutter_lints`).
- Vírgula no último argumento de listas longas, para o formatador quebrar as linhas.

## Organização

| Regra | Por quê |
|---|---|
| Um arquivo = uma responsabilidade principal | fácil de achar e revisar |
| Imports: `dart:` → `package:` → relativos, separados por linha em branco | padrão do Dart |
| No backend, `lib/` importa `lib/` com caminho relativo; `routes/` e `test/` importam com `package:summit_backend/...` | o Dart Frog exige `package:` fora de `lib/` |
| Campos `final` sempre que possível; modelos imutáveis com `copyWith` | evita mudanças escondidas |
| Dependências pelo **construtor**, tipadas pela **interface** | testável ([ADR-006](adr/ADR-006-injecao-por-construtor.md)) |
| "Agora" sempre pelo `Relogio`, nunca `DateTime.now()` | testes determinísticos |
| SQL sempre com parâmetros `:nome` | evita SQL Injection |
| Erros: **lance** exceções (backend: `AppException`; app: `ErroDeRegra`) | um lugar só trata e formata |

## Comentários

- Comentário de documentação (`///`) em classes e métodos públicos: **o quê** e **por quê**, não o óbvio.
- `// TODO(PessoaN): ...` só para algo combinado, com dono. Antes da entrega, não pode sobrar TODO sem dono.
- Sem código comentado "para o caso de precisar": o Git guarda o histórico.

## Testes

- Arquivo `*_test.dart` no mesmo caminho relativo de `lib/`, dentro de `test/`.
- Nome do teste descreve o comportamento: `'segunda ONG recebe DOACAO_INDISPONIVEL'`.
- Estrutura **Arrange → Act → Assert**, separada por linha em branco.

Ver [16 — Testes](16-testes.md).

## Interface (app)

- Cores de `AppColors`, nunca números soltos (`Color(0xFF...)`) nas telas.
- Componentes de `shared/widgets` antes de criar um novo.
- Textos de botão com verbo: "Publicar doação", "Reservar", "Confirmar retirada".
- Mensagens de erro dizem **o que fazer**: "Ative a localização (GPS) do aparelho e tente de novo."
