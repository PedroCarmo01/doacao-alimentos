import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padronizado do app, com label, ícone e validação.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.sufixo,
    this.textoAjuda,
    this.erro,
    this.somenteNumeros = false,
    this.tamanhoMaximo,
    this.aoMudar,
    this.acaoDoTeclado = TextInputAction.next,
    this.preenchimentoAutomatico,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  /// Widget no fim do campo (ex.: o "olho" que mostra a senha).
  final Widget? sufixo;

  /// Texto pequeno embaixo do campo (ex.: o CNPJ com a máscara).
  final String? textoAjuda;

  /// Erro vindo de fora do formulário (ex.: o servidor recusou o CNPJ).
  final String? erro;

  /// Aceita só dígitos (CNPJ, CPF, CEP, telefone).
  final bool somenteNumeros;
  final int? tamanhoMaximo;
  final ValueChanged<String>? aoMudar;
  final TextInputAction acaoDoTeclado;

  /// Ajuda o teclado do Android a sugerir e-mail e senha salvos.
  final Iterable<String>? preenchimentoAutomatico;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: somenteNumeros ? TextInputType.number : keyboardType,
        textInputAction: acaoDoTeclado,
        autofillHints: preenchimentoAutomatico,
        validator: validator,
        // Depois que a pessoa mexe no campo, ele se confere sozinho: o erro
        // some assim que o valor fica certo (sem esperar o "Continuar").
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: aoMudar,
        inputFormatters: [
          if (somenteNumeros) FilteringTextInputFormatter.digitsOnly,
          if (tamanhoMaximo != null)
            LengthLimitingTextInputFormatter(tamanhoMaximo),
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: textoAjuda,
          errorText: erro,
          errorMaxLines: 3,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: sufixo,
        ),
      ),
    );
  }
}
