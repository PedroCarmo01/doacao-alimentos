/// Listas de opções da doação (formulário T11 e cartões das listas).
///
/// O `name` de cada valor é o que vai no JSON e na coluna ENUM do banco.
library;

/// Categoria do alimento doado.
enum CategoriaAlimento {
  hortifruti('Hortifrúti'),
  padaria('Padaria'),
  laticinios('Laticínios'),
  mercearia('Mercearia'),
  refeicoesProntas('Refeições prontas'),
  carnesFrios('Carnes e frios'),
  bebidas('Bebidas'),
  outros('Outros');

  const CategoriaAlimento(this.rotulo);

  final String rotulo;
}

/// Unidade da quantidade ("5 caixas", "2,5 kg").
enum Unidade {
  kg('kg'),
  unidades('unidades'),
  caixas('caixas'),
  pacotes('pacotes'),
  litros('litros');

  const Unidade(this.rotulo);

  final String rotulo;
}

/// Como o alimento precisa ser guardado até a retirada.
enum Conservacao {
  ambiente('Temperatura ambiente'),
  refrigerado('Refrigerado'),
  congelado('Congelado');

  const Conservacao(this.rotulo);

  final String rotulo;
}

/// Ajuda a ONG a saber se consegue levar a doação.
enum VeiculoNecessario {
  sacola('Cabe numa sacola'),
  carro('Precisa de carro'),
  van('Precisa de van');

  const VeiculoNecessario(this.rotulo);

  final String rotulo;
}

/// Ciclo de vida de uma doação:
///
/// `disponivel` → `reservada` → `concluida`.
/// Saídas: `cancelada` pelo doador (RN12) ou `expirada` quando o horário de
/// retirada acaba sem ninguém retirar (RN13). Quando o prazo de uma
/// retirada acaba, a doação volta de `reservada` para `disponivel` (RN22).
enum StatusDoacao {
  disponivel('Disponível'),
  reservada('Reservada'),
  concluida('Concluída'),
  cancelada('Cancelada'),
  expirada('Expirada');

  const StatusDoacao(this.rotulo);

  final String rotulo;

  /// Aparece na aba "Ativas" (T10); as outras vão para o "Histórico".
  bool get ativa =>
      this == StatusDoacao.disponivel || this == StatusDoacao.reservada;
}

/// Filtro de `GET /doacoes?situacao=` (abas da T10).
enum SituacaoDaLista { ativas, historico }
