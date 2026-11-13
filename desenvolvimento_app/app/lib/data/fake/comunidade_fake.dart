import 'package:shared_models/shared_models.dart';

import '../../core/api/api_exception.dart';
import 'contas_fake.dart';
import 'doacoes_fake.dart';
import 'notificacoes_fake.dart';

/// A Comunidade do modo Fake: as MESMAS regras do `ComunidadeService` do
/// backend (RN40–RN42) e as mesmas 2 publicações de exemplo do seed.
class ComunidadeFake {
  ComunidadeFake(this._relogio, this._contas, this._doacoes, this._avisos);

  final Relogio _relogio;
  final ContasFake _contas;
  final DoacoesFake _doacoes;
  final NotificacoesFake _avisos;

  final List<Publicacao> _publicacoes = [];
  final Set<String> _apoios = {}; // "publicação-usuário" (RN41)
  final Set<String> _denuncias = {}; // "publicação-usuário" (RN42)
  final Set<int> _ocultas = {};

  static const denunciasParaOcultar = 3;
  static const _naoEncontrada = ApiException(
    codigo: 'NAO_ENCONTRADO',
    mensagem: 'Publicação não encontrada.',
    status: 404,
  );

  DateTime get _agora => _relogio.agora();

  /// As 2 publicações de exemplo, como no seed (sem doação ligada).
  void criarExemplos() {
    Conta conta(String email) => _contas.porEmail(email);

    final cestas = _criar(
      conta('pratocheio@exemplo.com'),
      const DadosPublicacao(
        texto:
            'Com os mantimentos do Mercado Bom Preço montamos 40 cestas '
            'básicas esta semana: arroz, feijão, macarrão, farinha de milho, '
            'açúcar e óleo. Obrigado pela parceria!',
        familiasAjudadas: 40,
      ),
      _agora.subtract(const Duration(days: 2)),
      fotos: const ['assets/exemplos/mantimentos.jpg'],
    );
    final cafe = _criar(
      conta('maosamigas@exemplo.com'),
      const DadosPublicacao(
        texto:
            'Os pães do dia da Padaria Pão Quente viraram o café da manhã '
            'de 80 pessoas no nosso projeto. Nada foi para o lixo!',
        refeicoes: 80,
      ),
      _agora.subtract(const Duration(days: 1)),
      fotos: const ['assets/exemplos/paes.jpg'],
    );
    final mercado = conta('mercado@exemplo.com').usuario.id;
    final padaria = conta('padaria@exemplo.com').usuario.id;
    _apoios.addAll(['${cestas.id}-$mercado', '${cafe.id}-$padaria']);
  }

  Impacto impacto() {
    var kg = 0.0;
    var concluidas = 0;
    for (final d in _doacoes.doacoes) {
      if (d.status == StatusDoacao.concluida) {
        concluidas++;
        kg += d.pesoKg;
      }
    }
    var familias = 0;
    var refeicoes = 0;
    for (final p in _publicacoes) {
      if (_ocultas.contains(p.id)) continue;
      familias += p.familiasAjudadas ?? 0;
      refeicoes += p.refeicoes ?? 0;
    }
    return Impacto(
      kgSalvos: kg,
      doacoesConcluidas: concluidas,
      familiasAjudadas: familias,
      refeicoes: refeicoes,
    );
  }

  List<Publicacao> feed(Conta leitor, int antesDe) => [
    for (final p in _publicacoes.reversed)
      if (!_ocultas.contains(p.id) && (antesDe == 0 || p.id < antesDe))
        _paraLeitor(p, leitor),
  ].take(20).toList();

  /// RN40: texto obrigatório; a doação ligada precisa estar concluída e
  /// ter a participação de quem publica.
  Publicacao publicar(Conta autor, DadosPublicacao dados) {
    final erros = dados.validar();
    if (erros.isNotEmpty) {
      throw ApiException(
        codigo: 'VALIDACAO',
        mensagem: erros.first,
        status: 400,
        detalhes: erros,
      );
    }
    final doacaoId = dados.doacaoId;
    if (doacaoId != null && !_participou(autor, doacaoId)) {
      throw const ApiException(
        codigo: 'VALIDACAO',
        mensagem:
            'Só dá para ligar a publicação a uma doação concluída da qual '
            'você participou.',
        status: 400,
      );
    }
    return _paraLeitor(_criar(autor, dados, _agora), autor);
  }

  Publicacao adicionarFoto(Conta autor, int id, String caminho) {
    final atual = _porId(id);
    if (atual.autorId != autor.usuario.id) throw _naoEncontrada;
    if (atual.fotos.length >= Publicacao.maximoDeFotos) {
      throw const ApiException(
        codigo: 'LIMITE_DE_FOTOS',
        mensagem: 'Cada publicação pode ter no máximo 3 fotos.',
        status: 409,
      );
    }
    _trocar(
      Publicacao.fromJson({
        ...atual.toJson(),
        'fotos': [...atual.fotos, caminho],
      }),
    );
    return _paraLeitor(_porId(id), autor);
  }

  /// RN41: uma vez por conta; o autor é avisado.
  Publicacao apoiar(Conta conta, int id, {required bool apoiar}) {
    final publicacao = _visivel(id);
    final chave = '$id-${conta.usuario.id}';
    if (apoiar) {
      final novo = _apoios.add(chave);
      if (novo && publicacao.autorId != conta.usuario.id) {
        _avisos.avisar(
          publicacao.autorId,
          TipoNotificacao.apoioNovo,
          titulo: 'Apoio na Comunidade',
          corpo: '${conta.perfil.nomeOrganizacao} apoiou sua publicação.',
        );
      }
    } else {
      _apoios.remove(chave);
    }
    return _paraLeitor(publicacao, conta);
  }

  /// RN42: uma por conta; com 3 contas diferentes, fica oculta.
  void denunciar(Conta conta, int id) {
    final publicacao = _visivel(id);
    if (publicacao.autorId == conta.usuario.id) {
      throw const ApiException(
        codigo: 'VALIDACAO',
        mensagem: 'Você não pode denunciar a sua própria publicação.',
        status: 400,
      );
    }
    _denuncias.add('$id-${conta.usuario.id}');
    final total = _denuncias.where((d) => d.startsWith('$id-')).length;
    if (total >= denunciasParaOcultar) _ocultas.add(id);
  }

  // ----------------------------------------------------------- internos

  Publicacao _criar(
    Conta autor,
    DadosPublicacao dados,
    DateTime em, {
    List<String> fotos = const [],
  }) {
    final doacao = dados.doacaoId == null
        ? null
        : _doacoes.doacoes.where((d) => d.id == dados.doacaoId).firstOrNull;
    final publicacao = Publicacao(
      id: _publicacoes.length + 1,
      autorId: autor.usuario.id,
      nomeAutor: autor.perfil.nomeOrganizacao,
      tipoAutor: autor.usuario.tipo,
      verificacaoAutor: autor.perfil.verificacao,
      texto: dados.texto.trim(),
      criadoEm: em,
      fotos: fotos,
      doacaoId: doacao?.id,
      resumoDoacao: doacao == null ? null : _resumo(doacao),
      familiasAjudadas: dados.familiasAjudadas,
      refeicoes: dados.refeicoes,
    );
    _publicacoes.add(publicacao);
    return publicacao;
  }

  String _resumo(Doacao doacao) {
    final retirada = _doacoes.reservas
        .where(
          (r) => r.doacaoId == doacao.id && r.status == StatusReserva.concluida,
        )
        .firstOrNull;
    final ong = retirada == null
        ? null
        : _contas.porId(retirada.ongId)?.perfil.nomeOrganizacao;
    return '${doacao.titulo} — ${doacao.nomeDoador}'
        '${ong == null ? '' : ' → $ong'}';
  }

  bool _participou(Conta conta, int doacaoId) {
    final doacao = _doacoes.doacoes.where((d) => d.id == doacaoId).firstOrNull;
    if (doacao == null || doacao.status != StatusDoacao.concluida) {
      return false;
    }
    final eu = conta.usuario.id;
    return doacao.doadorId == eu ||
        _doacoes.reservas.any(
          (r) =>
              r.doacaoId == doacaoId &&
              r.ongId == eu &&
              r.status == StatusReserva.concluida,
        );
  }

  /// Os campos que dependem de quem está lendo (apoios e "apoiei").
  Publicacao _paraLeitor(Publicacao p, Conta leitor) => Publicacao.fromJson({
    ...p.toJson(),
    'apoios': _apoios.where((a) => a.startsWith('${p.id}-')).length,
    'apoiadaPorMim': _apoios.contains('${p.id}-${leitor.usuario.id}'),
  });

  Publicacao _porId(int id) =>
      _publicacoes.where((p) => p.id == id).firstOrNull ??
      (throw _naoEncontrada);

  Publicacao _visivel(int id) {
    if (_ocultas.contains(id)) throw _naoEncontrada;
    return _porId(id);
  }

  void _trocar(Publicacao nova) =>
      _publicacoes[_publicacoes.indexWhere((p) => p.id == nova.id)] = nova;
}
