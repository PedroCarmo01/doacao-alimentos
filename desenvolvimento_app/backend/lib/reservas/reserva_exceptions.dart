import 'package:shared_models/shared_models.dart';

import '../core/erros/app_exception.dart';

/// Erros da retirada. Os códigos são os da tabela de rotas (docs/08).
abstract final class ErrosDaRetirada {
  static const indisponivel = ConflitoException(
    'DOACAO_INDISPONIVEL',
    'Que pena! Outra ONG aceitou esta doação primeiro.',
  );

  static const naoAtiva = ConflitoException(
    'RESERVA_NAO_ATIVA',
    'Esta retirada não está mais em andamento.',
  );

  static const suspensa = ConflitoException(
    'ONG_SUSPENSA',
    'Sua conta está suspensa por desistências. Você ainda vê as doações, '
        'mas não pode aceitar.',
  );

  static const bloqueada = ConflitoException(
    'ONG_BLOQUEADA_NESTA_DOACAO',
    'Você desistiu desta doação e não pode aceitá-la de novo.',
  );

  static ConflitoException limite(int maximo) => ConflitoException(
    'LIMITE_DE_RETIRADAS',
    'Você já tem $maximo retiradas em andamento. Conclua uma antes de '
        'aceitar outra.',
  );

  static const prazoNaoAcabou = ConflitoException(
    'PRAZO_NAO_ACABOU',
    'Só dá para marcar "A ONG não compareceu" depois que o prazo acabar.',
  );
}

/// 400 — o doador digitou um código diferente do da ONG (RN27).
class CodigoIncorretoException extends AppException {
  CodigoIncorretoException(int restam)
    : super(
        'CODIGO_INCORRETO',
        'Código incorreto. '
            '${restam == 1 ? 'Resta 1 tentativa' : 'Restam $restam tentativas'}'
            ' antes de bloquear por '
            '${RegrasDaRetirada.bloqueioDoCodigo.inMinutes} minutos.',
      );

  @override
  int get statusHttp => 400;
}

/// 429 (*Too Many Requests*) — muitos códigos errados seguidos: novas
/// tentativas ficam bloqueadas por 10 minutos (RN27). Evita "chutar" os
/// 10 mil códigos possíveis.
class TentativasEsgotadasException extends AppException {
  TentativasEsgotadasException(Duration falta)
    : super(
        'TENTATIVAS_ESGOTADAS',
        'Muitos códigos errados. Tente de novo daqui a '
            '${falta.inMinutes + 1} minuto(s).',
      );

  @override
  int get statusHttp => 429;
}
