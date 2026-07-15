# Prospector de Sites - publicacao automatica no VPS via SSH/SCP (chave)
# Manual: duplo clique no publicar-agora.bat (mostra janela)
# Automatico: instalado pelo instalar-publicador.bat, roda a cada minuto escondido (-Auto)
param([switch]$Auto)
$ErrorActionPreference = "Stop"
$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $pasta
function Fim($code){ if(-not $Auto){ pause }; exit $code }
function Log($msg,$cor="Gray"){
  if($Auto){ Add-Content "publicador-log.txt" ("[" + (Get-Date -Format "dd/MM HH:mm:ss") + "] " + $msg) }
  else { Write-Host $msg -ForegroundColor $cor }
}
if (-not (Test-Path "fila-publicacao.txt")) { if(-not $Auto){ Log "Nada na fila - peca /publicar ao Claude primeiro." "Yellow" }; Fim 0 }
try { $cfg = Get-Content "prospector-config.json" -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Log "ERRO: prospector-config.json nao encontrado/invalido." "Red"; Fim 1 }
$u = $cfg.vps.usuario; $host_ = $cfg.vps.host; $porta = $cfg.vps.porta; if (-not $porta) { $porta = 22 }
$chave = $cfg.vps.chaveSSH
if (-not $u -or -not $host_ -or -not $chave) { Log "ERRO: preencha a conexao VPS (dashboard > Configuracoes): usuario, host e caminho da chave SSH." "Red"; Fim 1 }
if (-not (Test-Path $chave)) { Log ("ERRO: chave SSH nao encontrada em " + $chave) "Red"; Fim 1 }
$fila = Get-Content "fila-publicacao.txt" -Encoding UTF8 | Where-Object { $_ -match "\|" }
$ok = 0; $falha = 0
$sshOpts = @("-i", $chave, "-p", "$porta", "-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=15")
foreach ($linha in $fila) {
  $par = $linha -split "\|", 2
  $local = $par[0].Trim(); $remoto = $par[1].Trim()
  if (-not (Test-Path $local)) { Log ("PULOU (nao existe): " + $local) "Yellow"; $falha++; continue }
  $remotoDir = ($remoto -replace '\\','/') -replace '/[^/]*$',''
  Log ("Criando pasta remota " + $remotoDir + " ...")
  & ssh.exe @sshOpts "$u@$host_" "mkdir -p `"$remotoDir`""
  if ($LASTEXITCODE -ne 0) { Log "  FALHOU ao criar pasta remota" "Red"; $falha++; continue }
  Log ("Subindo " + $local + " -> " + $remoto + " ...")
  & scp.exe -i $chave -P $porta -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 "$local" "${u}@${host_}:$remoto"
  if ($LASTEXITCODE -eq 0) { Log "  OK" "Green"; $ok++ } else { Log ("  FALHOU (codigo " + $LASTEXITCODE + ")") "Red"; $falha++ }
}
Log ("Concluido: " + $ok + " enviados, " + $falha + " falhas.") "Cyan"
if ($falha -eq 0 -and $ok -gt 0) {
  Rename-Item "fila-publicacao.txt" ("fila-publicada-" + (Get-Date -Format "yyyyMMdd-HHmm") + ".txt") -Force
  Log "Fila concluida. Avise o Claude ('publiquei') para verificar as URLs." "Cyan"
}
Fim 0
