import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

/// Termos de Uso e Política de Privacidade (etapa 5 do cadastro).
///
/// Texto simples, em uma tela. TODO(grupo): revisar o texto com o
/// professor antes da apresentação.
class TermosPage extends StatelessWidget {
  const TermosPage({super.key});

  static const _secoes = [
    _Secao(
      'O que é o app',
      'O ${AppConfig.nomeApp} é um projeto acadêmico que liga doadores de '
          'alimentos (mercados, feiras, padarias, restaurantes) a ONGs '
          'próximas. O app não vende nada e não cobra pelo uso.',
    ),
    _Secao(
      'Responsabilidades',
      'O doador declara que os alimentos estão dentro da validade e '
          'próprios para consumo. A ONG se compromete a retirar no prazo '
          'combinado e a usar os alimentos só para as pessoas que atende.',
    ),
    _Secao(
      'Dados que coletamos (LGPD)',
      'Nome do responsável, e-mail, telefone, CNPJ ou CPF, endereço e '
          'localização da organização. Usamos esses dados só para o '
          'funcionamento do app: mostrar doações próximas, avisar sobre '
          'novidades e permitir o contato entre doador e ONG.',
    ),
    _Secao(
      'Com quem compartilhamos',
      'O doador vê o nome, o telefone e o selo de verificação da ONG que '
          'aceitou a doação, e a ONG vê os dados do doador. Não vendemos nem '
          'repassamos dados a terceiros. O CNPJ é consultado em uma base '
          'pública da Receita Federal (BrasilAPI).',
    ),
    _Secao(
      'Seus direitos',
      'Pela Lei Geral de Proteção de Dados (Lei nº 13.709/2018), você pode '
          'pedir para ver, corrigir ou apagar os seus dados a qualquer '
          'momento, falando com a equipe do projeto.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Termos e Privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final secao in _secoes) ...[
            Text(secao.titulo, style: estilos.titleMedium),
            const SizedBox(height: 8),
            Text(secao.texto, style: estilos.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

/// Um título e o texto de uma parte dos termos.
class _Secao {
  const _Secao(this.titulo, this.texto);

  final String titulo;
  final String texto;
}
