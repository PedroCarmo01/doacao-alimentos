import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/reservas/reserva_repository.dart';
import '../../shared/widgets/primary_button.dart';
import 'confirmar_retirada_view_model.dart';

/// T13 — Confirmar retirada (doador): tela grande e simples com o campo do
/// código de 4 dígitos (RN27). Ao confirmar, mostra "Retirada confirmada!"
/// e devolve `true` para o detalhe recarregar.
class ConfirmarRetiradaPage extends StatefulWidget {
  const ConfirmarRetiradaPage({
    super.key,
    required this.reservaId,
    required this.reservas,
  });

  final int reservaId;
  final ReservaRepository reservas;

  @override
  State<ConfirmarRetiradaPage> createState() => _ConfirmarRetiradaPageState();
}

class _ConfirmarRetiradaPageState extends State<ConfirmarRetiradaPage> {
  late final ConfirmarRetiradaViewModel _viewModel;
  final _codigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ConfirmarRetiradaViewModel(
      reservas: widget.reservas,
      reservaId: widget.reservaId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Confirmar retirada')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _viewModel.confirmada ? _sucesso() : _formulario(),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return ListView(
      children: [
        const Icon(Icons.pin, size: 72, color: AppColors.verde),
        const SizedBox(height: 16),
        const Text(
          'Peça à ONG o código de retirada que aparece no celular dela.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 24),
        // Um campo só, com letras grandes e espaçadas: parece as "4
        // caixinhas" e é mais simples (e acessível) que 4 campos separados.
        TextField(
          key: const Key('campo_codigo'),
          controller: _codigo,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 40,
            letterSpacing: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '0000',
            counterText: '',
            errorText: _viewModel.erro,
            errorMaxLines: 3,
          ),
          onSubmitted: (_) => _viewModel.confirmar(_codigo.text),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          key: const Key('botao_confirmar_codigo'),
          texto: 'Confirmar retirada',
          carregando: _viewModel.ocupado,
          onPressed: () => _viewModel.confirmar(_codigo.text),
        ),
      ],
    );
  }

  Widget _sucesso() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 96, color: AppColors.verde),
        const SizedBox(height: 16),
        Text(
          'Retirada confirmada!',
          key: const Key('retirada_confirmada'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Obrigado por evitar o desperdício.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          texto: 'Voltar para a doação',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
