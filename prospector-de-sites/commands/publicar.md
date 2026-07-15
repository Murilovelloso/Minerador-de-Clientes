---
description: Publica as páginas redesenhadas no VPS e retorna as URLs públicas
argument-hint: "[nome do cliente ou todos]"
---

Publique páginas no VPS seguindo a skill `deploy-vps`.

## Passos

1. Leia `prospector-config.json`. Se os dados do `vps` não estiverem preenchidos (usuario, host, chaveSSH, caminhoBase, dominio), colete-os agora — e se ainda não houver chave SSH configurada, siga a seção "Gerar chave SSH" da skill `deploy-vps` antes de continuar. Nunca peça ou exiba o conteúdo da chave privada, só o caminho do arquivo.
2. Determine o que publicar: `$ARGUMENTS` (um cliente ou "todos"), ou liste as páginas com status `redesenhado` em `leads.md` e pergunte.
3. **Gere a página-capa de cada cliente**: preencha `references/capa-proposta-template.html` (skill `proposta-email`) com os dados do lead + assinatura do config e salve como `sites/[slug]/proposta.html`. É ela que vai no e-mail de proposta.
4. **Publique seguindo a skill `deploy-vps`**, nesta ordem: tente o SSH/SCP silencioso do sandbox; se a rede ou a chave (que vive no computador do usuário) bloquear, use o publicador automático local — garanta os arquivos do publicador na pasta, monte a `fila-publicacao.txt` com página (`index.html`) e capa (`proposta.html`) de cada cliente e aguarde ~90s: a tarefa agendada publica sozinha via SSH (confira a fila renomeada e o `publicador-log.txt`). Se a tarefa ainda não foi instalada, peça o duplo clique único no `instalar-publicador.bat`/`.command`. Sem senha em lugar nenhum, autenticação só por chave.
5. **Verificação HTTPS (bloqueante)**: abra cada URL com `https://` e confirme que carrega com cadeado válido. Se o HTTPS falhar, siga a seção "HTTPS obrigatório" da skill `deploy-vps` (certbot/Let's Encrypt no VPS — configuração única do domínio, não por cliente) antes de considerar publicado — link `http://` NUNCA vai para cliente.
6. Atualize `leads.md` e o banco do dashboard: status `publicado` + URL pública nova.

## Saída

Liste, por cliente: URL da página nova e URL da capa (`.../proposta.html`), ambas testadas em https. Sugira o próximo passo: `/proposta` para enviar os e-mails.
