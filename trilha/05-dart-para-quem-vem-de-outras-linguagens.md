# 05 — Dart para quem vem de outras linguagens

**Objetivo:** aprender o Dart necessário para o projeto, comparando com Java, C#, Python e JavaScript, com foco em **orientação a objetos**.
**Quem:** todos.
**Como praticar:** sem instalar nada, em [dartpad.dev](https://dartpad.dev). Ou crie um arquivo `rascunho.dart` e rode `dart run rascunho.dart`.

---

## 1. Primeiro programa

```dart
void main() {
  print('Olá, Dart!');
}
```

Como em Java e C#, a execução começa em `main`. Ponto e vírgula é obrigatório; blocos usam `{ }`.

## 2. Variáveis e tipos

```dart
var nome = 'Mercado Bom Preço'; // tipo inferido: String
String cidade = 'Mogi das Cruzes';  // tipo explícito
int quantidade = 5;
double latitude = -23.52;
bool disponivel = true;

final criadoEm = DateTime.now(); // atribuído uma vez (em tempo de execução)
const raioPadraoKm = 10.0;      // constante em tempo de compilação
```

| Dart | Java | C# | Python | JavaScript |
|---|---|---|---|---|
| `var x = 1;` | `var x = 1;` | `var x = 1;` | `x = 1` | `let x = 1;` |
| `final x = 1;` | `final int x = 1;` | `readonly` | — | `const x = 1;` |
| `const x = 1;` | `static final` | `const` | — | — |

> **Regra do projeto:** prefira `final`. Só use `var` quando o valor realmente muda.

## 3. Null safety (segurança contra nulos)

Em Dart, uma variável **não pode** ser `null`, a menos que o tipo termine com `?`. O compilador impede o famoso `NullPointerException`.

```dart
String titulo = 'Pães';   // nunca é null
String? descricao;        // pode ser null (começa null)

print(descricao?.length);     // ?.  chama só se não for null (resultado: null)
print(descricao ?? 'Sem descrição'); // ??  valor padrão se for null
descricao ??= 'Padrão';       // ??=  atribui só se for null
print(descricao!.length);     // !   "garanto que não é null" (use pouco!)
```

## 4. Strings, coleções e controle de fluxo

```dart
final total = 3;
print('Você tem $total doações e ${total * 2} itens'); // interpolação

final categorias = ['padaria', 'hortifruti'];          // List<String>
final estoque = {'pao': 30, 'frutas': 5};              // Map<String, int>
final tags = {'urgente', 'frio'};                       // Set<String>

final todas = [...categorias, 'laticinios', if (total > 2) 'outros']; // spread e if
final maiusculas = [for (final c in categorias) c.toUpperCase()];     // for em coleção

for (final c in categorias) {
  print(c);
}
final grandes = categorias.where((c) => c.length > 7).toList(); // filter
final tamanhos = categorias.map((c) => c.length).toList();      // map
```

## 5. Funções e parâmetros nomeados

```dart
// Função normal
int somar(int a, int b) {
  return a + b;
}

// Arrow function (uma expressão)
int dobrar(int x) => x * 2;

// Parâmetros NOMEADOS (entre chaves): muito usados no Flutter
String saudar({required String nome, String cumprimento = 'Olá'}) =>
    '$cumprimento, $nome!';

void main() {
  print(saudar(nome: 'Ana'));                     // Olá, Ana!
  print(saudar(cumprimento: 'Oi', nome: 'Bruno')); // a ordem não importa
}
```

Parâmetros opcionais posicionais usam colchetes: `void log(String msg, [String nivel = 'info'])`.

## 6. Classes e encapsulamento

```dart
class ContaBancaria {
  // Construtor com "this." atribui direto aos campos
  ContaBancaria(this.titular, {double saldoInicial = 0}) : _saldo = saldoInicial;

  final String titular;
  double _saldo; // _ no início = PRIVADO ao arquivo (biblioteca)

  double get saldo => _saldo; // getter: leitura pública, escrita privada

  void depositar(double valor) {
    if (valor <= 0) throw ArgumentError('Valor deve ser positivo');
    _saldo += valor;
  }
}

void main() {
  final conta = ContaBancaria('Ana', saldoInicial: 100); // "new" é opcional
  conta.depositar(50);
  print(conta.saldo); // 150
}
```

> **Diferença importante:** em Dart não existem `public`, `private` e `protected`. O `_` torna algo privado **ao arquivo** (não à classe). Por isso, nos ViewModels, os campos são `_privados` e expostos por getters.

### Construtores nomeados, `factory` e `const`

```dart
class Coordenadas {
  const Coordenadas(this.latitude, this.longitude); // const: objeto imutável

  const Coordenadas.zero() : this(0, 0);            // construtor NOMEADO

  factory Coordenadas.fromJson(Map<String, dynamic> json) => // FACTORY
      Coordenadas(json['lat'] as double, json['lng'] as double);

  final double latitude;
  final double longitude;
}
```

O `fromJson` de todos os modelos do projeto é um **factory constructor**: ele recebe um mapa e devolve um objeto.

## 7. Os 4 pilares da POO em Dart

### Abstração e interfaces

Em Dart, **toda classe já define uma interface**. Para declarar só o contrato, usamos `abstract interface class`:

```dart
abstract interface class DoacaoRepository {
  Future<List<String>> listar(); // sem corpo: só o "o quê"
}

class DoacaoRepositoryApi implements DoacaoRepository {
  @override
  Future<List<String>> listar() async => ['vindo da API'];
}

class DoacaoRepositoryFake implements DoacaoRepository {
  @override
  Future<List<String>> listar() async => ['dado de teste'];
}
```

| Dart | Java / C# |
|---|---|
| `abstract interface class X` | `interface X` |
| `class A implements X` | `class A implements X` / `class A : X` |
| `abstract class B` (com código) | `abstract class B` |
| `class C extends B` | `class C extends B` / `class C : B` |

### Herança

```dart
abstract class Animal {
  Animal(this.nome);
  final String nome;
  String som(); // método abstrato
  String apresentar() => '$nome faz ${som()}';
}

class Cachorro extends Animal {
  Cachorro(super.nome); // repassa para o construtor da mãe
  @override
  String som() => 'au au';
}
```

No projeto, todos os ViewModels **herdam** de `ViewModelBase`, que já traz "carregando", "erro" e o método `executar()`.

### Polimorfismo

```dart
void imprimirTodos(DoacaoRepository repositorio) async {
  print(await repositorio.listar()); // funciona com Api OU Fake
}
```

O código que usa a interface não sabe (nem precisa saber) qual implementação recebeu. É isso que permite o **modo Fake** do app.

### Encapsulamento
Visto na seção 6: estado privado (`_saldo`) e acesso controlado (getter e métodos).

## 8. Enums aprimorados e `switch` com padrões

```dart
enum StatusDoacao {
  disponivel('Disponível'),
  reservada('Reservada');

  const StatusDoacao(this.rotulo);
  final String rotulo;
}

String corDoStatus(StatusDoacao status) => switch (status) {
      StatusDoacao.disponivel => 'verde',
      StatusDoacao.reservada => 'laranja',
    }; // o compilador avisa se faltar algum caso
```

## 9. Assincronismo: `Future`, `async` e `await`

Chamadas à API demoram. Um `Future<T>` é uma "promessa" de um valor `T` no futuro (como `Promise` no JavaScript e `Task<T>` no C#).

```dart
Future<String> buscarNome() async {
  await Future.delayed(const Duration(seconds: 1)); // simula a rede
  return 'ONG Mãos Amigas';
}

Future<void> main() async {
  print('buscando...');
  final nome = await buscarNome(); // espera sem travar o app
  print(nome);
}
```

> Esqueceu o `await`? Você recebe um `Future`, não o valor. O VS Code avisa com a lint `unawaited_futures` ou mostrando o tipo errado.

## 10. Exceções

```dart
class SaldoInsuficienteException implements Exception {
  const SaldoInsuficienteException(this.mensagem);
  final String mensagem;
}

void sacar(double valor) {
  throw const SaldoInsuficienteException('Saldo insuficiente');
}

void main() {
  try {
    sacar(10);
  } on SaldoInsuficienteException catch (e) { // captura um tipo específico
    print(e.mensagem);
  } catch (e) {                               // qualquer outro
    print('Erro inesperado: $e');
  } finally {
    print('sempre executa');
  }
}
```

No backend, cada exceção de negócio sabe o próprio status HTTP; no app, `ApiException` carrega a mensagem para o usuário.

## 11. Extensões, records e `copyWith`

```dart
// Extensão: acrescenta métodos a uma classe que não é nossa
extension Reais on double {
  String get emReais => 'R\$ ${toStringAsFixed(2)}';
}

// Record: agrupa valores sem criar classe
(double, double) posicao() => (-23.52, -46.18);

void main() {
  print(19.9.emReais);
  final (lat, lng) = posicao();
  print('$lat, $lng');
}
```

**Imutabilidade:** os modelos do projeto têm só campos `final`. Para "alterar", criamos uma cópia: `doacao.copyWith(status: StatusDoacao.reservada)`.

## 12. Pacotes, imports e `pubspec.yaml`

```dart
import 'dart:math';                                // biblioteca padrão
import 'package:http/http.dart' as http;           // pacote externo
import 'package:shared_models/shared_models.dart'; // nosso pacote
import '../core/utils/formatador.dart';            // arquivo do próprio projeto
```

- `pubspec.yaml` lista as dependências (como `package.json` ou `pom.xml`).
- `dart pub get` (ou `flutter pub get`) baixa as dependências.
- `pubspec.lock` registra as versões exatas; ele **vai** para o Git.

## 13. Ferramentas do dia a dia

| Comando | Para quê |
|---|---|
| `dart run arquivo.dart` | Executa um programa |
| `dart format .` | Formata o código (o VS Code faz ao salvar) |
| `dart analyze` | Aponta erros e más práticas |
| `dart test` | Roda os testes |

---

## Exercícios (DartPad)

1. Crie a classe `Doacao` com `titulo`, `quantidade` e um `StatusDoacao`; adicione o getter `bool get podeReservar`.
2. Crie a interface `Notificador` com `void avisar(String msg)` e duas implementações: `NotificadorConsole` e `NotificadorSilencioso`. Escreva uma função que recebe um `Notificador` e use as duas.
3. Escreva `Future<int> contarDoacoes()` que espera 1 segundo e devolve 3; chame com `await` dentro de `main`.
4. Crie `ValorInvalidoException` e lance quando a quantidade for negativa; trate com `try/on/catch`.

<details>
<summary>Resposta do exercício 2</summary>

```dart
abstract interface class Notificador {
  void avisar(String mensagem);
}

class NotificadorConsole implements Notificador {
  @override
  void avisar(String mensagem) => print('AVISO: $mensagem');
}

class NotificadorSilencioso implements Notificador {
  @override
  void avisar(String mensagem) {}
}

void publicar(Notificador notificador) => notificador.avisar('Nova doação!');

void main() {
  publicar(NotificadorConsole());
  publicar(NotificadorSilencioso());
}
```
</details>

---

## Checklist

- [ ] Sei a diferença entre `var`, `final` e `const`
- [ ] Sei usar `?`, `?.`, `??` e quando evitar `!`
- [ ] Sei criar classe com construtor, campo privado e getter
- [ ] Sei criar uma interface e duas implementações (polimorfismo)
- [ ] Sei usar `async`/`await` e `try`/`on`/`catch`
- [ ] Fiz os 4 exercícios
