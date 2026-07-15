---
name: deploy-vps
description: Esta skill deve ser usada ao publicar páginas num VPS próprio (Linux com acesso SSH) — upload via SCP/SSH com chave, criação de pastas por cliente, verificação da URL pública e HTTPS via Let's Encrypt. Acione quando o usuário disser "publicar", "subir o site", "colocar no ar", "deploy", "vps", "servidor" ou rodar /publicar ou o teste de conexão do /setup.
---

# Deploy num VPS próprio

Publicar páginas em `[caminhoBase]/[slug]/` no VPS via SSH e garantir a URL pública `https://[dominio]/[caminhoBase-relativo]/[slug]/` funcionando.

## Credenciais

Tudo vem de `prospector-config.json` (bloco `vps`): `usuario` (usuário SSH, ex. `deploy` — evite usar `root`), `host` (IP ou hostname do servidor), `porta` (padrão 22), `chaveSSH` (caminho do arquivo de chave privada no computador do usuário, ex. `C:\Users\Nome\.ssh\id_prospector` ou `~/.ssh/id_prospector`), `caminhoBase` (pasta no servidor onde os sites dos clientes ficam, ex. `/var/www/clientes`), `dominio` (domínio já apontado pro VPS e servido pelo nginx/Apache a partir de `caminhoBase`).

**Autenticação é por CHAVE SSH, nunca por senha.** É mais seguro e é o único método que os scripts do publicador automático conseguem rodar sem depender de ferramentas extras no Windows. O arquivo de chave privada nunca é lido, exibido ou registrado em nenhuma saída — só o CAMINHO dele vai no config. Se o usuário só tiver senha (sem chave configurada), oriente a gerar o par de chaves (seção "Gerar chave SSH" abaixo) antes de continuar.

## Gerar chave SSH (uma vez, no /setup se ainda não existir)

1. No terminal do usuário (PowerShell no Windows, Terminal no Mac — ambos têm OpenSSH nativo):
   ```
   ssh-keygen -t ed25519 -f "CAMINHO_ESCOLHIDO/id_prospector" -N ""
   ```
   Isso gera `id_prospector` (chave privada) e `id_prospector.pub` (chave pública) na pasta escolhida (sugestão: dentro da própria pasta conectada do plugin, numa subpasta oculta, ou em `~/.ssh/`).
2. Copiar a chave pública pro VPS — o jeito mais simples, se o usuário já tiver acesso por senha uma única vez:
   ```
   ssh-copy-id -i "CAMINHO/id_prospector.pub" -p [porta] [usuario]@[host]
   ```
   (No Windows sem `ssh-copy-id`: oriente colar o conteúdo do `.pub` no final de `~/.ssh/authorized_keys` do usuário no VPS, manualmente ou via um comando único de `cat id_prospector.pub | ssh usuario@host "cat >> ~/.ssh/authorized_keys"`.)
3. Testar: `ssh -i "CAMINHO/id_prospector" -p [porta] [usuario]@[host] "echo conectou"`. Se conectar sem pedir senha, está pronto — salve o caminho da chave privada em `chaveSSH` no config.

## Método 1 — Publicador automático local (RECOMENDADO: instala uma vez, nunca mais clica)

A rede do sandbox do Cowork provavelmente NÃO alcança SSH de qualquer VPS (mesma limitação que existia com FTP). A publicação roda na máquina do usuário via um publicador instalado no agendador do Windows/launchd do Mac: a cada minuto ele verifica a fila e sobe o que houver via `scp`/`ssh`, usando a chave do config. O usuário instala UMA vez e o `/publicar` vira 100% automático.

1. **Garanta os arquivos do publicador na pasta conectada** (copie de `references/` desta skill, sobrescrevendo versões antigas), conforme o sistema do usuário:
   - **Windows**: `publicar-agora.ps1`, `publicar-agora.bat`, `publicador-oculto.vbs`, `instalar-publicador.bat`. Requer o cliente OpenSSH do Windows ativo (vem instalado por padrão no Windows 10/11 — se `ssh`/`scp` não forem reconhecidos no PowerShell, oriente ativar em Configurações → Aplicativos opcionais → Adicionar recurso → "Cliente OpenSSH").
   - **Mac**: `publicar-agora.command` e `instalar-publicador.command` (`ssh`/`scp` já vêm no macOS).
2. **Primeira vez**: peça UM duplo clique no `instalar-publicador.bat` (Windows — cria a tarefa "ProspectorPublicador") ou no `instalar-publicador.command` (Mac — registra no launchd). Só uma vez na vida.
3. **Monte a fila**: escreva `fila-publicacao.txt` na raiz da pasta conectada, uma linha por arquivo: `caminho/local/arquivo.html|[caminhoBase]/[slug]/index.html`. Inclua página (`index.html`) e capa (`proposta.html`) de cada cliente. Em até 1 minuto o publicador cria a pasta remota (se não existir) e sobe tudo sozinho, renomeando a fila para `fila-publicada-[data].txt` (log em `publicador-log.txt`).
4. **Aguarde ~90s e verifique**: confira se a fila foi renomeada e teste as URLs (verificação abaixo). Sem tarefa instalada, o fallback manual é o duplo clique no `publicar-agora.bat` (Windows) ou `publicar-agora.command` (Mac).

## Método 2 — SSH direto do sandbox (tentar primeiro, silencioso)

Antes de acionar o usuário, tente publicar você mesmo via bash: primeiro `ssh -i [chaveSSH] -p [porta] -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 [usuario]@[host] "mkdir -p $(dirname [caminhoRemoto])"`, depois `scp -i [chaveSSH] -P [porta] -o StrictHostKeyChecking=accept-new [arquivo] [usuario]@[host]:[caminhoRemoto]`. Se funcionar, ótimo: zero ação do usuário. Se a rede do sandbox bloquear (timeout/refused) ou a chave não estiver acessível pelo sandbox (o normal, já que ela vive no computador do usuário), caia SEM DRAMA para o Método 1 — não insista em tentativas repetidas.

## Método 3 — Cliente SFTP manual (último recurso)

Se os métodos 1 e 2 falharem (ex.: usuário sem OpenSSH habilitado e sem paciência pra instalar): oriente o usuário a usar um cliente SFTP gráfico (FileZilla, Cyberduck) com host/porta/usuário/chave do config, e fazer o upload manual da pasta `sites/[slug]/` para `[caminhoBase]/[slug]/` no VPS.

## HTTPS obrigatório (Let's Encrypt — configuração única no VPS, não por cliente)

Como todos os clientes moram em subpastas do MESMO domínio (`[dominio]/[caminhoBase-relativo]/[slug]/`), o certificado HTTPS é UM só para o domínio inteiro — configurado uma vez no servidor, nunca por cliente novo. Se ainda não tiver HTTPS válido no domínio:

1. No VPS, com nginx ou Apache já servindo `caminhoBase` como raiz do domínio, instalar o certbot (`apt install certbot python3-certbot-nginx` ou `python3-certbot-apache`, conforme o servidor web).
2. Rodar `certbot --nginx -d [dominio]` (ou `--apache`) — ele emite o certificado e configura o redirecionamento HTTPS automaticamente. O certbot já deixa a renovação automática agendada (systemd timer ou cron).
3. Isso é tarefa do usuário no terminal do VPS (via SSH) — oriente passo a passo na primeira publicação; depois disso, todo cliente novo já sai em HTTPS sem nenhuma ação extra.

Enquanto o HTTPS do domínio não estiver validado, a publicação NÃO está concluída — link `http://` NUNCA vai para cliente.

## Verificação (obrigatória, após qualquer método)

1. Abra `https://[dominio]/[caminhoBase-relativo]/[slug]/` e a capa `.../proposta.html` — confirme que carregam com conteúdo certo.
2. Confirme cadeado válido (ver seção HTTPS acima se falhar).
3. Atualize `leads.md` + o banco do dashboard com status `publicado` e a URL.

## Teste de conexão do /setup

Publique `teste.html` simples ("Funcionou!") em `[caminhoBase]/teste/index.html` pelo Método 2; se bloqueado, já deixe os scripts do Método 1 copiados na pasta, monte a fila com o teste e peça os 2 cliques — assim o usuário aprende o fluxo logo no setup.
