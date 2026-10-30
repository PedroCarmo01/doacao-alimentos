/// Listas de opções do perfil (cadastro T4 e perfil T50).
///
/// O `name` de cada valor é o que vai no JSON e no banco (coluna ENUM).
library;

/// Tipo de estabelecimento do doador (cadastro, etapa 2).
///
/// RN02: cada tipo diz se aceita CPF além de CNPJ. Feirantes, produtores
/// rurais e "outros" muitas vezes são pessoa física.
enum TipoEstabelecimento {
  supermercado('Supermercado / mercado', aceitaCpf: false),
  hortifruti('Hortifrúti / sacolão', aceitaCpf: false),
  feira('Feira / feirante', aceitaCpf: true),
  padaria('Padaria / confeitaria', aceitaCpf: false),
  restaurante('Restaurante / lanchonete', aceitaCpf: false),
  produtorRural('Produtor rural', aceitaCpf: true),
  outro('Outro', aceitaCpf: true);

  const TipoEstabelecimento(this.rotulo, {required this.aceitaCpf});

  final String rotulo;

  /// `true` = pode cadastrar com CPF; `false` = só com CNPJ.
  final bool aceitaCpf;
}

/// Qual documento identifica a organização.
enum TipoDocumento {
  cnpj('CNPJ'),
  cpf('CPF');

  const TipoDocumento(this.rotulo);

  final String rotulo;

  /// Descobre o tipo pelo tamanho: 11 números = CPF; senão, CNPJ.
  static TipoDocumento doNumero(String somenteDigitos) =>
      somenteDigitos.length == 11 ? TipoDocumento.cpf : TipoDocumento.cnpj;
}

/// Selo mostrado no perfil e para o doador antes de entregar (RN03).
enum Verificacao {
  /// O CNPJ foi conferido na BrasilAPI: está ATIVO (e, para ONG, é de
  /// entidade sem fins lucrativos).
  verificada('Verificada'),

  /// A BrasilAPI estava fora do ar no cadastro (o servidor tenta de novo
  /// depois) ou o documento é um CPF, que não tem consulta pública.
  pendente('Verificação pendente');

  const Verificacao(this.rotulo);

  final String rotulo;
}

/// Como a ONG costuma buscar as doações. Ajuda o doador a saber se ela
/// consegue levar tudo.
enum Transporte {
  aPe('A pé'),
  carro('Carro'),
  van('Van ou caminhonete');

  const Transporte(this.rotulo);

  final String rotulo;
}
