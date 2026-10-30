import 'package:flutter/widgets.dart';

import 'campos_do_cadastro.dart';

/// Os controladores de texto de todos os campos do cadastro, juntos.
///
/// Ficam na TELA (são coisa do Flutter) e continuam vivos quando a pessoa
/// vai e volta entre os passos, então nada do que ela digitou se perde.
class ControladoresDoCadastro {
  final documento = TextEditingController();
  final nomeOrganizacao = TextEditingController();
  final nomeResponsavel = TextEditingController();
  final telefone = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final familiasAtendidas = TextEditingController();
  final infoExtra = TextEditingController();
  final cep = TextEditingController();
  final endereco = TextEditingController();

  /// Fotografia dos textos, para entregar ao ViewModel.
  CamposDoCadastro campos() => CamposDoCadastro(
    documento: documento.text,
    nomeOrganizacao: nomeOrganizacao.text,
    nomeResponsavel: nomeResponsavel.text,
    telefone: telefone.text,
    email: email.text,
    senha: senha.text,
    familiasAtendidas: familiasAtendidas.text,
    infoExtra: infoExtra.text,
    cep: cep.text,
    endereco: endereco.text,
  );

  void dispose() {
    for (final controlador in [
      documento,
      nomeOrganizacao,
      nomeResponsavel,
      telefone,
      email,
      senha,
      familiasAtendidas,
      infoExtra,
      cep,
      endereco,
    ]) {
      controlador.dispose();
    }
  }
}
