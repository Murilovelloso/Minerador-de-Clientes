#!/bin/bash
# Prospector de Sites — publica a fila no VPS via SSH/SCP (chave) (Mac).
# Manual: duplo clique. Automatico (launchd): chamado com --auto (log em publicador-log.txt, sem pause).
cd "$(dirname "$0")"
AUTO=0; [ "$1" = "--auto" ] && AUTO=1
log(){ if [ $AUTO -eq 1 ]; then echo "[$(date '+%d/%m %H:%M:%S')] $1" >> publicador-log.txt; else echo "$1"; fi; }
fim(){ [ $AUTO -eq 0 ] && read -p "Pressione Enter para fechar..."; exit $1; }
[ -f fila-publicacao.txt ] || { [ $AUTO -eq 0 ] && log "Nada na fila — peca /publicar ao Claude primeiro."; fim 0; }
CFG=prospector-config.json
[ -f $CFG ] || { log "ERRO: prospector-config.json nao encontrado."; fim 1; }
U=$(python3 -c "import json;print(json.load(open('$CFG'))['vps'].get('usuario',''))")
HOST=$(python3 -c "import json;print(json.load(open('$CFG'))['vps'].get('host',''))")
PORTA=$(python3 -c "import json;print(json.load(open('$CFG'))['vps'].get('porta',22))")
CHAVE=$(python3 -c "import json;print(json.load(open('$CFG'))['vps'].get('chaveSSH',''))")
[ -n "$U" ] && [ -n "$HOST" ] && [ -n "$CHAVE" ] || { log "ERRO: preencha a conexao VPS no dashboard (Configuracoes): usuario, host e caminho da chave SSH."; fim 1; }
[ -f "$CHAVE" ] || { log "ERRO: chave SSH nao encontrada em $CHAVE"; fim 1; }
SSHOPTS=(-i "$CHAVE" -p "$PORTA" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15)
OK=0; FALHA=0
while IFS='|' read -r LOCAL REMOTO; do
  LOCAL=$(echo "$LOCAL" | xargs); REMOTO=$(echo "$REMOTO" | xargs)
  [ -z "$LOCAL" ] && continue
  if [ ! -f "$LOCAL" ]; then log "PULOU (nao existe): $LOCAL"; FALHA=$((FALHA+1)); continue; fi
  REMOTO_DIR=$(dirname "$REMOTO")
  log "Criando pasta remota $REMOTO_DIR ..."
  if ! ssh "${SSHOPTS[@]}" "$U@$HOST" "mkdir -p '$REMOTO_DIR'"; then
    log "  FALHOU ao criar pasta remota"; FALHA=$((FALHA+1)); continue
  fi
  log "Subindo $LOCAL -> $REMOTO ..."
  if scp -i "$CHAVE" -P "$PORTA" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 "$LOCAL" "$U@$HOST:$REMOTO"; then
    log "  OK"; OK=$((OK+1))
  else
    log "  FALHOU"; FALHA=$((FALHA+1))
  fi
done < fila-publicacao.txt
log "Concluido: $OK enviados, $FALHA falhas."
if [ $FALHA -eq 0 ] && [ $OK -gt 0 ]; then
  mv fila-publicacao.txt "fila-publicada-$(date '+%Y%m%d-%H%M').txt"
  log "Fila concluida. Avise o Claude ('publiquei') para verificar as URLs."
fi
fim 0
