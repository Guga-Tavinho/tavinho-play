param([string]$Raiz = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
$raizPlayer = (Get-Item -LiteralPath $Raiz -Force).FullName
$prefixoPlayer = $raizPlayer.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$pastaPlayer = Join-Path $raizPlayer 'ginga\player-usb-05\source'
$modeloPlayer = Join-Path $pastaPlayer 'modelo_v05.ncl'
if (-not (Test-Path -LiteralPath $modeloPlayer -PathType Leaf)) {
    throw 'Copie o atualizador e a pasta ginga para a raiz do pendrive, ou indique -Raiz.'
}
$arquivosPlayer = [Collections.Generic.List[IO.FileInfo]]::new()
function Buscar-PlayerMp4([string]$Diretorio, [int]$Profundidade) {
    if ($Profundidade -gt 12) { return }
    try { $entradasPlayer = @(Get-ChildItem -LiteralPath $Diretorio -Force -ErrorAction Stop) }
    catch {
        if ($Profundidade -eq 0) { throw }
        Write-Warning ('Pasta inacessivel ignorada: {0}' -f $Diretorio)
        return
    }
    foreach ($itemPlayer in $entradasPlayer) {
        if ($itemPlayer.Name.StartsWith('.')) { continue }
        if ($itemPlayer.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        if ($itemPlayer.PSIsContainer) {
            if ($Profundidade -eq 0 -and $itemPlayer.Name -ieq 'ginga') { continue }
            Buscar-PlayerMp4 $itemPlayer.FullName ($Profundidade + 1)
        } elseif ($itemPlayer.Extension -ieq '.mp4') {
            if (-not $itemPlayer.FullName.StartsWith($prefixoPlayer, [StringComparison]::OrdinalIgnoreCase)) {
                throw ('Arquivo fora da raiz informada: {0} (raiz: {1})' -f $itemPlayer.FullName,$prefixoPlayer)
            }
            $arquivosPlayer.Add($itemPlayer)
            if ($arquivosPlayer.Count -gt 300) { throw 'O catalogo permite ate 300 videos.' }
        }
    }
}
Buscar-PlayerMp4 $raizPlayer 0
$ordenadosPlayer = @($arquivosPlayer | Sort-Object { $_.FullName.ToLowerInvariant() })
$areasPlayer = [Collections.Generic.List[string]]::new()
$midiasPlayer = [Collections.Generic.List[string]]::new()
$elosPlayer = [Collections.Generic.List[string]]::new()
$mapaPlayer = [Collections.Generic.List[string]]::new()
$mapaPlayer.Add('return {')
$numeroPlayer = 0
foreach ($arquivoPlayer in $ordenadosPlayer) {
    $numeroPlayer++
    $idPlayer = 'v{0:D4}' -f $numeroPlayer
    $relativoPlayer = $arquivoPlayer.FullName.Substring($prefixoPlayer.Length).Replace('\', '/')
    $hexPlayer = -join ([Text.Encoding]::UTF8.GetBytes($relativoPlayer) | ForEach-Object { $_.ToString('x2') })
    $mapaPlayer.Add(('["{0}"]="{1}",' -f $hexPlayer, $idPlayer))
    $fontePlayer = [Security.SecurityElement]::Escape('../../../' + $relativoPlayer).Replace(',', '&#44;')
    $midiasPlayer.Add(('<media id="{0}" src="{1}" type="video/mp4" descriptor="dVideo"/>' -f $idPlayer, $fontePlayer))
    foreach ($parPlayer in @(@('abrir','start'),@('parar','stop'),@('pausar','pause'),@('continuar','resume'))) {
        $rotuloPlayer = $parPlayer[0] + '_' + $idPlayer
        $areasPlayer.Add(('<area id="{0}" label="{0}"/>' -f $rotuloPlayer))
        $elosPlayer.Add(('<link id="l_{0}" xconnector="c_{1}"><bind role="onBegin" component="controller" interface="{0}"/><bind role="{1}" component="{2}"/></link>' -f $rotuloPlayer,$parPlayer[1],$idPlayer))
    }
    foreach ($parPlayer in @(@('tocando','onBegin','c_inicio'),@('fim','onEnd','c_fim'))) {
        $elosPlayer.Add(('<link id="l_{0}_{1}" xconnector="{2}"><linkParam name="valor" value="{0}:{1}"/><bind role="{3}" component="{1}"/><bind role="set" component="controller" interface="estado"/></link>' -f $parPlayer[0],$idPlayer,$parPlayer[2],$parPlayer[1]))
    }
}
$mapaPlayer.Add('}')
$nclPlayer = [IO.File]::ReadAllText($modeloPlayer, [Text.Encoding]::UTF8)
foreach ($marcaPlayer in @('<!--USB_AREAS-->','<!--USB_MEDIA-->','<!--USB_LINKS-->')) {
    if ([regex]::Matches($nclPlayer,[regex]::Escape($marcaPlayer)).Count -ne 1) { throw 'Modelo de catalogo invalido.' }
}
$nclPlayer = $nclPlayer.Replace('<!--USB_AREAS-->',($areasPlayer -join "`n")).Replace('<!--USB_MEDIA-->',($midiasPlayer -join "`n")).Replace('<!--USB_LINKS-->',($elosPlayer -join "`n"))
$xmlPlayer = [xml]$nclPlayer
$mapaTextoPlayer = ($mapaPlayer -join "`n") + "`n"
$utf8Player = [Text.UTF8Encoding]::new($false)
$mainPlayer = Join-Path $pastaPlayer 'main_v05.ncl'
$luaPlayer = Join-Path $pastaPlayer 'catalogo_v05.lua'
$mainAnteriorPlayer = [IO.File]::ReadAllText($mainPlayer,[Text.Encoding]::UTF8)
$luaAnteriorPlayer = [IO.File]::ReadAllText($luaPlayer,[Text.Encoding]::UTF8)
[IO.File]::WriteAllText((Join-Path $pastaPlayer 'catalogo_preparado.ncl'),$nclPlayer,$utf8Player)
[IO.File]::WriteAllText((Join-Path $pastaPlayer 'catalogo_preparado.lua'),$mapaTextoPlayer,$utf8Player)
[IO.File]::WriteAllText((Join-Path $pastaPlayer 'main_v05_antes_atualizacao.ncl'),$mainAnteriorPlayer,$utf8Player)
[IO.File]::WriteAllText((Join-Path $pastaPlayer 'catalogo_v05_antes_atualizacao.lua'),$luaAnteriorPlayer,$utf8Player)
try {
    [IO.File]::WriteAllText($mainPlayer,$nclPlayer,$utf8Player)
    [IO.File]::WriteAllText($luaPlayer,$mapaTextoPlayer,$utf8Player)
} catch {
    $erroPlayer = $_
    try { [IO.File]::WriteAllText($mainPlayer,$mainAnteriorPlayer,$utf8Player) } catch {}
    try { [IO.File]::WriteAllText($luaPlayer,$luaAnteriorPlayer,$utf8Player) } catch {}
    throw $erroPlayer
}
Write-Host ('Catalogo atualizado: {0} video(s).' -f $numeroPlayer)
Write-Host 'Ejete o pendrive, conecte ao receptor e abra Tavinho Play.'
