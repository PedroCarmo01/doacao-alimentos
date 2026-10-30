import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';
import '../../shared/widgets/foto_da_doacao.dart';
import '../../shared/widgets/selo_verificacao.dart';

/// T12 — fotos para deslizar (ou o ícone da categoria, se não houver).
class GaleriaDeFotos extends StatelessWidget {
  const GaleriaDeFotos({super.key, required this.doacao});

  final Doacao doacao;

  @override
  Widget build(BuildContext context) {
    final fotos = doacao.fotos;
    return SizedBox(
      height: 220,
      child: fotos.isEmpty
          ? FotoDaDoacao(caminho: null, categoria: doacao.categoria, raio: 0)
          : PageView(
              children: [
                for (var i = 0; i < fotos.length; i++)
                  Semantics(
                    label: 'Foto ${i + 1} de ${fotos.length}',
                    child: FotoDaDoacao(caminho: fotos[i], raio: 0),
                  ),
              ],
            ),
    );
  }
}

/// Os dados da doação, um por linha (ícone + rótulo + valor).
class DadosDaDoacao extends StatelessWidget {
  const DadosDaDoacao({super.key, required this.doacao});

  final Doacao doacao;

  @override
  Widget build(BuildContext context) {
    final preparo = doacao.preparadoEm;
    final veiculo = doacao.veiculo;
    final descricao = doacao.descricao;
    return Column(
      children: [
        _Dado(Icons.category_outlined, 'Categoria', doacao.categoria.rotulo),
        _Dado(
          Icons.inventory_2_outlined,
          'Quantidade',
          '${doacao.quantidadeTexto} • ${Formatador.peso(doacao.pesoKg)}',
        ),
        _Dado(Icons.ac_unit, 'Conservação', doacao.conservacao.rotulo),
        _Dado(Icons.event, 'Validade', Formatador.data(doacao.validade)),
        if (preparo != null)
          _Dado(
            Icons.soup_kitchen,
            'Preparada em',
            Formatador.diaHora(preparo),
          ),
        _Dado(
          Icons.schedule,
          'Retirada',
          'de ${Formatador.diaHora(doacao.janelaInicio)} '
              'até ${Formatador.diaHora(doacao.janelaFim)}',
        ),
        _Dado(Icons.place_outlined, 'Endereço', doacao.endereco ?? '—'),
        if (veiculo != null)
          _Dado(Icons.local_shipping_outlined, 'Transporte', veiculo.rotulo),
        if (descricao != null) _Dado(Icons.notes, 'Observações', descricao),
      ],
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado(this.icone, this.rotulo, this.valor);

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icone, color: AppColors.verde),
    title: Text(rotulo, style: const TextStyle(color: AppColors.cinza)),
    subtitle: Text(valor, style: const TextStyle(fontSize: 16)),
  );
}

/// T12 — linha do tempo: Publicada → Reservada → Retirada.
class LinhaDoTempo extends StatelessWidget {
  const LinhaDoTempo({super.key, required this.detalhe, required this.agora});

  final DetalheDoacao detalhe;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final doacao = detalhe.doacao;
    final reserva = detalhe.reserva;
    final status = doacao.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Passo(
          feito: true,
          texto: 'Publicada  ${Formatador.diaHora(doacao.criadoEm)}',
        ),
        if (reserva != null)
          _Passo(
            feito: true,
            texto:
                'Reservada  ${Formatador.hora(reserva.reservadoEm)}  por '
                '${detalhe.ong?.nomeOrganizacao ?? reserva.nomeOng ?? 'ONG'}',
          ),
        if (status == StatusDoacao.reservada && reserva != null)
          _Passo(
            feito: false,
            texto:
                'Retirada  (aguardando — faltam '
                '${Formatador.duracaoCurta(reserva.tempoRestante(agora))})',
          ),
        if (status == StatusDoacao.disponivel)
          const _Passo(feito: false, texto: 'Aguardando uma ONG aceitar'),
        if (!status.ativa) _Passo(feito: true, texto: status.rotulo),
      ],
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.feito, required this.texto});

  final bool feito;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          feito ? Icons.circle : Icons.radio_button_unchecked,
          size: 14,
          color: feito ? AppColors.verde : AppColors.cinza,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(texto)),
      ],
    ),
  );
}

/// T12 — quando reservada: a ONG que vem buscar, com o selo de verificação.
class CartaoDaOng extends StatelessWidget {
  const CartaoDaOng({super.key, required this.ong});

  final ResumoOrganizacao ong;

  @override
  Widget build(BuildContext context) {
    final transporte = ong.transporte;
    return Card(
      elevation: 0,
      color: AppColors.verdeClaro,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ong.nomeOrganizacao,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            SeloVerificacao(verificacao: ong.verificacao),
            const SizedBox(height: 8),
            if (ong.nomeResponsavel != null)
              Text('Responsável: ${ong.nomeResponsavel}'),
            if (ong.telefone != null) Text('Telefone: ${ong.telefone}'),
            if (transporte != null) Text('Vem de: ${transporte.rotulo}'),
          ],
        ),
      ),
    );
  }
}
