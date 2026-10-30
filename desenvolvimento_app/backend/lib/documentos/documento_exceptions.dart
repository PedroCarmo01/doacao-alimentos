import '../core/erros/app_exception.dart';

/// 422 — o documento foi recusado pelas regras RN02/RN03.
///
/// Códigos usados: `DOCUMENTO_INVALIDO`, `CNPJ_NAO_ENCONTRADO`,
/// `CNPJ_INATIVO` e `CNPJ_NAO_E_ENTIDADE`. O app usa o código para decidir
/// o que mostrar; a mensagem já diz ao usuário o que fazer.
class DocumentoRecusadoException extends AppException {
  const DocumentoRecusadoException(super.codigo, super.mensagem);

  @override
  int get statusHttp => 422;
}

/// 503 — a BrasilAPI não respondeu na pré-consulta (`GET /documentos/...`).
///
/// No CADASTRO isso não acontece: lá a conta é criada com "verificação
/// pendente" (RN03). Só a pré-consulta avisa, para o app explicar ao usuário
/// que ele pode continuar mesmo assim.
class ConsultaIndisponivelException extends AppException {
  const ConsultaIndisponivelException()
    : super(
        'CONSULTA_INDISPONIVEL',
        'Não foi possível consultar o CNPJ agora. Você pode continuar: a '
            'verificação será feita depois.',
      );

  @override
  int get statusHttp => 503;
}
