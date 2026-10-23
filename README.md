# Tavinho Play

**Player de vídeos MP4 pelo pendrive para o receptor Multilaser RE510, usando o Ginga que já existe no aparelho.**

Versão **0.6.16** · firmware de referência **V1.11.0** · interface e instruções em português.

O Tavinho Play permite escolher vídeos em uma lista, navegar pelas pastas do pendrive, pausar, avançar, voltar e reproduzir o próximo arquivo automaticamente. Inclui três tamanhos de interface, inclusive um modo com letras ampliadas para TVs CRT pequenas.

O aplicativo é executado pelo USB. A instalação não grava uma nova firmware na memória do receptor. O controle de tempo e de busca usa um módulo nativo específico da plataforma analisada; por isso, a compatibilidade não é universal com todo aparelho que tenha Ginga.

## Índice

- [Recursos](#recursos)
- [Compatibilidade e requisitos](#compatibilidade-e-requisitos)
- [Quais arquivos ele reproduz?](#quais-arquivos-ele-reproduz)
- [Converter e inspecionar vídeos](#converter-e-inspecionar-vídeos)
- [Instalar pela primeira vez](#instalar-pela-primeira-vez)
- [Organizar e cadastrar os vídeos](#organizar-e-cadastrar-os-vídeos)
- [Controles](#controles)
- [Avançar, voltar e reprodução em sequência](#avançar-voltar-e-reprodução-em-sequência)
- [Resolução e tamanho das letras](#resolução-e-tamanho-das-letras)
- [Atualizar uma instalação existente](#atualizar-uma-instalação-existente)
- [Como funciona](#como-funciona)
- [Arquivos e configurações](#arquivos-e-configurações)
- [Limitações](#limitações)
- [Resolver problemas](#resolver-problemas)
- [Desenvolvimento e verificação](#desenvolvimento-e-verificação)
- [Publicar no GitHub](#publicar-no-github)
- [Créditos e licença](#créditos-e-licença)

## Recursos

- Reprodução local de arquivos com extensão `.mp4`, inclusive `.MP4`.
- Navegação pela raiz e pelas subpastas do pendrive.
- Lista de arquivos com seleção pelo controle remoto.
- Pausa e retomada com **OK**.
- Exibição do tempo atual e da duração do vídeo.
- Barra de progresso e seleção de uma posição para avançar ou voltar.
- Acúmulo do destino ao segurar esquerda/direita, evitando mandar um salto a cada repetição da tecla.
- Próximo vídeo automático ao terminar o atual, dentro da pasta que está aberta.
- Troca manual entre vídeos com cima/baixo durante a reprodução.
- Barra que desaparece depois de **3 segundos sem interação**.
- Margens na interface para reduzir cortes de textos nas bordas da TV.
- Perfis **Padrão**, **Letras grandes** e **CRT 5"**.
- Preferência de layout salva no pendrive.
- GitHub, Instagram e YouTube com ícones, no cabeçalho dos modos ampliados e na página **Créditos**.
- Atualização do catálogo pelo próprio receptor ou por um atualizador para Windows.
- Funcionamento do player sem conexão com a internet.

## Compatibilidade e requisitos

| Item | Situação |
|---|---|
| Receptor de referência | **Multilaser RE510** |
| Firmware analisada | **V1.11.0** |
| Ambiente do aplicativo | Ginga-NCL com NCLua/Lua 5.1 |
| Módulo de tempo | `re510time63.so`, MIPS32r2 little endian, ABI O32, hard-float/FP32 |
| Pendrive | Reconhecido pelo receptor, com leitura e gravação disponíveis para o aplicativo |
| Internet no receptor | Dispensável para usar o player |
| Computador | Útil para copiar arquivos; Windows é necessário apenas para o atualizador `.cmd`/`.ps1` |

O funcionamento foi desenvolvido e testado no RE510 usado no projeto. As funções principais tiveram confirmação no aparelho durante o desenvolvimento; os últimos ajustes visuais também foram conferidos em simulação. A montagem completa de distribuição e o novo exemplo de vídeo ainda precisam ser conferidos no receptor físico. Os testes locais não garantem compatibilidade com outras revisões de firmware, modelos ou codecs.

**Ter Ginga, por si só, não garante compatibilidade.** Outro receptor precisa permitir iniciar aplicativos pelo USB, acessar os arquivos e disponibilizar um ambiente compatível. O módulo de tempo depende de bibliotecas e estruturas internas da firmware V1.11.0. Mesmo um processador MIPS ou um chipset semelhante não bastam para garantir que esse módulo funcione em outro aparelho.

Use um pendrive que o seu receptor já consiga reconhecer. O reconhecimento de FAT32, NTFS, exFAT, capacidades e partições é responsabilidade da firmware; o player não implementa um sistema de arquivos nem faz formatação.

## Quais arquivos ele reproduz?

### Extensões aceitas pelo navegador

| Extensão | Tratamento nesta versão |
|---|---|
| `.mp4` | É listada e pode ser cadastrada para reprodução. |
| `.MP4` e variações de maiúsculas/minúsculas | Também são aceitas. |
| `.mkv`, `.avi`, `.mov`, `.m4v`, `.ts`, `.webm` | Não são listadas como vídeos pelo player atual. |
| `.mp3`, `.wav`, `.aac` como arquivos separados | Não há modo de player de música nesta versão. |
| `.srt`, `.ass` e outras legendas externas | Não há carregador de legendas externas implementado. |
| `.png`, `.jpg` e outros arquivos | Não aparecem como conteúdo reproduzível no navegador de vídeos. |

**MP4 é um contêiner, não o codec do vídeo.** Dois arquivos `.mp4` podem ter codificações diferentes e apresentar resultados diferentes no mesmo receptor. Renomear `filme.mkv` para `filme.mp4` não converte o arquivo.

### Codecs e arquivo de exemplo

O aplicativo entrega a reprodução ao decodificador do receptor. Ele não inclui FFmpeg, novos codecs ou conversão dentro do Ginga.

O caminho usado como referência nos testes é **vídeo H.264/AVC com áudio AAC-LC em um contêiner MP4**. A release inclui um exemplo sintético de 30 segundos, com imagem e um tom de áudio:

| Propriedade do exemplo | Valor |
|---|---|
| Arquivo | `Videos/Exemplo-Tavinho-Play.mp4` |
| Vídeo | H.264, Constrained Baseline |
| Resolução do arquivo | 640 × 480 |
| Taxa de quadros | 25 fps |
| Formato de pixels | `yuv420p` |
| Áudio | AAC-LC, estéreo, 48 kHz |
| Duração | 30 segundos |

Esses valores descrevem o exemplo e uma configuração conservadora para experimentar. **Não representam uma especificação de limite máximo do RE510.** Perfis, níveis, resolução, bitrate, codificação de áudio e integridade dos arquivos continuam dependendo do decodificador do aparelho.

Se precisar converter um arquivo no computador, use as instruções da próxima seção. Não é necessário instalar FFmpeg para reproduzir o exemplo ou usar o aplicativo no receptor.

## Converter e inspecionar vídeos

A conversão é opcional e deve ser feita no computador, com FFmpeg instalado separadamente. O aplicativo não converte vídeos dentro do receptor.

### Conferir os codecs de um arquivo

Com `ffprobe`, execute:

```bash
ffprobe -v error -show_entries stream=codec_name,codec_type,profile,width,height,pix_fmt,sample_rate,channels -show_entries format=duration,size -of json "entrada.mp4"
```

O resultado informa codecs, perfil, resolução, áudio, duração e tamanho. Ele também pode ser usado ao relatar um problema com um vídeo específico.

### Gerar um MP4 para experimentar no RE510

O comando abaixo cria um arquivo diferente, usando H.264 Baseline, formato de pixels `yuv420p`, áudio AAC-LC estéreo e imagem de 640 × 480, com barras quando necessário:

```bash
ffmpeg -n -i "entrada.mkv" -map 0:v:0 -map 0:a:0? -vf "scale=640:480:force_original_aspect_ratio=decrease:force_divisible_by=2,pad=640:480:(ow-iw)/2:(oh-ih)/2,setsar=1" -r 25 -c:v libx264 -profile:v baseline -level:v 3.0 -pix_fmt yuv420p -crf 23 -preset veryfast -c:a aac -profile:a aac_low -b:a 128k -ac 2 -ar 48000 -movflags +faststart "saida-re510.mp4"
```

Use nomes diferentes para entrada e saída. A opção `-n` impede substituir uma saída já existente. O comando seleciona o primeiro vídeo e, se existir, o primeiro áudio; não cria som para uma entrada sem áudio e não carrega legendas externas.

Esses parâmetros são uma configuração conservadora próxima ao exemplo incluído, não uma declaração dos limites máximos do receptor. Materiais anamórficos ou com proporção de pixel especial podem exigir outro ajuste de imagem.

### Reorganizar um MP4 sem recodificar

Se os codecs já forem compatíveis, você pode reorganizar o contêiner:

```bash
ffmpeg -n -i "entrada.mp4" -map 0:v:0 -map 0:a:0? -c copy -movflags +faststart "saida-organizada.mp4"
```

`-c copy` preserva os fluxos e não resolve um codec incompatível. `+faststart` coloca o índice/cabeçalho MP4 no início. O leitor de duração do player também procura `moov` ao final de um MP4 comum, portanto essa reorganização não é obrigatória em todos os arquivos.

Depois de copiar ou renomear a saída no pendrive, atualize o catálogo e reabra o aplicativo.

## Instalar pela primeira vez

### 1. Baixe o pacote completo

Na aba **Releases** do repositório, baixe o arquivo:

```text
Tavinho-Play-v0.6.16-Completo.zip
```

O pacote completo já contém o aplicativo, os documentos NCL, o catálogo inicial, os módulos e um vídeo de exemplo. Os pacotes chamados **Atualizacao** servem para instalações que já possuem os documentos e o catálogo.

### 2. Copie para a raiz do pendrive

Extraia o ZIP e copie estes itens para a raiz:

```text
PENDRIVE/
├── ginga/
│   └── player-usb-05/
│       ├── MANIFEST
│       ├── icon.png
│       └── source/
│           ├── main_v05.ncl
│           ├── modelo_v05.ncl
│           ├── catalogo_v05.lua
│           ├── player_v05.lua
│           ├── theme.lua
│           ├── displayprefs.lua
│           ├── focussetup.lua
│           ├── seekqueue.lua
│           ├── mp4meta.lua
│           └── re510time63.so
├── Videos/
│   ├── Exemplo-Tavinho-Play.mp4
│   └── seus-videos.mp4
├── Atualizar-Player.cmd
└── Atualizar-Player.ps1
```

A pasta **`Videos` fica fora de `ginga`**, diretamente na raiz do pendrive. Evite uma pasta extra envolvendo tudo, como `PENDRIVE/Tavinho-Play-v0.6.16/ginga/`.

O nome interno `player-usb-05` foi mantido por compatibilidade com os caminhos do aplicativo. Ele não indica que o programa ainda está na versão 0.5. Mantenha esse nome e os nomes dos arquivos internos.

Os arquivos de documentação, fontes nativos e ferramentas para desenvolvedores também acompanham o pacote. Para executar no receptor, os itens essenciais são os mostrados na árvore acima.

### 3. Abra no receptor

1. Ejete o pendrive no computador e conecte-o ao RE510.
2. Pressione o botão **GINGA** do controle e abra **Tavinho Play** na lista de aplicações USB.
3. Selecione `Exemplo-Tavinho-Play.mp4` e pressione **OK**.
4. Confira imagem e áudio. Use **OK** para pausar/retomar e esquerda/direita para testar a busca.
5. Pressione **VERMELHO** ou **VOLTAR** para retornar à lista.

O exemplo já está no catálogo inicial. Seus próprios vídeos precisam ser cadastrados conforme a próxima seção.

Os documentos da instalação completa já incluem o ajuste de foco do controle remoto. Se uma instalação antiga exibir **“Controle atualizado.”**, feche o aplicativo completamente e abra novamente uma vez para carregar os documentos atualizados. O aviso não precisa se repetir a cada uso.

## Organizar e cadastrar os vídeos

Você pode criar subpastas:

```text
Videos/
├── Exemplo-Tavinho-Play.mp4
├── Gameplays/
│   ├── 01 - Primeiro video.mp4
│   └── 02 - Segundo video.mp4
└── Filmes/
    └── Meu filme.mp4
```

Ao abrir, o player tenta entrar na pasta `Videos`. Se ela não existir, começa na raiz do pendrive. **VERDE** abre a raiz; as pastas podem ser abertas com **OK**.

### Opção A — pelo receptor

1. Na lista de arquivos, pressione **AMARELO**.
2. Aguarde a leitura dos nomes dos MP4 e a mensagem **“Catálogo atualizado”**.
3. Feche completamente o aplicativo e abra **Tavinho Play** outra vez.
4. Selecione o vídeo desejado e pressione **OK**.

**Voltar do vídeo para a lista não equivale a fechar o aplicativo.** Depois de gerar o catálogo, é preciso encerrar e abrir novamente porque o Ginga carrega os elementos de mídia declarados no documento NCL na inicialização.

Faça esse procedimento quando adicionar, remover, mover ou renomear vídeos. Um arquivo pode aparecer na listagem de pastas e ainda não estar no catálogo carregado; nesse caso, ele não inicia até a atualização e a reabertura.

### Opção B — pelo Windows

1. Feche o aplicativo e conecte o pendrive ao computador.
2. Na raiz **do pendrive**, execute `Atualizar-Player.cmd`.
3. Confira a quantidade de vídeos cadastrados.
4. Ejete o pendrive, reconecte ao receptor e abra o player.

O `.cmd` chama o script PowerShell que o acompanha. Mantenha os dois juntos. O atualizador pode ser usado antes da primeira abertura e não depende do receptor conectado.

Para indicar uma unidade explicitamente pelo PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Atualizar-Player.ps1" -Raiz "E:\"
```

Troque `E:\` pela unidade correta. O atualizador lê os nomes e regrava o catálogo na pasta do aplicativo; ele não converte, move ou renomeia os vídeos. Guarda cópias dos dois arquivos anteriores do catálogo antes de substituí-los.

### Limites do catálogo

- Até **300 vídeos** cadastrados no conjunto do pendrive.
- Atualização percorre até **12 níveis de subpastas**.
- A pasta `ginga` da raiz e nomes iniciados por ponto são ignorados na montagem da biblioteca.
- A listagem de uma pasta é limitada às primeiras **1.000 entradas lidas**; esse número inclui entradas que podem não aparecer como vídeos.
- A sequência automática usa a pasta atualmente aberta, não todas as subpastas do pendrive.

Você pode remover o exemplo da pasta `Videos` e atualizar o catálogo depois.

## Controles

### Na lista de arquivos

| Botão | Ação |
|---|---|
| CIMA / BAIXO | Selecionar o item anterior ou seguinte. |
| ESQUERDA / DIREITA | Mudar a seleção por uma página. |
| OK | Abrir a pasta ou reproduzir o vídeo selecionado. |
| VERMELHO / VOLTAR | Ir para a pasta acima; na raiz, permanecer na raiz. |
| VERDE | Abrir a raiz do pendrive. |
| AMARELO | Gerar um novo catálogo; exige fechar e reabrir em seguida. |
| AZUL | Alternar o perfil de **Resolução** da interface. |
| 1 | Abrir a página **Créditos**. |

### Durante um vídeo

| Botão | Ação |
|---|---|
| OK | Pausar ou retomar. |
| DIREITA | Selecionar uma posição adiante. |
| ESQUERDA | Selecionar uma posição anterior. |
| Segurar ESQUERDA / DIREITA | Acumular o destino da busca; soltar para aplicá-lo. |
| CIMA | Abrir o vídeo anterior da pasta, se houver. |
| BAIXO | Abrir o próximo vídeo da pasta, se houver. |
| VERMELHO / VOLTAR | Parar e voltar à lista. |

O botão AZUL troca o perfil na lista, não durante o vídeo. A tecla 1 abre os créditos a partir da lista. Os antigos atalhos de teste/diagnóstico das teclas 0 e 9 não são usados pela interface atual.

### Na página Créditos

**OK**, **VERMELHO**, **VOLTAR** ou **1** retornam à lista. **AZUL** também permite alternar o perfil nessa página.

## Avançar, voltar e reprodução em sequência

Cada passo aceito de esquerda/direita seleciona aproximadamente **10 segundos** para trás ou para a frente. Ao segurar a tecla, o destino se acumula na barra. O número de passos por segundo depende dos eventos de repetição enviados pelo controle e do filtro do aplicativo.

O player aguarda uma pequena pausa na entrada, de aproximadamente **650 ms**, e então envia a busca. Assim, várias repetições são agrupadas em um destino. Enquanto uma busca aguarda confirmação do tempo real, não é enviada outra em paralelo.

- **IR PARA** indica o destino selecionado.
- **BUSCANDO** indica que o pedido foi enviado e aguarda confirmação.
- O relógio e a posição confirmada da barra acompanham a posição que o módulo consegue consultar no receptor.

Uma pequena diferença entre o destino e o ponto reproduzido pode ocorrer conforme o arquivo e o comportamento do decodificador. Uma busca sem confirmação é encerrada por timeout; o aplicativo não fica reenviando o mesmo pedido indefinidamente.

Ao terminar naturalmente um vídeo, o player procura o próximo arquivo de vídeo **na mesma lista/pasta**, pulando as entradas de pasta. No último vídeo, retorna ao menu. Não existe repetição automática do último arquivo nem avanço recursivo para outras pastas.

A lista coloca pastas antes de arquivos e ordena os nomes. Para organizar uma sequência, use prefixos como `01`, `02` e `03`.

## Resolução e tamanho das letras

O nome **Resolução**, exibido no botão AZUL, identifica o **perfil de layout do player**. Ele não muda a resolução HDMI/AV configurada no menu do receptor nem a resolução do arquivo de vídeo.

| Perfil | Itens por página | Organização |
|---|---:|---|
| **Padrão** | 6 | Lista à esquerda e créditos na coluna lateral. |
| **Letras grandes** | 4 | Lista na largura inteira, nomes ampliados e redes no cabeçalho. |
| **CRT 5"** | 3 | Nomes, tempo e controles ainda maiores; redes no cabeçalho. |

Pressione **AZUL** para alternar: Padrão → Letras grandes → CRT 5" → Padrão. A seleção é manual. Você pode usar qualquer perfil em qualquer TV, conforme a distância e o conforto de leitura.

O modo escolhido é gravado em `ginga/player-usb-05/source/tela.cfg` e restaurado na próxima abertura. Se não for possível salvar, a troca vale para a sessão e o aplicativo informa a falha. Se a preferência estiver ausente ou inválida, abre no perfil Padrão.

A barra desaparece após **3 segundos sem interação**. Os eventos de atualização do tempo não a mantêm aberta indefinidamente. Uma interação com os controles de reprodução volta a mostrá-la.

## Atualizar uma instalação existente

Para preservar seu catálogo e a configuração salva, use:

```text
Tavinho-Play-v0.6.16-Atualizacao.zip
```

1. Feche o player no receptor e retire o pendrive.
2. Copie a pasta `ginga` do pacote de atualização para a raiz do pendrive.
3. Mescle as pastas e substitua os arquivos solicitados.
4. Se quiser atualizar também a ferramenta do Windows, substitua os dois arquivos `Atualizar-Player` do pacote.
5. Reconecte e abra o aplicativo.

O pacote de atualização não inclui `main_v05.ncl`, `modelo_v05.ncl`, `catalogo_v05.lua` nem `tela.cfg`. Esses arquivos existentes são preservados. Quem vier de versões antigas pode receber o aviso único **“Controle atualizado.”** e precisar fechar/reabrir uma vez.

Para uma instalação nova, use **Completo**. Recolocar os documentos iniciais do pacote completo sobre uma instalação existente substitui o catálogo personalizado pelo catálogo do exemplo; nesse caso, gere a biblioteca novamente.

## Como funciona

O projeto tem três partes principais:

1. **Interface em Lua:** desenha o menu, lê as teclas, navega pelas pastas e mantém a sequência de vídeos.
2. **Documentos NCL e catálogo:** cada vídeo cadastrado possui uma mídia e vínculos de iniciar, parar, pausar e retomar. O player envia eventos para esses vínculos já declarados, usando o mecanismo de reprodução do Ginga.
3. **Módulo nativo de tempo:** `re510time63.so` identifica a mídia ativa e faz a integração específica com o RE510 para consultar a posição e viabilizar os comandos de busca.

A duração é lida do cabeçalho `mvhd`, dentro de `moov`, no próprio MP4. A rotina pula o conteúdo de vídeo/áudio; não carrega o arquivo inteiro em memória para obter a duração. MP4s sem duração final válida nesse cabeçalho podem ficar sem duração e sem busca disponíveis.

O módulo nativo confere trechos e estruturas da firmware antes de usar o controle específico. Durante uma reprodução compatível, ajusta temporariamente dados de estado em memória e consulta o serviço de mídia do receptor. Não grava uma nova firmware nem substitui as bibliotecas originais em flash. Ao trocar ou encerrar uma reprodução, tenta restaurar os dados ainda associados àquela mídia.

O tratamento de **VOLTAR** inclui a recuperação de foco do Ginga. Isso evita a situação observada durante o desenvolvimento em que a lista aparecia, mas as setas só voltavam a responder depois de pressionar OK.

As instruções para recompilar o módulo, verificar os arquivos e gerar os pacotes estão na seção Desenvolvimento e verificação deste README.

## Arquivos e configurações

| Arquivo | Função |
|---|---|
| `MANIFEST` | Identidade do aplicativo e ponto de entrada no Ginga. |
| `main_v05.ncl` | Documento efetivamente carregado, com os vídeos cadastrados. |
| `modelo_v05.ncl` | Modelo usado para gerar o catálogo. |
| `catalogo_v05.lua` | Mapa entre caminhos dos vídeos e identificadores NCL. |
| `player_v05.lua` | Navegação, comandos, reprodução em sequência e integração dos módulos. |
| `theme.lua` | Aparência dos menus, créditos e barra. |
| `displayprefs.lua` | Perfis de tamanho e leitura/gravação da preferência. |
| `tela.cfg` | Preferência criada quando o usuário troca o perfil. |
| `focussetup.lua` | Instalação idempotente dos vínculos de recuperação de foco. |
| `seekqueue.lua` | Agrupamento dos pedidos de busca e confirmação do destino. |
| `mp4meta.lua` | Leitura da duração a partir dos metadados MP4. |
| `re510time63.so` | Módulo nativo compilado para o RE510 analisado. |
| `Atualizar-Player.cmd` / `.ps1` | Atualizador de catálogo executado no Windows. |

Arquivos `catalogo_preparado.*` são auxiliares de geração. As cópias `*_antes_foco0610.ncl` podem ser criadas ao adaptar documentos antigos. O atualizador Windows cria `main_v05_antes_atualizacao.ncl` e `catalogo_v05_antes_atualizacao.lua` antes de gravar o catálogo novo.

Para restaurar a aparência padrão, você pode alternar com AZUL até Padrão. Também pode remover somente `tela.cfg`, com o aplicativo fechado; o arquivo será recriado quando escolher outro perfil.

Para desinstalar o player, feche-o e remova a pasta `ginga/player-usb-05` e os dois atualizadores do pendrive. A pasta dos seus vídeos é separada.

## Limitações

- Compatibilidade nativa direcionada ao **RE510 / V1.11.0**, sem promessa para outros modelos ou revisões.
- Navegador de mídia restrito a **MP4** nesta versão.
- Reprodução e codecs dependem do hardware e da firmware existentes.
- Não há streaming, download de vídeos, abertura de YouTube, navegador de internet ou conversão no receptor.
- Os endereços das redes são créditos exibidos na interface.
- Não há seleção de faixas de áudio, suporte implementado a arquivos externos de legenda, velocidade de reprodução ou retomada automática do último ponto.
- Catálogo precisa ser atualizado e recarregado quando os caminhos mudam.
- A duração depende de metadados MP4 válidos e a busca depende do módulo e do estado nativo da reprodução.
- Fechar um vídeo pode levar alguns segundos por causa da finalização do decodificador.
- Não existe emulador completo do RE510 neste repositório. Os testes locais simulam partes das APIs e dos vínculos.

## Resolver problemas

| Sintoma | O que conferir |
|---|---|
| O aplicativo não aparece no Ginga | Verifique `ginga/player-usb-05/MANIFEST`, a raiz do pendrive e se a extração não criou uma pasta extra. Abra pelo botão GINGA. |
| O pendrive é reconhecido, mas não vejo o aplicativo no navegador de arquivos comum | Use a lista de aplicações do Ginga. O reconhecimento do dispositivo USB não significa que o navegador comum execute aplicativos NCL. |
| O vídeo aparece na lista, mas diz que não está no catálogo | Use AMARELO, encerre o aplicativo completamente e abra novamente. |
| Coloquei arquivos na pasta errada | `Videos` deve ficar na raiz, fora de `ginga`. Use VERDE para conferir a raiz. |
| Não encontra vídeos | Confira a extensão real `.mp4`, o caminho e se os arquivos não estão dentro da pasta `ginga`. |
| Aparece “Controle atualizado.” | Feche e reabra uma vez para carregar os documentos ajustados. |
| O catálogo não pode ser gravado no receptor | Use o atualizador no Windows e confira se o pendrive permite gravação. |
| Tela preta ou áudio ausente em um arquivo | Teste o exemplo incluído. Confira os codecs do arquivo; a extensão MP4 sozinha não garante reprodução. |
| Tempo aparece como `--:--` ou busca fica indisponível | Confira o MP4, o módulo `re510time63.so` e a firmware. O vídeo pode não ter duração final válida ou o módulo pode não ter conseguido ativar o controle nativo. |
| A mensagem fica em BUSCANDO | Aguarde o timeout, tente um ponto mais próximo e compare com o exemplo. A posição precisa ser confirmada pelo receptor. |
| As letras estão pequenas | Use AZUL na lista e escolha Letras grandes ou CRT 5". |
| Cortes nas bordas da tela | Confira o enquadramento/overscan da TV e do receptor. O player já reserva margem para a interface. |
| Demora ao voltar de um vídeo | Uma pequena espera no encerramento do decodificador é esperada. A versão inclui recuperação de foco; não deve depender de um OK extra para navegar. |
| Mudei o tamanho e ele não ficou salvo | Confira a gravação em `source/tela.cfg`. Uma falha mantém a escolha apenas na sessão atual. |
| Não consigo sair de “Catálogo atualizado” usando OK | Encerre o aplicativo pelo comando de saída disponível no receptor e abra novamente. Essa tela pede recarga do NCL, não seleção de outro vídeo. |

Para relatar um problema, informe modelo e firmware, versão do player, layout selecionado, botão usado, mensagem exata e se o exemplo reproduz. Para problemas de mídia, informe os codecs e propriedades do arquivo. Você pode obter um relatório com o comando `ffprobe` apresentado na seção Converter e inspecionar vídeos deste README.

## Desenvolvimento e verificação

Os arquivos Lua/NCL são fornecidos no pacote. Os fontes do módulo nativo estão em `native/`; a compilação cruzada exige as bibliotecas compatíveis obtidas da firmware de referência. O dump completo e as bibliotecas originais da firmware não acompanham esta distribuição.

### Módulo nativo

O código-fonte está dividido em quatro arquivos:

- `native/re510time63.c`: interface com Lua e integração com a reprodução Ginga/IPC.
- `native/native_access.c`: localização e leitura das estruturas necessárias.
- `native/native_layout.h`: endereços e assinaturas da firmware V1.11.0.
- `native/native_control.inc`: ativação e restauração temporária dos dados da reprodução.

O nome `re510time63.so` foi mantido por compatibilidade com o carregador. Ele não indica a versão do aplicativo completo.

Para recompilar em Linux ou WSL, prepare um compilador MIPS32r2 little endian, O32, hard-float/FP32, e uma árvore privada com as bibliotecas extraídas da firmware:

```text
firmware-extraida/
├── mslib/
│   ├── liblua.so
│   ├── libipcClient.so.1.0.4
│   └── ginga/lib/ginga/
│       ├── libgingaccplayer.so
│       └── libnclipcclientmanager.so
└── rootfs/lib/
    └── libc.so.6
```

Preserve os arquivos e links de suporte que o linker precisar. Então execute, na raiz do projeto:

```bash
RE510_FIRMWARE_DIR=/caminho/firmware-extraida CC=mipsel-linux-gnu-gcc sh native/build.sh
```

A saída fica em `native/build/re510time63.so`. O script não instala o resultado no pendrive automaticamente. A compilação precisa das bibliotecas de referência; elas não são baixadas nem fornecidas pelo player.

O módulo distribuído tem SHA-256:

```text
6acc9c98dbf63334388225b9c8952eabb700db79ad95bd118f8c44b616c2c307
```

Na preparação desta release, a recompilação com o toolchain e as bibliotecas usados no projeto produziu esse mesmo hash. Outra versão de compilador/linker pode gerar um binário diferente mesmo com o mesmo código.

### Verificar e empacotar

Para verificar a estrutura e a integridade dos arquivos:

```bash
python tools/verificar_release.py
```

Para gerar os pacotes completo e de atualização a partir deste diretório:

```bash
python tools/empacotar_release.py
```

As ferramentas exigem Python **3.9 ou mais recente** no computador; Python não é necessário no receptor.

Execute essas ferramentas na cópia original do projeto, com o catálogo do exemplo. O verificador exige esse catálogo inicial limpo para evitar empacotar a biblioteca pessoal de quem estiver preparando uma release.

O empacotador grava os ZIPs, hashes e inventário em `dist/`. A pasta é uma saída local e não precisa ser enviada junto com o código-fonte do repositório.

### O que foi verificado

Na preparação da release completa foram conferidos:

- Estrutura de arquivos, manifesto, ícone, documentos NCL, áreas, conectores, referências e catálogo inicial.
- Instalação nova em simulação Lua 5.1/NCL, sem depender de uma versão antiga no pendrive.
- Início do exemplo cadastrado, busca, confirmação, ocultação da barra e retorno com os vínculos de foco.
- Troca dos layouts, preferência salva, créditos, atualização do catálogo e reabertura.
- Propriedades reais do exemplo por `ffprobe` e leitura de 30 segundos pelo `mp4meta.lua` real.
- Atualizador Windows com acentos, espaços, vírgula, `&`, subpastas, exclusões, backups e limite de 300 vídeos.
- Recompilação do módulo nativo e comparação do hash com o binário distribuído.
- Comando de conversão de vídeo executado no computador.
- Prévia visual dos três perfis em superfícies de 1280 × 720 e 720 × 480.
- Integridade dos ZIPs e comparação dos arquivos empacotados com suas origens.

Os testes de reprodução simulam eventos, teclas, vínculos e respostas do serviço de mídia. Eles não executam uma firmware completa nem comprovam nitidez em uma CRT de 5", latência do USB, comportamento de outro modelo ou compatibilidade com todos os codecs.

## Publicar no GitHub

Extraia o pacote completo e envie seu conteúdo para a raiz do repositório, mantendo `README.md` nessa raiz. Preserve as pastas do código e não inclua saídas locais de `dist/`, `native/build/`, preferências pessoais ou cópias privadas da firmware.

Para a release desta versão, use:

- **Tag:** `v0.6.16`.
- **Título sugerido:** `Tavinho Play v0.6.16 — Player USB para Multilaser RE510`.
- **Anexos:** `Tavinho-Play-v0.6.16-Completo.zip`, `Tavinho-Play-v0.6.16-Atualizacao.zip` e `SHA256SUMS-v0.6.16.txt`.

Identifique o completo como o pacote de primeira instalação e a atualização como a opção que preserva o catálogo existente. O GitHub também oferece arquivos automáticos do código-fonte da tag; os nomes dos anexos acima ajudam a distinguir o pacote pronto para uso.

A licença geral do projeto ficou para uma decisão posterior do responsável. Mantenha os avisos dos componentes de terceiros ao preparar o repositório.

## Créditos e licença

**Tavinho Play / Tavinho Games**

- [GitHub — Guga-Tavinho](https://github.com/Guga-Tavinho)
- [Instagram — tavinho.games](https://www.instagram.com/tavinho.games)
- [YouTube — @tavinho-games](https://www.youtube.com/@tavinho-games)

Ícones de GitHub, Instagram, YouTube, pasta e retorno derivados de **Feather Icons**, Copyright (c) 2013–2023 Cole Bemis, sob licença MIT. O pacote inclui os avisos de terceiros e a licença integral dos ícones.

O Ginga, o sistema do receptor e seus componentes mantêm suas próprias autorias e licenças. As fontes tipográficas e as bibliotecas originais já presentes na firmware não são redistribuídas neste pacote.

A licença geral do código do Tavinho Play ainda não foi definida pelo responsável. A licença MIT dos ícones não atribui automaticamente essa licença aos demais arquivos do projeto.
