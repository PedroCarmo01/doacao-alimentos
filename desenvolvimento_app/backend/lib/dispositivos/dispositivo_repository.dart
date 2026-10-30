/// CONTRATO: guardar o identificador de push de um celular (tabela
/// `dispositivos`), usado pelo push real numa etapa futura.
abstract interface class DispositivoRepository {
  /// Se o [token] já existe (mesmo celular), só atualiza o dono e a data.
  Future<void> salvar({
    required int usuarioId,
    required String token,
    required String plataforma,
    required DateTime agora,
  });
}
