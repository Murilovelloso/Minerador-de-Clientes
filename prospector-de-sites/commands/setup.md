---
description: Configura o plugin — assinatura, preferências e conexão com o VPS (roda uma vez)
---

Configure o ambiente do Prospector de Sites. Siga esta ordem:

## 1. Pasta de trabalho

Verifique se há uma pasta do usuário conectada. Se não houver, peça para conectar uma pasta (ex.: "Clientes") usando a ferramenta de solicitação de pasta — tudo (config, leads e sites criados) será salvo nela para persistir entre sessões.

## 2. Verificar config existente

Procure `prospector-config.json` na pasta conectada. Se existir, mostre um resumo (sem exibir a senha) e pergunte o que o usuário quer atualizar. Se não existir, colete os dados abaixo.

## 3. Dados do usuário (perguntar via AskUserQuestion / formulário)

Colete:

- **Mercado(s) alvo**: Brasil, Portugal, ou ambos. Isso define, por mercado, a moeda (R$/€), o formato de telefone/WhatsApp (BR: `55+DDD+número`; PT: `351+número`, sem DDD) e o documento do cliente no contrato (BR: CPF/CNPJ; PT: NIF). Se o usuário escolher "ambos", pergunte qual é o mercado padrão para quando ele não especificar em `/prospectar`.
- **Assinatura da proposta**: nome completo, como quer se apresentar (ex.: "Designer de páginas de alta conversão") e WhatsApp/telefone de contato (no formato do mercado dele).
- **Nichos padrão de prospecção**: sugira nutricionistas, psicólogos, advogados e psiquiatras como ponto de partida, mas deixe o usuário editar livremente. Se houver mais de um mercado, pergunte se os nichos e a cidade padrão valem para os dois ou se cada mercado tem os seus.
- **Cidade/região padrão** — uma por mercado configurado.
- **Preço de referência da página** (usado só como estimativa de potencial no dashboard) — padrão R$ 700 para BR, € 200 para PT (o usuário pode ajustar).
- **Leads qualificados por busca**: padrão 10.
- **Modo de envio da proposta**: padrão "criar rascunho no Gmail para revisão" (recomendado). Alternativa: enviar direto.

## 4. Conexão com o VPS

Pergunte se o usuário já tem um VPS (servidor Linux próprio, com acesso SSH e um domínio apontado pra ele, servindo um servidor web como nginx ou Apache).

- **Se ainda não tem**: explique brevemente que ele precisa de um VPS Linux qualquer (DigitalOcean, Hetzner, Contabo, etc.), com nginx ou Apache instalado servindo uma pasta (ex.: `/var/www/clientes`) como raiz do domínio, e acesso SSH liberado. Depois de ter isso, deve voltar e rodar `/setup` de novo. Salve o config parcial e encerre.
- **Se já tem**: primeiro confira se existe chave SSH configurada (`chaveSSH` no config apontando pra um arquivo que existe). Se NÃO existir, siga a seção "Gerar chave SSH" da skill `deploy-vps` — ela é rodada pelo próprio usuário no terminal dele (você guia passo a passo, mas quem digita é ele, já que envolve `ssh-keygen`/`ssh-copy-id` no ambiente dele). NÃO colete nenhum outro dado do VPS pelo chat (usuário, host, caminho). Tudo vai num lugar só, a aba Configurações do dashboard:
  1. Instrua: abra o dashboard (`iniciar-dashboard.bat` na pasta conectada) → aba **Configurações** → seção **Conexão VPS**.
  2. Lá ele preenche: usuário SSH, host/IP, porta (padrão 22), caminho da chave privada gerada no passo anterior, caminho da pasta no servidor (ex.: `/var/www/clientes`), pasta na URL pública (se o VPS servir os clientes direto na raiz do domínio, deixa em branco) e o domínio principal. Clica em "Salvar conexão" → tudo vai do navegador direto pro `prospector-config.json` no computador dele, sem passar pelo chat.
  3. Peça para ele avisar quando salvar ("salvei") — aí você LÊ o config (confirmando que os campos estão preenchidos e que o arquivo da chave existe no caminho informado) e roda o teste de conexão.

  Nunca peça, exiba ou registre o CONTEÚDO da chave privada em nenhuma saída — só o caminho do arquivo importa pro plugin. Se ele preferir, editar o `prospector-config.json` na mão também vale.

## 5. Salvar e testar

Salve tudo em `prospector-config.json` na pasta conectada, neste formato:

```json
{
  "assinatura": { "nome": "", "apresentacao": "", "whatsapp": "" },
  "mercados": {
    "padrao": "BR",
    "BR": { "codigoPais": "55", "moeda": "R$", "localeNum": "pt-BR", "documento": "CPF/CNPJ", "cidade": "", "precoPagina": 700 },
    "PT": { "codigoPais": "351", "moeda": "€", "localeNum": "pt-PT", "documento": "NIF", "cidade": "", "precoPagina": 200 }
  },
  "prospeccao": { "nichos": ["nutricionistas", "psicologos", "advogados", "psiquiatras"], "leadsPorBusca": 10 },
  "envio": { "modo": "rascunho" },
  "vps": { "usuario": "", "host": "", "porta": 22, "chaveSSH": "", "caminhoBase": "/var/www/clientes", "pastaUrl": "clientes", "dominio": "" }
}
```

Inclua no config apenas os mercados que o usuário efetivamente escolheu (se for só Brasil, mantenha só o bloco `BR`). O `deploy-vps` NÃO muda por mercado — o mesmo VPS publica sites de qualquer país, o que muda é só moeda/telefone/documento.

Se os dados do `vps` foram informados (usuário, host, chave SSH), teste a conexão seguindo a skill `deploy-vps`: publique uma página `teste.html` simples e informe a URL pública ao usuário. Se o teste falhar, diagnostique (chave SSH, permissões da pasta remota, servidor web servindo `caminhoBase`) antes de concluir.

## 6. Dashboard inicial

Siga a seção "Setup" da skill `dashboard-leads`: copie `dashboard-server.py` e `iniciar-dashboard.bat` para a raiz da pasta conectada, crie o banco `prospector.db` (schema da skill) e gere o `dashboard.html` do template. Explique ao usuário: duplo clique em `iniciar-dashboard.bat` abre o painel completo em http://localhost:8765 com edição/exclusão salvando no banco (requer Python no Windows; sem ele, o dashboard.html abre no modo leitura).

## 7B. Entregar o manual e os scripts

Copie da pasta do plugin para a pasta conectada (sobrescrevendo versões antigas): `manual.html` (manual do usuário) e os arquivos do publicador conforme o sistema do usuário (skill `deploy-vps`, references) — Windows: `publicar-agora.ps1/.bat`, `publicador-oculto.vbs`, `instalar-publicador.bat` · Mac: `publicar-agora.command`, `instalar-publicador.command` — mais o iniciador do dashboard certo (`iniciar-dashboard.bat` ou `.command`). Peça UM duplo clique no instalador do publicador (registra o publicador automático — única vez na vida; o teste de conexão do item 5 pode usar esse fluxo). Apresente o `manual.html` ao usuário com a frase: "Esse é o seu manual — guarda ele que responde 90% das dúvidas."

## 7. Encerrar

Confirme o que foi salvo e explique o ciclo (guiando SEMPRE o próximo passo ao fim de cada comando): `/prospectar` → `/redesenhar` → `/publicar` → `/proposta`, com `/editor` opcional para ajustes manuais e o `dashboard.html` como painel de controle de tudo.
