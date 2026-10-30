/// Erro cuja [mensagem] pode ser mostrada diretamente ao usuário.
///
/// É uma INTERFACE: classes diferentes (`ApiException`,
/// `LocalizacaoException`, [ErroDeRegra]) a implementam. A `ViewModelBase`
/// trata todas do mesmo jeito, sem saber qual é qual (polimorfismo).
abstract interface class ErroAmigavel implements Exception {
  String get mensagem;
}

/// Regra de negócio violada no próprio app (ex.: validação de formulário).
class ErroDeRegra implements ErroAmigavel {
  const ErroDeRegra(this.mensagem);

  @override
  final String mensagem;

  @override
  String toString() => mensagem;
}
