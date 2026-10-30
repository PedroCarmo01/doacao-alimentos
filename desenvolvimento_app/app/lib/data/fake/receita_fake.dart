import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';

/// "Receita Federal" do modo Fake: substitui a BrasilAPI sem internet.
///
/// Conhece os mesmos CNPJs de teste do roteiro da etapa 1, para que o teste
/// manual funcione igual nos modos API e Fake. Qualquer outro CNPJ com
/// dígitos certos é tratado como "BrasilAPI fora do ar": a conta é criada
/// com "verificação pendente" (RN03).
abstract final class ReceitaFake {
  static final Map<String, InfoCnpj> _cadastros = {
    // Associação privada ATIVA (natureza 3999): pode ser ONG.
    '11222333000181': const InfoCnpj(
      cnpj: '11222333000181',
      razaoSocial: 'CAIXA ESCOLAR (EXEMPLO)',
      situacao: 'ATIVA',
      naturezaJuridica: 'Associação Privada',
      codigoNaturezaJuridica: 3999,
    ),
    // Sociedade de economia mista ATIVA (2038): só doador.
    '00000000000191': const InfoCnpj(
      cnpj: '00000000000191',
      razaoSocial: 'BANCO DO BRASIL SA',
      nomeFantasia: 'DIRECAO GERAL',
      situacao: 'ATIVA',
      naturezaJuridica: 'Sociedade de Economia Mista',
      codigoNaturezaJuridica: 2038,
    ),
    // CNPJ fictício BAIXADO: ninguém pode usar.
    ValidadorDocumento.completarCnpj('904500080001'): InfoCnpj(
      cnpj: ValidadorDocumento.completarCnpj('904500080001'),
      razaoSocial: 'EMPRESA FECHADA (FICTICIO)',
      situacao: 'BAIXADA',
      codigoNaturezaJuridica: 2062,
    ),
  };

  /// `null` = "não deu para consultar" (como a BrasilAPI fora do ar).
  static InfoCnpj? consultar(String cnpj) => _cadastros[cnpj];

  /// RN03 com os mesmos códigos e mensagens do `DocumentoService`.
  static InfoCnpj conferir(InfoCnpj info, TipoUsuario? tipo) {
    if (!info.ativa) {
      throw ApiException(
        codigo: 'CNPJ_INATIVO',
        mensagem:
            'Este CNPJ não está ativo na Receita Federal '
            '(situação: ${info.situacao}). Só CNPJ ativo pode se cadastrar.',
        status: 422,
      );
    }
    if (tipo == TipoUsuario.ong && !info.semFinsLucrativos) {
      throw const ApiException(
        codigo: 'CNPJ_NAO_E_ENTIDADE',
        mensagem:
            'Este CNPJ não é de uma entidade sem fins lucrativos. Para se '
            'cadastrar como ONG, use o CNPJ da associação ou fundação.',
        status: 422,
      );
    }
    return info;
  }

  /// Pré-consulta (`GET /documentos/{numero}`), com os mesmos erros.
  static InfoCnpj preConsultar(String numero, TipoUsuario tipo) {
    final cnpj = ValidadorDocumento.somenteDigitos(numero);
    final erro = ValidadorDocumento.cnpj(cnpj);
    if (erro != null) {
      throw ApiException(
        codigo: 'DOCUMENTO_INVALIDO',
        mensagem: erro,
        status: 422,
      );
    }
    final info = consultar(cnpj);
    if (info == null) {
      throw const ApiException(
        codigo: 'CONSULTA_INDISPONIVEL',
        mensagem:
            'Não foi possível consultar o CNPJ agora. Você pode continuar: '
            'a verificação será feita depois.',
        status: 503,
      );
    }
    return conferir(info, tipo);
  }
}
