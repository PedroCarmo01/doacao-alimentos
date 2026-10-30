import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatador.dart';

/// Mostra quanto falta até [expiraEm] (HH:MM:SS) e atualiza a cada segundo.
///
/// Quando o tempo acaba, chama [aoExpirar] UMA vez (por exemplo, para o
/// ViewModel recarregar a lista).
class ContadorRegressivo extends StatefulWidget {
  const ContadorRegressivo({super.key, required this.expiraEm, this.aoExpirar});

  final DateTime expiraEm;
  final VoidCallback? aoExpirar;

  @override
  State<ContadorRegressivo> createState() => _ContadorRegressivoState();
}

class _ContadorRegressivoState extends State<ContadorRegressivo> {
  Timer? _timer;
  Duration _restante = Duration.zero;
  bool _avisou = false;

  @override
  void initState() {
    super.initState();
    _atualizar();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _atualizar());
  }

  void _atualizar() {
    final diferenca = widget.expiraEm.difference(DateTime.now());
    final restante = diferenca.isNegative ? Duration.zero : diferenca;
    setState(() => _restante = restante);
    if (restante == Duration.zero && !_avisou) {
      _avisou = true;
      _timer?.cancel();
      widget.aoExpirar?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // sem isso o timer continuaria rodando (vazamento)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acabou = _restante == Duration.zero;
    final cor = acabou ? AppColors.erro : AppColors.laranja;
    return Semantics(
      label: acabou
          ? 'Prazo esgotado'
          : 'Tempo restante ${Formatador.duracao(_restante)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 18, color: cor),
          const SizedBox(width: 6),
          Text(
            acabou ? 'Prazo esgotado' : Formatador.duracao(_restante),
            style: TextStyle(color: cor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
