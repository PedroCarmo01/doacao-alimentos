# 03 — Ambiente no Windows com VS Code

**Objetivo:** cada pessoa terminar com Git, Flutter/Dart, Android, Dart Frog, MySQL e VS Code funcionando.
**Quem:** todos, na **máquina pessoal**. Façam juntos em uma chamada: quem travar recebe ajuda na hora.
**Tempo:** 2 a 3 horas (a maior parte é download).

---

## 0. Antes de começar

| Item | Recomendado |
|---|---|
| Windows | 10 ou 11, 64 bits |
| RAM | 8 GB funciona; 16 GB é confortável |
| Disco livre | 20 GB |
| Internet | Boa, para os downloads |

> **PC com pouca memória?** O emulador Android é o que mais pesa. Alternativas, da mais leve para a mais pesada: rodar no **celular pelo cabo USB**, rodar no **Chrome**, ou usar o emulador. Veja o passo 5.

**Por que NÃO vamos instalar o Docker:** ele não é necessário neste projeto e pesaria na memória junto com o emulador. A justificativa completa está em [docs/23, seção 5](../docs/23-analise-tecnica.md). Se o MySQL não instalar de jeito nenhum, use o [apêndice A](apendice-a-docker-opcional.md).

### O que vamos instalar (e para quê)

| # | Programa | Para que serve, em uma frase | Tempo |
|---|---|---|---|
| 1 | **Git** | guarda o histórico do código e envia para o GitHub | 5 min |
| 2 | **VS Code** | o editor onde vamos programar | 5 min |
| 3 | **Flutter SDK** | cria o app; traz junto o **Dart** (a linguagem) | 15 a 30 min |
| 4 | **Android Studio** | só para instalar o SDK do Android e o emulador (não vamos programar nele) | 30 a 60 min |
| 5 | Celular, emulador ou Chrome | onde o app vai rodar | 10 min |
| 6 | **Dart Frog CLI** | sobe o servidor (backend) | 2 min |
| 7 | **MySQL 8.4** + **Workbench** | o banco de dados e a "janela" para enxergá-lo | 20 min |

Façam **nesta ordem**: cada passo usa o anterior.

### Preparação do Windows (5 minutos, uma vez)

1. **Conta no GitHub:** se ainda não tiver, crie em <https://github.com/signup> (use um nome de usuário profissional; o professor vai ver). Mande o usuário para o líder.
2. **Modo de Desenvolvedor do Windows** (o Flutter precisa dele para plugins): aperte `Win+R`, digite `ms-settings:developers`, Enter, e ligue **Modo de Desenvolvedor**.
3. **PowerShell liberado para scripts:** abra o PowerShell e rode (responda `S` se perguntar):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
4. **Extensões de arquivo visíveis:** no Explorador de Arquivos, *Exibir > Mostrar > Extensões de nomes de arquivos*. Assim você enxerga a diferença entre `.env` e `.env.example`.

> **Variável de ambiente / PATH (você vai ver muito essa palavra):** o PATH é a lista de pastas onde o Windows procura um programa quando você digita o nome dele no terminal (`git`, `flutter`...). "Não é reconhecido como comando" quase sempre significa "a pasta do programa não está no PATH" ou "o terminal foi aberto antes de instalar". **Feche e abra o terminal** (ou o VS Code) depois de cada instalação.

---

## 1. Git

1. Baixe em [git-scm.com/download/win](https://git-scm.com/download/win) e instale.
2. Nas telas do instalador, mantenha o padrão, exceto:
   - **Default editor**: *Use Visual Studio Code as Git's default editor*.
   - **Initial branch name**: *Override... = `main`*.
3. Abra um **novo** PowerShell e confira:
   ```powershell
   git --version
   ```
4. Configure seu nome e e-mail (os mesmos da conta do GitHub):
   ```powershell
   git config --global user.name "Seu Nome Completo"
   git config --global user.email "seu-email@exemplo.com"
   ```

> O Git para Windows já traz o **Git Credential Manager**: na primeira vez que você enviar código, uma janela do navegador pedirá login no GitHub. Não é preciso configurar chave SSH.

## 2. VS Code

1. Baixe em [code.visualstudio.com](https://code.visualstudio.com/) e instale. Marque **"Add to PATH"** e **"Open with Code"**.
2. Instale a extensão **Flutter** (Dart-Code). Ela instala a extensão **Dart** junto.
3. As demais extensões são oferecidas automaticamente quando você abrir a pasta do projeto (estão em `.vscode/extensions.json`): Dart Frog, REST Client, Error Lens, Git Graph e Mermaid.

## 3. Flutter SDK (traz o Dart junto)

O jeito recomendado pela documentação oficial é instalar **pelo VS Code**:

1. No VS Code, `Ctrl+Shift+P` e digite **Flutter: New Project**.
2. Aparece o aviso "Could not find a Flutter SDK". Clique em **Download SDK**.
3. Escolha uma pasta **sem espaços e sem acentos**, por exemplo `C:\dev` (o SDK ficará em `C:\dev\flutter`).
4. Quando perguntar **"Add SDK to PATH?"**, clique em **Add SDK to PATH**.
5. Feche e abra o VS Code. Em um terminal novo:
   ```powershell
   flutter --version
   dart --version
   ```
6. **Confira a versão:** o projeto precisa do **Flutter 3.35 ou mais novo** (que traz o **Dart 3.9+**). Se a primeira linha do `flutter --version` mostrar algo mais antigo, rode `flutter upgrade`.

> Não instale em `C:\Program Files` (exige permissão de administrador e quebra atualizações) nem em pastas com espaço ou acento.

**Instalação manual (se a do VS Code falhar):** baixe o zip em [docs.flutter.dev/install/archive](https://docs.flutter.dev/install/archive), extraia em `C:\dev\flutter` e adicione `C:\dev\flutter\bin` ao PATH (Menu Iniciar > "variáveis de ambiente" > Variáveis de usuário > Path > Editar > Novo).

## 4. Android Studio (SDK e emulador)

Usaremos o VS Code para programar, mas o Android Studio é a forma mais simples de instalar o **Android SDK** e o **emulador**.

1. Baixe em [developer.android.com/studio](https://developer.android.com/studio) e instale com as opções padrão.
2. Abra o Android Studio e conclua o assistente inicial (**Standard**). Ele baixa o SDK.
3. Em **More Actions > SDK Manager > SDK Tools**, marque **Android SDK Command-line Tools (latest)** e clique em **Apply**.
4. No PowerShell, aceite as licenças (responda `y` a todas):
   ```powershell
   flutter doctor --android-licenses
   ```
5. Rode o diagnóstico:
   ```powershell
   flutter doctor
   ```
   Precisam aparecer com `[√]`: **Flutter**, **Android toolchain** e **VS Code**. Os itens **Visual Studio** e **Chrome** podem ficar com aviso: não são necessários.

## 5. Onde o app vai rodar (escolha um)

### Opção A — Celular Android pelo cabo USB (mais leve)
1. No celular: **Configurações > Sobre o telefone**, toque 7 vezes em **Número da versão**. Isso ativa as **Opções do desenvolvedor**.
2. Em **Opções do desenvolvedor**, ative **Depuração USB**.
3. Conecte o cabo e aceite "Permitir depuração USB" no celular.
4. `flutter devices` deve listar o aparelho.

### Opção B — Emulador
1. No Android Studio: **More Actions > Virtual Device Manager > Create device**.
2. Escolha **Pixel 7** (ou similar) e uma imagem de sistema recente com **Google APIs**; conclua.
3. Inicie o emulador pelo ▶ do Device Manager. No VS Code, o nome dele aparece no canto inferior direito.
4. **Localização do emulador:** por padrão ele está na Califórnia. Defina Mogi das Cruzes em **⋮ (Extended controls) > Location**, pesquisando o endereço e clicando em **Set location**.

### Opção C — Chrome (sem Android)
`flutter run -d chrome`. Bom para trabalhar no visual das telas. GPS e armazenamento seguro funcionam de forma limitada.

## 6. Dart Frog CLI

```powershell
dart pub global activate dart_frog_cli
```

O comando avisa que a pasta `...\Pub\Cache\bin` não está no PATH. Adicione `%LOCALAPPDATA%\Pub\Cache\bin` às variáveis de usuário (como no passo 3, instalação manual). Em um terminal **novo**:

```powershell
dart_frog --version
```

## 7. MySQL 8.4 LTS e MySQL Workbench

> Por que 8.4? A versão 8.0 saiu de suporte em abril de 2026; a 8.4 é a LTS (suporte longo) atual mais usada.

### Servidor
1. Acesse [dev.mysql.com/downloads/mysql](https://dev.mysql.com/downloads/mysql/).
2. Em **Select Version**, escolha a **8.4.x LTS**; em **Operating System**, **Microsoft Windows**.
3. Baixe o **Windows (x86, 64-bit), MSI Installer**. Na página seguinte, clique em **"No thanks, just start my download"**.
4. Instale com **Typical**. Ao final, deixe marcado **Run MySQL Configurator**.
5. No **MySQL Configurator**:
   - **Type and Networking**: *Development Computer*, porta **3306**.
   - **Accounts and Roles**: defina a **senha do root** e **anote-a**.
   - **Windows Service**: deixe marcado para iniciar com o Windows.
   - Avance até **Execute** e **Finish**.

### Workbench (interface gráfica)
1. Baixe em [dev.mysql.com/downloads/workbench](https://dev.mysql.com/downloads/workbench/) e instale.
2. Abra e clique na conexão **Local instance MySQL84** (ou crie uma: `127.0.0.1`, porta `3306`, usuário `root`).
3. Se aparecer um aviso de versão do servidor não testada, clique em **Continue Anyway**.

### Cliente `mysql` no terminal (opcional)
Adicione `C:\Program Files\MySQL\MySQL Server 8.4\bin` ao PATH e teste `mysql --version`.

## 8. Verificação final

Em um PowerShell **novo**, todos os comandos devem responder com uma versão:

```powershell
git --version
flutter --version
dart --version
dart_frog --version
flutter doctor
```

E o Workbench deve conectar no servidor local.

> **Ainda não clone o projeto.** O repositório do grupo é criado no **Sprint 0** ([etapa 10](10-sprint-0-esqueleto-funcional.md)), passo 1 (líder) e passo 11 (colegas clonam). Antes disso, faça as etapas [04](04-git-e-github-do-zero.md) a [09](09-design-de-telas.md).

### Teste rápido do Flutter (opcional, 10 min)

Para ter certeza de que tudo funciona **antes** do Sprint 0, crie um app de treino fora da pasta do projeto:

```powershell
cd $HOME\Documents
flutter create treino_flutter
cd treino_flutter
code .
```

No VS Code, escolha o dispositivo no canto inferior direito (celular, emulador ou Chrome) e aperte `F5`. Se aparecer o app com o contador e o botão **+**, o seu ambiente está pronto. Esse projeto de treino também é usado na [etapa 06](06-flutter-essencial-e-mvvm.md).

## 9. Problemas comuns

| Sintoma | Causa | Solução |
|---|---|---|
| `flutter` ou `dart_frog` "não é reconhecido" | PATH não atualizado | Confira as variáveis e abra um terminal **novo** (ou reinicie o VS Code) |
| `cmdline-tools component is missing` | Faltou o passo 4.3 | SDK Manager > SDK Tools > Command-line Tools |
| `Android license status unknown` | Licenças não aceitas | `flutter doctor --android-licenses` |
| "Building with plugins requires symlink support" | Modo de Desenvolvedor desligado | `start ms-settings:developers` e ative o Modo de Desenvolvedor |
| Emulador não inicia ou fica lento | Virtualização desligada ou pouca RAM | Ative a virtualização na BIOS ou use o celular (opção A) |
| Porta 3306 em uso no Configurator | Outro MySQL/XAMPP instalado | Pare o outro serviço ou use outra porta (e ajuste o `.env` depois) |
| `flutter --version` mostra versão antiga (menor que 3.35) | SDK instalado há tempo | `flutter upgrade` |
| "a execução de scripts foi desabilitada neste sistema" | Política do PowerShell | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `flutter devices` não mostra o celular | Cabo só de carga, driver ou depuração desligada | Troque o cabo; aceite "Permitir depuração USB"; no celular, mude o modo USB para "Transferência de arquivos" |
| Workbench: "Can't connect to MySQL server" | Serviço parado | `Win+R` → `services.msc` → **MySQL84** → *Iniciar* |
| Esqueci a senha do root | — | Rode o **MySQL Configurator** de novo (*Reconfigure*) e defina outra |

Mais problemas em [docs/22 — Troubleshooting](../docs/22-troubleshooting.md).

---

## Checklist

- [ ] Conta no GitHub criada e usuário enviado ao líder
- [ ] Modo de Desenvolvedor do Windows ligado
- [ ] `git --version` e `git config --global user.name` respondem
- [ ] `flutter --version` mostra 3.35 ou mais novo
- [ ] `flutter doctor` com Flutter, Android toolchain e VS Code em `[√]`
- [ ] `dart_frog --version` responde
- [ ] Workbench conectado ao MySQL 8.4 com o usuário root
- [ ] Um dispositivo disponível (`flutter devices`): celular, emulador ou Chrome
- [ ] (Opcional) O app de treino `treino_flutter` abriu com `F5`

Próximo: [04 — Git e GitHub do zero](04-git-e-github-do-zero.md).
