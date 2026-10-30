# ADR-003 — MySQL 8.4 LTS instalado nativamente; Docker opcional

- Status: Aceita
- Data: 2026-09-15

## Contexto
O grupo escolheu MySQL. A versão 8.0 saiu de suporte em abril/2026. A ideia inicial era usar Docker para que todos tivessem o mesmo banco, mas ninguém da equipe usou Docker antes, e no Windows ele exige WSL2, virtualização habilitada e bastante RAM, que também é disputada pelo emulador Android.

## Decisão
- **MySQL Community Server 8.4 LTS** instalado pelo MSI oficial, configurado pelo **MySQL Configurator**, com o **MySQL Workbench** como interface visual.
- A igualdade entre os bancos é garantida pelos **scripts SQL versionados** em `database/` e pelo seed em Dart (`backend/tool/seed.dart`).
- O `database/docker-compose.yml` fica como **alternativa opcional**.

## Alternativas consideradas
- **Docker obrigatório**: custo de aprendizado e de hardware sem benefício real, já que cada um usa o próprio banco local.
- **XAMPP**: traz MariaDB, não MySQL; as diferenças de autenticação e de recursos confundiriam o grupo.
- **MySQL 9.x (Innovation)**: suporte curto; o LTS é mais estável para um semestre.

## Consequências
- Positivas: instalação de cerca de 15 minutos, consumo baixo de memória e Workbench para visualizar tabelas e consultas.
- Cuidados: cada pessoa precisa criar o banco rodando os scripts, e mudanças de estrutura vão para `database/migracoes/` (nunca editar um script já aplicado pelos colegas).
