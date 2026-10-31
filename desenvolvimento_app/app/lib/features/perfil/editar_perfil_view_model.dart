import 'package:shared_models/shared_models.dart';

import '../../core/erros/erro_amigavel.dart';
import '../../core/mvvm/view_model_base.dart';
import '../../core/sessao/sessao.dart';
import '../../data/localizacao/cep_repository.dart';
import '../../data/localizacao/localizacao_service.dart';
import '../../data/perfil/perfil_repository.dart';

/// ViewModel de "Editar dados" (T50): nome, organização, telefone,
/// endereço, localização e, para a ONG, famílias e transporte.
///
/// A localização (o ponto no mapa) só muda se a pessoa pedir: pelo CEP ou
/// pelo GPS. É ela que decide quais doações a ONG vê (etapa 3).
class EditarPerfilViewModel extends ViewModelBase {
  EditarPerfilViewModel({
    required Sessao sessao,
    required PerfilRepository perfis,
    required CepRepository cep,
    required LocalizacaoService localizacao,
  }) : _sessao = sessao,
       _perfis = perfis,
       _cep = cep,
       _localizacao = localizacao {
    final perfil = sessao.conta!.perfil;
    _coordenadas = perfil.coordenadas;
    _transporte = perfil.transporte;
  }

  final Sessao _sessao;
  final PerfilRepository _perfis;
  final CepRepository _cep;
  final LocalizacaoService _localizacao;

  late Coordenadas _coordenadas;
  Transporte? _transporte;
  bool _localizacaoMudou = false;

  Conta get conta => _sessao.conta!;
  bool get ehOng => conta.usuario.ehOng;
  Transporte? get transporte => _transporte;

  /// Para a tela avisar "a localização vai mudar".
  bool get localizacaoMudou => _localizacaoMudou;

  void escolherTransporte(Transporte? transporte) {
    _transporte = transporte;
    notificar();
  }

  /// Busca o CEP. Devolve o endereço para a tela preencher o campo; se o
  /// CEP tiver coordenadas, a localização muda junto.
  Future<String?> buscarCep(String cep) async {
    String? endereco;
    await executar(() async {
      final achado = await _cep.buscar(cep);
      endereco = achado.textoParaEndereco;
      final ponto = achado.coordenadas;
      if (ponto != null) _mudarLocal(ponto);
    });
    return endereco;
  }

  /// Usa o GPS do celular como o novo ponto da organização.
  Future<bool> usarLocalizacaoAtual() => executar(() async {
    _mudarLocal(await _localizacao.obterAtual());
  });

  /// Valida (as mesmas regras do servidor) e salva.
  Future<bool> salvar({
    required String nome,
    required String nomeOrganizacao,
    required String telefone,
    required String endereco,
    required String cep,
    required String familias,
  }) => executar(() async {
    final perfil = conta.perfil;
    final dados = DadosPerfil(
      nome: nome,
      nomeOrganizacao: nomeOrganizacao,
      telefone: telefone,
      endereco: endereco,
      cep: cep,
      latitude: _coordenadas.latitude,
      longitude: _coordenadas.longitude,
      familiasAtendidas: ehOng ? int.tryParse(familias.trim()) : null,
      transporte: ehOng ? _transporte : null,
      infoExtra: perfil.infoExtra,
      buscaAtiva: perfil.buscaAtiva,
      raioKm: perfil.raioKm,
    ).normalizado();
    final erros = ValidadorUsuario.validarPerfil(dados);
    if (erros.isNotEmpty) throw ErroDeRegra(erros.first);
    _sessao.restaurar(await _perfis.atualizar(dados));
  });

  void _mudarLocal(Coordenadas ponto) {
    _coordenadas = ponto;
    _localizacaoMudou = true;
  }
}
