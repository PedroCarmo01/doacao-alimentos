import 'package:shared_models/shared_models.dart';

import '../perfil/perfil_repository.dart';
import 'consulta_cnpj.dart';
import 'documento_exceptions.dart';

/// Regras de verificação do documento (RN02 e RN03).
///
/// Usado em três momentos:
/// 1. pré-consulta (`GET /documentos/{numero}`), para o app preencher o nome;
/// 2. cadastro (`AuthService.cadastrar`), para aceitar ou recusar a conta;
/// 3. a cada 10 minutos (`ReverificacaoJob`), para tentar de novo os CNPJs
///    que ficaram "pendentes" porque a BrasilAPI estava fora do ar.
class DocumentoService {
  DocumentoService({
    required ConsultaCnpj consulta,
    required PerfilRepository perfis,
  }) : _consulta = consulta,
       _perfis = perfis;

  final ConsultaCnpj _consulta;
  final PerfilRepository _perfis;

  /// Quantos perfis pendentes são conferidos a cada rodada do job.
  /// Poucos de cada vez, para não abusar da BrasilAPI (que é gratuita).
  static const pendentesPorRodada = 10;

  /// `GET /documentos/{numero}?tipo=ong|doador`.
  ///
  /// Diferente do cadastro, aqui "BrasilAPI fora do ar" vira um aviso (503)
  /// para o app explicar que dá para continuar.
  Future<InfoCnpj> preConsultar(String numero, {TipoUsuario? tipo}) async {
    final cnpj = ValidadorDocumento.somenteDigitos(numero);
    final erro = ValidadorDocumento.cnpj(cnpj);
    if (erro != null) {
      throw DocumentoRecusadoException('DOCUMENTO_INVALIDO', erro);
    }
    final resultado = await _consulta.consultar(cnpj);
    if (resultado.situacao == SituacaoDaConsulta.indisponivel) {
      throw const ConsultaIndisponivelException();
    }
    return _conferir(resultado, tipo);
  }

  /// RN03 no cadastro. Devolve os dados da Receita se o CNPJ foi conferido,
  /// ou `null` quando não deu para conferir: CPF (não tem consulta pública)
  /// ou BrasilAPI fora do ar. Nesses casos a conta fica "pendente".
  ///
  /// Lança [DocumentoRecusadoException] se o CNPJ não existe, não está
  /// ativo ou (para ONG) não é de entidade sem fins lucrativos.
  Future<InfoCnpj?> conferirParaCadastro(
    String documento,
    TipoUsuario tipo,
  ) async {
    if (TipoDocumento.doNumero(documento) == TipoDocumento.cpf) return null;
    final resultado = await _consulta.consultar(documento);
    if (resultado.situacao == SituacaoDaConsulta.indisponivel) return null;
    return _conferir(resultado, tipo);
  }

  /// Tenta de novo a verificação dos perfis pendentes. Devolve quantos
  /// passaram a "verificada". Quem continuar sem resposta fica para a
  /// próxima rodada.
  Future<int> reverificarPendentes() async {
    final pendentes = await _perfis.pendentesDeVerificacao(
      limite: pendentesPorRodada,
    );
    var verificados = 0;
    for (final perfil in pendentes) {
      final resultado = await _consulta.consultar(perfil.cnpj);
      final info = resultado.info;
      if (info != null && _aceito(info, perfil.tipo)) {
        await _perfis.marcarVerificada(
          perfil.usuarioId,
          razaoSocial: info.razaoSocial,
        );
        verificados++;
      }
    }
    return verificados;
  }

  /// Aplica a RN03 a uma consulta que funcionou.
  InfoCnpj _conferir(ResultadoConsultaCnpj resultado, TipoUsuario? tipo) {
    final info = resultado.info;
    if (info == null) {
      throw const DocumentoRecusadoException(
        'CNPJ_NAO_ENCONTRADO',
        'Este CNPJ não foi encontrado na Receita Federal. Confira os números.',
      );
    }
    if (!info.ativa) {
      throw DocumentoRecusadoException(
        'CNPJ_INATIVO',
        'Este CNPJ não está ativo na Receita Federal '
            '(situação: ${info.situacao}). Só CNPJ ativo pode se cadastrar.',
      );
    }
    if (tipo == TipoUsuario.ong && !info.semFinsLucrativos) {
      throw const DocumentoRecusadoException(
        'CNPJ_NAO_E_ENTIDADE',
        'Este CNPJ não é de uma entidade sem fins lucrativos. Para se '
            'cadastrar como ONG, use o CNPJ da associação ou fundação.',
      );
    }
    return info;
  }

  /// Mesma regra de [_conferir], mas sem lançar exceção (usada pelo job).
  bool _aceito(InfoCnpj info, TipoUsuario tipo) =>
      info.ativa && (tipo == TipoUsuario.doador || info.semFinsLucrativos);
}
