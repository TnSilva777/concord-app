# CONCORD Desktop (Windows)

O CONCORD Desktop utiliza Electron para abrir o site oficial em uma janela própria, mantendo autenticação e dados no Supabase.

## Rodar no computador
1. Instale Node.js 22 ou posterior.
2. Execute `npm install` na raiz do repositório.
3. Execute `npm start` para testar.
4. Execute `npm run desktop:build` para gerar `dist/CONCORD-Setup-0.1.0.exe` no Windows.

## Compilar sem instalar Node.js no seu computador
No GitHub, abra **Actions → CONCORD Desktop Windows → Run workflow** na branch `main`.
Ao terminar a execução, baixe o artefato `CONCORD-Windows-Setup` na página da execução.
O instalador de teste é **não assinado** e o Windows SmartScreen pode apresentar aviso.

## Atualizações
- Alterações **do site**: quando o código do site for publicado na Vercel, aparecerá no Desktop após recarregar ou reabrir.
- Alterações **do Electron/instalador**: devem ser publicadas como GitHub Releases, incluindo o manifesto `latest.yml`.
- Para publicar um instalador com canal de atualização, ajuste a propriedade `version` em `package.json` e crie uma tag `desktop-vX.Y.Z` com a **mesma versão**. O workflow de tag executa a publicação para GitHub Releases.
- O atualizador verifica novas versões na inicialização e instala a versão baixada ao fechar o aplicativo. O repositório de releases precisa estar público para downloads sem token.
- Não renomeie ou transfira o repositório de distribuição sem migrar também o endereço de atualização incluído nos executáveis já distribuídos.

## Limitações atuais
- Este projeto é um **invólucro do site**, não um servidor de chamadas independente.
- É necessário acesso à internet e à hospedagem Vercel/Supabase.
- As falhas existentes de WebRTC (STUN sem TURN) permanecem; captura de áudio de sistema e seleção de tela podem precisar de adaptação específica ao Electron.
- A versão inicial não é assinada digitalmente e não foi validada em todas as versões do Windows.
- Não inclui ícone personalizado de marca nesta primeira versão. Isso pode ser acrescentado posteriormente.
