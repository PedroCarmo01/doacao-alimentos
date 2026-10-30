import 'package:shared_models/shared_models.dart';

import '../core/erros/app_exception.dart';
import '../core/seguranca/senha_service.dart';
import '../core/seguranca/token_service.dart';
import '../core/seguranca/usuario_autenticado.dart';
import '../documentos/documento_service.dart';
import 'usuario_repository.dart';

/// Regras de cadastro e login (RN01 a RN05, telas T3 e T4).
///
/// Não conhece HTTP nem SQL: recebe dados, aplica regras, devolve modelos
/// ou lança exceções. Isso o torna fácil de testar.
class AuthService {
  AuthService({
    required UsuarioRepository usuarios,
    required DocumentoService documentos,
    required SenhaService senhas,
    required TokenService tokens,
    required Relogio relogio,
  }) : _usuarios = usuarios,
       _documentos = documentos,
       _senhas = senhas,
       _tokens = tokens,
       _relogio = relogio;

  final UsuarioRepository _usuarios;
  final DocumentoService _documentos;
  final SenhaService _senhas;
  final TokenService _tokens;
  final Relogio _relogio;

  /// Mesma mensagem para e-mail inexistente e senha errada: assim ninguém
  /// descobre quais e-mails têm conta no app.
  static const _credenciaisInvalidas = NaoAutenticadoException(
    codigo: 'CREDENCIAIS_INVALIDAS',
    mensagem: 'E-mail ou senha incorretos.',
  );

  Future<RespostaAutenticacao> cadastrar(DadosCadastro recebidos) async {
    // 1. Limpa espaços, máscara do documento e campos do outro tipo (RN01).
    final dados = recebidos.normalizado();

    // 2. As MESMAS regras do formulário do app (shared_models), incluindo
    //    os dígitos do CNPJ/CPF (RN02).
    final erros = ValidadorUsuario.validarCadastro(dados);
    if (erros.isNotEmpty) {
      throw ValidacaoException(erros.first, detalhes: erros);
    }

    // 3. RN04: e-mail e documento únicos (o banco também garante, com os
    //    índices uk_usuarios_email e uk_perfis_documento).
    if (await _usuarios.emailEmUso(dados.email)) {
      throw const ConflitoException(
        'EMAIL_EM_USO',
        'Este e-mail já está cadastrado. Entre com ele ou use outro.',
      );
    }
    if (await _usuarios.documentoEmUso(dados.documento)) {
      throw ConflitoException(
        'DOCUMENTO_EM_USO',
        'Já existe uma conta com este ${dados.tipoDocumento.rotulo}.',
      );
    }

    // 4. RN03: consulta a Receita. Recusa CNPJ inexistente, inativo ou de
    //    empresa (para ONG). Se não der para consultar, segue "pendente".
    final infoCnpj = await _documentos.conferirParaCadastro(
      dados.documento,
      dados.tipo,
    );

    // 5. Grava com a senha transformada em hash.
    final conta = await _usuarios.criar(
      dados,
      senhaHash: _senhas.gerarHash(dados.senha),
      criadoEm: _relogio.agora(),
      verificacao: infoCnpj == null
          ? Verificacao.pendente
          : Verificacao.verificada,
      razaoSocial: infoCnpj?.razaoSocial,
    );
    return _respostaPara(conta);
  }

  Future<RespostaAutenticacao> entrar(DadosLogin dados) async {
    final email = dados.email.trim().toLowerCase();
    if (email.isEmpty || dados.senha.isEmpty) throw _credenciaisInvalidas;

    final registro = await _usuarios.buscarPorEmail(email);
    if (registro == null || !_senhas.confere(dados.senha, registro.senhaHash)) {
      throw _credenciaisInvalidas;
    }
    return _respostaPara(registro.conta);
  }

  /// `GET /auth/me`: a conta do dono do token (usada na tela de abertura).
  Future<Conta> contaDe(UsuarioAutenticado usuario) async {
    final conta = await _usuarios.buscarConta(usuario.id);
    if (conta == null) {
      // Token válido, mas o usuário não existe mais (ex.: banco recriado).
      throw const NaoAutenticadoException(
        codigo: 'TOKEN_INVALIDO',
        mensagem: 'Sessão inválida. Entre novamente.',
      );
    }
    return conta;
  }

  /// RN05: o token vale o tempo configurado no `TokenService`
  /// (JWT_VALIDADE_DIAS, 30 dias por padrão).
  RespostaAutenticacao _respostaPara(Conta conta) => RespostaAutenticacao(
    token: _tokens.gerar(usuarioId: conta.usuario.id, tipo: conta.usuario.tipo),
    conta: conta,
  );
}
