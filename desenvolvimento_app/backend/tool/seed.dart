import 'package:shared_models/shared_models.dart';
import 'package:summit_backend/core/config/env.dart';
import 'package:summit_backend/core/db/database.dart';
import 'package:summit_backend/core/seguranca/senha_service.dart';

import 'seed/comunidade_de_exemplo.dart';
import 'seed/contas_de_exemplo.dart';
import 'seed/doacoes_de_exemplo.dart';
import 'seed/gravador_de_exemplos.dart';

/// Recria os DADOS DE EXEMPLO. ATENÇÃO: apaga os dados atuais do banco.
///
/// Uso, dentro da pasta `backend`:
///
///     dart run tool/seed.dart
///
/// Todos os usuários têm a senha `senha123` e ficam em Mogi das Cruzes (SP),
/// menos a ONG "distante" (São Paulo, ~45 km, fora do raio de 10 km).
/// As partes ficam na pasta `tool/seed/`: contas, doações e comunidade.
Future<void> main() async {
  final env = Env.carregar();
  final banco = Database.conectar(env);
  final exemplos = GravadorDeExemplos(
    banco,
    senhaHash: const SenhaService().gerarHash('senha123'),
    pastaArquivos: env.pastaArquivos,
  );
  final agora = const RelogioSistema().agora();

  try {
    await exemplos.apagarTudo();
    await exemplos.apagarFotos();
    final contas = await ContasDeExemplo.criar(exemplos, agora);
    final doacoes = DoacoesDeExemplo(
      exemplos,
      contas,
      agora: agora,
      hoje: Calendario.dataNoFuso(agora, env.fusoHorarioUtc),
      prazoReserva: env.regrasDaRetirada.prazo,
    );
    await doacoes.criar();
    await criarComunidadeDeExemplo(
      exemplos,
      contas,
      agora: agora,
      doacoesConcluidas: doacoes.concluidas,
    );
    print(_resumo);
  } finally {
    await banco.fechar();
  }
}

const _resumo = '''
Dados de exemplo criados. Senha de todos os usuários: senha123

  doador  mercado@exemplo.com     Mercado Bom Preço (CNPJ, verificado)
  doador  padaria@exemplo.com     Padaria Pão Quente (CNPJ, verificado)
  doador  feirante@exemplo.com    Banca do Zé (CPF, verificação pendente)
  ong     maosamigas@exemplo.com  ONG Mãos Amigas: retirada em andamento (código 4821)
  ong     pratocheio@exemplo.com  Instituto Prato Cheio: 2 desistências
  ong     suspensa@exemplo.com    Casa Esperança: suspensa por 30 h
  ong     distante@exemplo.com    Associação Distante (~45 km, fora do raio)

Doações: 5 disponíveis (4 com foto), 1 reservada, 2 concluídas e 3 expiradas.
Comunidade: 4 publicações. Chat: 1 conversa (mercado e Mãos Amigas).
''';
