import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../shared/widgets/foto_da_doacao.dart';
import '../../shared/widgets/selo_verificacao.dart';

/// Uma publicação do feed (T40): autor com selo, texto, fotos, o cartão da
/// doação ligada, os números e as ações (Apoiar ❤ e o menu Denunciar).
class CartaoDaPublicacao extends StatelessWidget {
  const CartaoDaPublicacao({
    super.key,
    required this.publicacao,
    required this.minha,
    required this.aoApoiar,
    required this.aoDenunciar,
  });

  final Publicacao publicacao;

  /// A minha não tem "Denunciar".
  final bool minha;
  final VoidCallback aoApoiar;
  final VoidCallback aoDenunciar;

  @override
  Widget build(BuildContext context) {
    final p = publicacao;
    final resumo = p.resumoDoacao;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _autor(context),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(p.texto, style: const TextStyle(fontSize: 16)),
            ),
            if (p.fotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final foto in p.fotos)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FotoDaDoacao(caminho: foto, tamanho: 120),
                      ),
                  ],
                ),
              ),
            ],
            if (resumo != null) ...[
              const SizedBox(height: 8),
              _CartaoDaDoacao(resumo: resumo),
            ],
            if (_numeros != null) ...[
              const SizedBox(height: 8),
              Text(
                _numeros!,
                style: const TextStyle(
                  color: AppColors.verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            _botaoApoiar(),
          ],
        ),
      ),
    );
  }

  /// "40 famílias • 160 refeições"
  String? get _numeros {
    final partes = [
      if (publicacao.familiasAjudadas != null)
        '${publicacao.familiasAjudadas} famílias',
      if (publicacao.refeicoes != null) '${publicacao.refeicoes} refeições',
    ];
    return partes.isEmpty ? null : partes.join(' • ');
  }

  Widget _autor(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.verdeClaro,
          child: Icon(
            publicacao.tipoAutor == TipoUsuario.ong
                ? Icons.groups
                : Icons.storefront,
            color: AppColors.verde,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                publicacao.nomeAutor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                Formatador.diaHora(publicacao.criadoEm),
                style: const TextStyle(color: AppColors.cinza, fontSize: 12),
              ),
            ],
          ),
        ),
        SeloVerificacao(verificacao: publicacao.verificacaoAutor),
        if (minha)
          const SizedBox(width: 12)
        else
          PopupMenuButton<void>(
            tooltip: 'Mais opções',
            itemBuilder: (_) => [
              PopupMenuItem<void>(
                onTap: aoDenunciar,
                child: const Text('Denunciar'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _botaoApoiar() {
    final apoiada = publicacao.apoiadaPorMim;
    return TextButton.icon(
      key: Key('apoiar_${publicacao.id}'),
      onPressed: aoApoiar,
      icon: Icon(
        apoiada ? Icons.favorite : Icons.favorite_border,
        color: apoiada ? AppColors.erro : AppColors.cinza,
      ),
      label: Text(
        '${apoiada ? 'Apoiado' : 'Apoiar'} • ${publicacao.apoios}',
        style: const TextStyle(color: AppColors.cinza),
      ),
    );
  }
}

/// "Doação: Pães do dia — Padaria Pão Quente → ONG Mãos Amigas"
class _CartaoDaDoacao extends StatelessWidget {
  const _CartaoDaDoacao({required this.resumo});

  final String resumo;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.verdeClaro,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.volunteer_activism, color: AppColors.verde),
        const SizedBox(width: 8),
        Expanded(child: Text('Doação: $resumo')),
      ],
    ),
  );
}
