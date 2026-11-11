# 19 — Deploy (opcional)

Para a avaliação, **não é preciso publicar nada na internet**: a entrega é o repositório no GitHub, e a demonstração roda no notebook do grupo ([trilha/22](../trilha/22-documentacao-e-entrega.md)). Este documento existe para quem quiser ir além depois que o MVP estiver pronto.

## Opções para a apresentação (sem servidor)

| Opção | Como | Quando usar |
|---|---|---|
| **Modo Fake** | APK com `--dart-define=USAR_FAKE=true` | plano B sem rede; tudo no celular |
| **Notebook na mesma Wi-Fi** | backend com `ESCUTAR_NA_REDE=true`; app com `API_URL=http://<IP do notebook>:8080` (build **debug**, que aceita HTTP) | demonstração real com dois celulares |
| **Emuladores no notebook** | dois emuladores + backend local | sem depender da rede da faculdade |

## Versão web de demonstração (abre em qualquer celular)

O modo Fake não precisa de servidor nem de banco, então o app pode virar um **site estático** e ser aberto pelo navegador de qualquer celular (Android ou iPhone), sem instalar nada.

1. Criar a pasta `web/` do app (só na primeira vez):

   ```powershell
   cd desenvolvimento_app\app
   flutter create --platforms=web .
   ```

2. Testar no computador:

   ```powershell
   flutter run -d chrome --dart-define=USAR_FAKE=true
   ```

3. Gerar o site (o resultado fica em `build\web`):

   ```powershell
   flutter build web --release --dart-define=USAR_FAKE=true
   ```

4. Publicar a pasta `build\web` em qualquer hospedagem de site estático com HTTPS (Netlify, Firebase Hosting, GitHub Pages). No GitHub Pages o site fica em `/<nome-do-repositorio>/`: gere com `--base-href /<nome-do-repositorio>/`.

Limites desta versão: os dados ficam na memória do navegador (recarregar a página volta ao começo), não há notificações na barra do sistema e a câmera vira o seletor de arquivos do navegador. Os usuários de teste são os mesmos do modo Fake (senha `senha123`).

## Publicar a API (se quiserem)

O que seria necessário:

1. **Um MySQL na nuvem** (serviço gerenciado ou servidor próprio), com o `schema.sql` e o usuário de privilégio mínimo. O seed **não** vai para produção.
2. **Um host para o backend** que rode containers (por exemplo, um PaaS com plano gratuito ou uma VPS).
3. **HTTPS** (os PaaS normalmente já fornecem). O app de release **exige** HTTPS.
4. **Variáveis de ambiente** configuradas no painel do host (nunca no Git): `DB_*`, `JWT_SEGREDO` novo, `CORS_ORIGEM`, `ESCUTAR_NA_REDE=true`.

### Gerar a imagem do backend

```powershell
cd desenvolvimento_app\backend
dart_frog build
```

O comando cria a pasta `build/` com o servidor compilável e um `Dockerfile`. O Dart Frog copia para dentro de `build/` as dependências por caminho (o nosso `shared_models`); confira se a pasta copiada existe antes de construir a imagem. O `build/` está no `.gitignore`.

### App apontando para a API publicada

```powershell
cd desenvolvimento_app\app
flutter build apk --release --dart-define=API_URL=https://<seu-endereco>
```

## Checklist (se publicarem)

- [ ] `JWT_SEGREDO` de produção diferente do de desenvolvimento
- [ ] Usuário do banco sem privilégios de administrador
- [ ] `schema.sql` aplicado; seed **não**
- [ ] HTTPS funcionando
- [ ] `CORS_ORIGEM` restrito (se houver cliente web)
- [ ] APK de release testado num celular real
