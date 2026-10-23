-- Player USB RE510 0.6.16. Aplicativo local, sem alteracao do firmware.
local ev = require('event')
local okdir, dirs = pcall(require, 'dir')
local okusb, usb = pcall(require, 'usbmonitor')
if type(dirs) ~= 'table' then dirs = _G.dir end
if type(usb) ~= 'table' then usb = _G.usbmonitor end

local W,H = canvas:attrSize()
W,H = tonumber(W) or 1280,tonumber(H) or 720
local scale = math.min(W/1280,H/720)
local function px(n) return math.max(1,math.floor(n*scale)) end
-- Margem para TVs que cortam as bordas (overscan). Afeta somente a interface.
local uiScale = 0.88
local uiLeft = (1280-1280*uiScale)/2
local uiTop = (720-720*uiScale)/2
local items, selected, current, root = {},1,'',''
local displayPrefs=require('displayprefs')
local displayIndex=1
local pageSize=displayPrefs.profiles[displayIndex].rows
local message = 'Procurando pendrive...'
local restartTitle='Catalogo atualizado.'
local mode, paused, sequence = 'menu',false,0
local active = nil
local okcatalogue, catalogue = pcall(require,'catalogo_v05')
if not okcatalogue or type(catalogue)~='table' then catalogue={} end
local activeBuiltin, playbackState, selectedFile = false,'',''
local failureTitle = 'Falha ao ler a pasta'
local pendingToken = 0
local recentKey, recentTime = '',-1000
local lastFailure = ''

local function basename(path) return (path:gsub('/+$',''):match('([^/]+)$')) or path end
local function join(a,b) return a:gsub('/+$','')..'/'..b:gsub('^/+','') end
local function parent(path)
  if path == root then return root end
  local p = path:gsub('/+$',''):match('^(.*)/[^/]+$') or root
  if #p < #root then return root end
  return p
end
local function within(path)
  return path == root or path:sub(1,#root+1) == root..'/'
end
local function displayPath(path)
  if path == root then return '/ (pendrive)' end
  if path:sub(1,#root) == root then return path:sub(#root+1) end
  return path
end
local function clip(s,n)
  local chars={}
  for c in tostring(s):gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    chars[#chars+1]=c
    if #chars>n then chars[n]='...';return table.concat(chars,'',1,n) end
  end
  return table.concat(chars)
end
local function color(r,g,b,a) canvas:attrColor(r,g,b,a or 255) end
local function rect(x,y,w,h,r,g,b,a)
  -- Quantize shared edges together so enlarged icon runs stay connected.
  local left,top=px(uiLeft+x*uiScale),px(uiTop+y*uiScale)
  local right,bottom=px(uiLeft+(x+w)*uiScale),px(uiTop+(y+h)*uiScale)
  color(r,g,b,a);canvas:drawRect('fill',left,top,math.max(1,right-left),math.max(1,bottom-top))
end
local function text(x,y,s,size,r,g,b,weight)
  color(r or 236,g or 241,b or 248)
  -- Use the screenfont already validated before the visual redesign.
  canvas:attrFont('Tiresias',px((size or 27)*uiScale),'normal')
  canvas:drawText(px(uiLeft+x*uiScale),px(uiTop+y*uiScale),tostring(s))
end
local themeOk,themeModule=pcall(require,'theme')
local appTheme=nil
if themeOk and type(themeModule)=='table' and type(themeModule.new)=='function' then
  local ok,result=pcall(themeModule.new,rect,text,clip)
  if ok then appTheme=result end
end
local function clearScreen()
  canvas:attrColor(0,0,0,0);canvas:clear();canvas:flush()
end
local drawTimeline,beginTimeline,resetTimeline,loadTimeModule,seekVideo
local function draw()
  if mode=='playing' then drawTimeline();return end
  if appTheme then
    color(9,14,23);canvas:clear()
    local ok=pcall(appTheme.menu,{mode=mode,restartTitle=restartTitle,path=displayPath(current),
      items=items,selected=selected,pageSize=pageSize,message=message,
      profile=displayPrefs.profiles[displayIndex].id,profileName=displayPrefs.profiles[displayIndex].name,
      failureTitle=failureTitle,failure=lastFailure})
    if ok then canvas:flush();return end
    appTheme=nil
  end
  color(13,19,30);canvas:clear()
  rect(0,0,1280,133,20,31,46)
  rect(52,40,7,47,56,207,182)
  text(82,36,'PLAYER USB 0.6.16',36,255,255,255)
  text(84,85,mode=='loading' and 'Abrindo video...' or 'Escolha um video MP4',23,166,190,212)
  text(55,151,clip(displayPath(current),79),22,128,199,221)
  if mode=='restart' then
    text(65,225,restartTitle,32,94,232,199)
    text(65,295,'Feche este aplicativo e abra Tavinho Play novamente.',25)
    text(65,345,'A nova lista fica disponivel ao reabrir o player.',23,166,190,212)
  elseif mode=='error' then
    text(65,192,failureTitle,28,255,191,116)
    local y,line=238,lastFailure
    while #line>0 and y<600 do
      text(65,y,line:sub(1,87),19,215,229,242);line=line:sub(88);y=y+27
    end
  elseif mode=='loading' then
    text(65,240,clip(message,70),28)
    text(65,295,'Carregando o video...',23,166,190,212)
    text(65,335,'VERMELHO cancela e volta para a lista.',23,166,190,212)
  elseif #items==0 then
    text(65,240,'Nenhum video MP4 nesta pasta.',29)
    text(65,291,'Coloque seus videos na pasta Videos do pendrive.',23,166,190,212)
    text(65,331,'AMARELO atualiza a lista. VERDE abre a raiz.',23,166,190,212)
  else
    local first=math.floor((selected-1)/pageSize)*pageSize+1
    for row=0,pageSize-1 do
      local index=first+row;local item=items[index]
      if item then
        local y=195+row*49
        if index==selected then rect(48,y-3,1184,46,33,104,108) end
        text(66,y+3,item.parent and '<' or (item.folder and '+' or '>'),26,94,232,199)
        text(112,y+3,clip(item.name,68),26)
        if item.folder then text(1110,y+5,'PASTA',19,167,204,213) end
      end
    end
    text(57,603,tostring(selected)..' / '..tostring(#items)..'     Esquerda / direita: paginas',20,153,175,198)
  end
  rect(0,642,1280,78,20,31,46)
  text(55,650,clip(message,94),19,158,187,209)
  text(55,680,'OK abrir  VERMELHO voltar  VERDE raiz  AMARELO atualizar',19,225,234,242)
  canvas:flush()
end
local function safeDraw()
  pcall(draw)
end
local function fail(err)
  local detail=tostring(err)
  -- Keep actionable errors without Lua source locations or internal logs.
  for _=1,3 do detail=detail:gsub('^.-:%d+:%s*','') end
  if detail:find('Permission Denied',1,true) then detail='Nao foi possivel acessar esta pasta no pendrive.' end
  mode='error';lastFailure=detail;message='VERMELHO volta para a lista.';safeDraw()
end
-- The validated 0.6.3 module enables the native time callbacks and duration
-- cache for each identified playback. Until activation succeeds, retain the
-- presentation clock; only native position readings can confirm a seek.
local timeModule, timeError = nil,'Modulo de tempo ainda nao carregado'
local nativeEnabled=false
local seekQueue,cancelSeek,armSeekPump
local seekPumpGeneration,seekPumpDue=0,nil
local autoNative=nil
-- Observed on the RE510: setCurrentTime answers -1 for USB media. Once refused,
-- stop repeating the request for this video; reset on the next playback.
local seekRefused = false
local timeline = {visible=false,untilTime=0,position=nil,duration=nil,id=nil,notice='',noticeUntil=0,offset=0}
loadTimeModule=function()
  local oldPath=package.cpath
  -- The app folder is the working directory (see readFile); keep the USB path as fallback.
  local localPath=(type(basedir_file)=='string' and basedir_file..'/?.so;' or '')..'./?.so;'..root..'/ginga/player-usb-05/source/?.so'
  package.cpath=localPath..';'..tostring(oldPath or '')
  local ok,result=pcall(require,'re510time63')
  package.cpath=oldPath
  if ok and type(result)=='table' and type(result.status)=='function' and type(result.seek)=='function' then
    timeModule=result;timeError=''
  else
    timeError=tostring(result)
  end
end
local function clockText(seconds)
  if type(seconds)~='number' then return '--:--' end
  seconds=math.max(0,math.floor(seconds))
  local h=math.floor(seconds/3600);local m=math.floor(seconds/60)%60;local s=seconds%60
  if h>0 then return string.format('%d:%02d:%02d',h,m,s) end
  return string.format('%02d:%02d',m,s)
end
local metadata=require('mp4meta')
local showTimeline
local timelineHideGeneration,timelineHideArmed=0,false
local function mp4Duration(path)
  return metadata.duration(path,root)
end
local function releaseNative()
  if cancelSeek then cancelSeek('parada/troca') end
  if timeModule and type(timeModule.restore)=='function' then
    pcall(timeModule.restore)
  end
  nativeEnabled=false;autoNative=nil
end
local function enableNative()
  if nativeEnabled then return true end
  if paused or not timeline.duration or not timeline.id then return false end
  if not timeModule or type(timeModule.enable)~='function' then return false end
  local path=selectedFile
  if path:sub(1,1)~='/' and type(basedir_file)=='string' then
    path=basedir_file:gsub('/+$','')..'/'..path
  end
  local ok,result=pcall(timeModule.enable,path,math.floor(timeline.duration),timeline.id)
  local enabled=ok and type(result)=='table' and result.native==1
  if enabled then
    nativeEnabled=true;seekRefused=false;timeError=''
    timeline.position=tonumber(result.position);timeline.offset=0
    showTimeline('Segure ESQ / DIR para escolher. Solte para ir. OK: pausar',true)
  end
  return enabled
end
local function tryAutoNative()
  if nativeEnabled or not autoNative or autoNative.done then return end
  if not timeModule or type(timeModule.enable)~='function' or not timeline.duration then
    autoNative.done=true;return
  end
  if paused or not timeline.id or ev.uptime()<autoNative.nextTry then return end
  autoNative.attempts=autoNative.attempts+1
  if enableNative() then autoNative.done=true
  elseif autoNative.attempts>=4 then
    autoNative.done=true
    showTimeline('Avanco e retorno indisponiveis neste video.',true)
  else autoNative.nextTry=ev.uptime()+math.min(3000,autoNative.attempts*1000) end
end
resetTimeline=function()
  timelineHideGeneration=timelineHideGeneration+1;timelineHideArmed=false
  if cancelSeek then cancelSeek('novo video') end
  if seekQueue then seekQueue:reset() end
  timeline={visible=false,untilTime=0,position=nil,duration=nil,id=nil,notice='',noticeUntil=0,offset=0}
end
showTimeline=function(notice,passive)
  if notice then timeline.notice=notice;timeline.noticeUntil=ev.uptime()+5000 end
  -- Decoder feedback updates the message without extending user activity.
  if passive then return end
  timeline.visible=true;timeline.untilTime=ev.uptime()+3000
  -- Keep one idle timer, even while receiving many remote key repeats.
  if timelineHideArmed then return end
  timelineHideArmed=true
  local generation,token=timelineHideGeneration,pendingToken
  local function hideWhenIdle()
    if generation~=timelineHideGeneration or token~=pendingToken or mode~='playing' then return end
    local remaining=timeline.untilTime-ev.uptime()
    if remaining>0 then ev.timer(remaining,hideWhenIdle);return end
    timelineHideArmed=false;timeline.visible=false
    safeDraw()
  end
  ev.timer(3000,hideWhenIdle)
end
local function readTimeline()
  if not timeModule then return false end
  local ok,result,err=pcall(timeModule.status)
  if not ok or type(result)~='table' then
    timeError=tostring(err or result);return false
  end
  local clock,id=tonumber(result.clock),tonumber(result.id)
  if not clock or not id then timeError='Resposta invalida do modulo de tempo';return false end
  if timeline.id and timeline.id~=id then
    timeline.offset=0;if cancelSeek then cancelSeek('ID alterado') end
  end
  local isNative=result.native==1
  if nativeEnabled and not isNative then
    nativeEnabled=false;if cancelSeek then cancelSeek('controle perdido') end
    autoNative={attempts=0,nextTry=ev.uptime()+1500,done=false}
  end
  local pos=isNative and tonumber(result.position) or math.max(0,clock/1000+timeline.offset)
  if not pos or pos<0 then timeError='Posicao nativa indisponivel';return false end
  if timeline.duration then pos=math.min(pos,timeline.duration) end
  timeline.position=pos;timeline.id=id;timeError=''
  if isNative and seekQueue then seekQueue:observe(pos,id,ev.uptime(),paused,timeline.duration) end
  if timeline.notice~='' and ev.uptime()>timeline.noticeUntil then timeline.notice='' end
  return true
end
local SeekQueue=require('seekqueue')
seekQueue=SeekQueue.new({
  quiet=650,timeout=5000,cooldown=250,minStep=120,
  send=function(target,id)
    if mode~='playing' or not nativeEnabled or timeline.id~=id then return nil,'O video ativo mudou' end
    return timeModule.seek(target,id)
  end,
  event=function(kind,data)
    if kind=='selected' then
      showTimeline('Escolhendo destino. Solte a seta para aplicar.',true)
    elseif kind=='sent' then
      showTimeline('Buscando '..clockText(data.target)..'...',true)
    elseif kind=='confirmed' or kind=='reached' then
      if seekQueue:selection() then showTimeline('Proximo destino: '..clockText(seekQueue:selection()),true)
      else showTimeline('',true) end
    elseif kind=='timeout' then
      showTimeline('Nao foi possivel mudar a posicao. Tente novamente.')
    elseif kind=='failed' then
      if tonumber(data.reply)==-1 then seekRefused=true end
      showTimeline('Nao foi possivel avancar ou voltar neste video.')
    elseif kind=='noop' then showTimeline('Video ja esta nessa posicao.',true) end
  end
})
cancelSeek=function(reason)
  seekPumpGeneration=seekPumpGeneration+1;seekPumpDue=nil
  seekQueue:cancel(reason)
end
armSeekPump=function()
  local now=ev.uptime();local delay=seekQueue:delay(now)
  if not delay or mode~='playing' or not nativeEnabled then return end
  local due=now+delay
  -- Key repeats must not postpone an already scheduled confirmation check.
  if seekPumpDue and seekPumpDue<=due then return end
  seekPumpGeneration=seekPumpGeneration+1
  local generation,token=seekPumpGeneration,pendingToken
  seekPumpDue=due
  ev.timer(math.max(1,delay),function()
    if generation~=seekPumpGeneration or token~=pendingToken or mode~='playing' or not nativeEnabled then return end
    seekPumpDue=nil
    if seekQueue:busy() or seekQueue:ready(ev.uptime()) then
      local busy=seekQueue:busy()
      if not readTimeline() and not busy then
        cancelSeek('posicao indisponivel');showTimeline('Posicao indisponivel. Tente novamente.');safeDraw();return
      end
    end
    if generation~=seekPumpGeneration or token~=pendingToken or mode~='playing' or not nativeEnabled then return end
    seekQueue:tick(ev.uptime())
    safeDraw();armSeekPump()
  end)
end

drawTimeline=function()
  canvas:attrColor(0,0,0,0);canvas:clear()
  if not timeline.visible then canvas:flush();return end
  if appTheme then
    local destination=seekQueue and seekQueue:selection()
    local notice
    if not timeModule then notice='Tempo do video indisponivel.'
    elseif timeError~='' then notice=timeline.notice~='' and timeline.notice or 'Carregando o tempo do video...'
    else notice=timeline.notice~='' and timeline.notice or
      (not nativeEnabled and ((autoNative and autoNative.done) and
        'Avanco e retorno indisponiveis. OK: pausar' or 'Preparando avancar/voltar...   OK: pausar') or
       seekRefused and 'OK: pausar   CIMA / BAIXO: outro video' or
       'Segure ESQ / DIR para escolher. Solte para ir. OK: pausar') end
    local ok=pcall(appTheme.timeline,{filename=basename(selectedFile),clock=clockText(timeline.position),
      total=clockText(timeline.duration),position=timeline.position,duration=timeline.duration,
      target=destination,destination=destination and clockText(destination),
      waiting=seekQueue and not seekQueue.dirty,paused=paused,notice=notice,
      profile=displayPrefs.profiles[displayIndex].id})
    if ok then canvas:flush();return end
    appTheme=nil;canvas:attrColor(0,0,0,0);canvas:clear()
  end
  rect(35,524,1210,174,13,24,38,235)
  text(60,540,clip(basename(selectedFile),75),23,236,244,250)
  text(60,576,clockText(timeline.position)..' / '..clockText(timeline.duration),24,94,232,199)
  local destination=seekQueue and seekQueue:selection()
  if destination then
    text(760,576,(seekQueue.dirty and 'IR PARA ' or 'BUSCANDO ')..clockText(destination),23,255,198,82)
  else text(920,576,paused and 'PAUSADO' or 'REPRODUZINDO',20,185,210,225) end
  rect(60,615,1160,8,61,78,95)
  if timeline.position and timeline.duration then
    local amount=math.floor(1160*math.min(1,timeline.position/timeline.duration))
    if amount>0 then rect(60,615,amount,8,56,207,182) end
  end
  if destination and timeline.duration and timeline.duration>0 then
    local marker=60+1160*math.min(1,destination/timeline.duration)
    rect(math.max(60,math.min(1214,marker-3)),608,6,22,255,198,82)
  end
  if not timeModule then
    text(60,636,'Tempo do video indisponivel.',20,255,191,116)
  elseif timeError~='' then
    text(60,636,clip(timeline.notice~='' and timeline.notice or 'Carregando o tempo do video...',102),20,255,191,116)
  else
    text(60,636,clip(timeline.notice~='' and timeline.notice or
      (not nativeEnabled and ((autoNative and autoNative.done) and
        'Avanco e retorno indisponiveis. OK: pausar' or
        'Preparando avancar/voltar...   OK: pausar') or
       seekRefused and 'OK: pausar   CIMA / BAIXO: outro video' or
      'Segure ESQ / DIR para escolher. Solte para ir. OK: pausar'),102),20,216,229,242)
  end
  canvas:flush()
end
beginTimeline=function()
  resetTimeline();seekRefused=false;showTimeline()
  autoNative={attempts=0,nextTry=ev.uptime()+1500,done=false}
  local ok,dur=pcall(mp4Duration,selectedFile)
  if ok and dur then timeline.duration=dur end
  local token=pendingToken
  local function poll()
    if token~=pendingToken or mode~='playing' then return end
    readTimeline()
    tryAutoNative()
    safeDraw()
    ev.timer(1000,poll)
  end
  -- Let the native decoder finish registering its media before querying it.
  ev.timer(500,poll)
end
seekVideo=function(delta,kind)
  showTimeline()
  if not nativeEnabled then
    showTimeline((autoNative and not autoNative.done) and 'Preparando controle de video. Aguarde um instante.' or
      'Avanco e retorno indisponiveis neste video.');safeDraw();return
  end
  if seekRefused then showTimeline('Avanco e retorno indisponiveis neste video.');safeDraw();return end
  if seekQueue:needsPosition(ev.uptime()) then
    if not readTimeline() then
      showTimeline('Posicao indisponivel. Tente novamente.');safeDraw();return
    end
  end
  if not nativeEnabled then return end
  seekQueue:move(delta,ev.uptime())
  armSeekPump();safeDraw()
end

-- Verified in the supplied firmware: /usb is a symlink to /Customer/usb/.
-- usbmonitor reports /Customer/usb/sda1, while the app runs under /usb/sda1.
-- Normalize BOTH names before listing or comparing a returned entry.
local USB_TARGET = '/Customer/usb'
local function usbPath(path)
  path = tostring(path):gsub('/+$','')
  if path == USB_TARGET or path:sub(1,#USB_TARGET+1) == USB_TARGET..'/' then
    return '/usb' .. path:sub(#USB_TARGET+1)
  end
  return path
end
-- dir.so checks the literal prefix /mnt before calling opendir unchanged.
-- /mnt exists in this firmware, so Linux resolves this alias to the USB.
-- Use the alias for directory reads only; media uses the normal /usb path.
local LIST_ALIAS = '/mnt/..'
local function listingPath(path)
  path = usbPath(path)
  if path == '/usb' or path:sub(1,5) == '/usb/' then
    return LIST_ALIAS .. path
  end
  return path
end
local function physicalPath(path)
  if path:sub(1,#LIST_ALIAS+1) == LIST_ALIAS..'/' then
    path = path:sub(#LIST_ALIAS+1)
  end
  return usbPath(path)
end
local function listDirectory(path)
  if not dirs or type(dirs.list)~='function' then error('Modulo dir indisponivel no Ginga') end
  local requested=listingPath(path)
  local ok,iterator=pcall(dirs.list,requested)
  if not ok then error(iterator) end
  if type(iterator)~='function' then error('Listagem do pendrive indisponivel') end
  return function()
    local value=iterator()
    if value~=nil then return physicalPath(tostring(value)) end
  end
end
local function isdir(path)
  if not dirs or type(dirs.list)~='function' then return false end
  -- dir.list returns full paths; its API was checked in dir.so from the firmware.
  local ok,iterator=pcall(listDirectory,path)
  if not ok or type(iterator)~='function' then return false end
  -- Do not traverse here. The native iterator's userdata is closed by its GC.
  iterator=nil
  return true
end
local function scan(path)
  failureTitle='Falha ao ler a pasta'
  lastFailure=''
  if not okdir or not dirs or type(dirs.list)~='function' then
    error('Modulo dir indisponivel no Ginga')
  end
  if not within(path) then error('Pasta fora do pendrive') end
  local listed={}
  local count=0
  for entry in listDirectory(path) do
    count=count+1
    if count>1000 then break end
    local full=tostring(entry)
    if full:sub(1,1)~='/' then full=join(path,full) end
    local name=basename(full)
    if name:sub(1,1)~='.' and within(full) then
      if name:lower():match('%.mp4$') then
        listed[#listed+1]={name=name,path=full,folder=false}
      elseif isdir(full) then
        listed[#listed+1]={name=name,path=full,folder=true}
      end
    end
  end
  table.sort(listed,function(a,b)
    if a.folder~=b.folder then return a.folder end
    return a.name:lower()<b.name:lower()
  end)
  if path~=root then table.insert(listed,1,{name='.. Voltar',path=parent(path),folder=true,parent=true}) end
  items,current,selected=listed,path,1
  mode='menu';message='OK abre o item selecionado.'
  if count>1000 then message='Pasta grande: mostrando os primeiros 1000 itens lidos.' end
  collectgarbage('collect')
  safeDraw()
end
local function xml(s)
  return tostring(s):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;'):gsub('"','&quot;'):gsub("'",'&apos;'):gsub(',', '&#44;')
end
local function signal(label)
  if activeBuiltin then
    local mapped={abrir='testeAbrir',parar='testeParar',pausar='testePausar',continuar='testeContinuar'}
    label=mapped[label] or label
  elseif active then label=label..'_'..active
  else return end
  ev.post('out',{class='ncl',type='presentation',action='start',label=label})
  -- Let Ginga process the beginning before ending this short control anchor.
  ev.timer(80,function()
    pcall(ev.post,'out',{class='ncl',type='presentation',action='stop',label=label})
  end)
end
-- BACK also deselects the Lua application in this firmware. Re-enter its
-- NCL key-master selection after the native BACK handler has finished.
local menuFocusGeneration=0
local function queueMenuFocus()
  menuFocusGeneration=menuFocusGeneration+1
  local generation,token=menuFocusGeneration,pendingToken
  ev.timer(200,function()
    if generation~=menuFocusGeneration or token~=pendingToken or mode~='menu' then return end
    pcall(ev.post,'out',{class='ncl',type='presentation',action='start',label='usbRetomarControle'})
    ev.timer(80,function()
      if mode~='closed' then
        pcall(ev.post,'out',{class='ncl',type='presentation',action='stop',label='usbRetomarControle'})
      end
    end)
  end)
end
local function removeActive()
  active=nil;activeBuiltin=false
end
local function hex(s)
  return (tostring(s):gsub('.',function(c) return string.format('%02x',string.byte(c)) end))
end
local function relativePath(path)
  if not within(path) then error('Arquivo fora do pendrive') end
  return path:sub(#root+2)
end
local function readFile(name)
  if not io or type(io.open)~='function' then error('Este Ginga nao permite atualizar arquivos. Use Atualizar-Player.cmd no computador.') end
  local f,e=io.open(name,'rb');if not f then error('Nao foi possivel ler '..name..': '..tostring(e)) end
  local data=f:read('*a');f:close();if not data then error('Leitura incompleta de '..name) end
  return data
end
local function writeFile(name,data)
  local f,e=io.open(name,'wb');if not f then error('Nao foi possivel gravar '..name..': '..tostring(e)..'. Use Atualizar-Player.cmd no computador.') end
  local ok,err=f:write(data)
  local closed,ce=f:close()
  if not ok or not closed then error('Falha ao gravar '..name..': '..tostring(err or ce)) end
end
local function changeDisplay()
  displayIndex=displayIndex%#displayPrefs.profiles+1
  local profile=displayPrefs.profiles[displayIndex]
  pageSize=profile.rows
  local saved=displayPrefs.save(writeFile,readFile,displayIndex)
  message=saved and ('Resolução: '..profile.name..' - salva.') or 'Resolução nao salva no USB.'
  safeDraw()
end
local function catalogueParts(paths)
  local areas,media,links,map={},{},{},{'return {\n'}
  local function binding(role,component,interface)
    return '<bind role="'..role..'" component="'..component..'"'..(interface and ' interface="'..interface..'"' or '')..'/>'
  end
  for i,path in ipairs(paths) do
    local id=string.format('v%04d',i)
    local rel=relativePath(path)
    map[#map+1]='["'..hex(rel)..'"]="'..id..'",\n'
    media[#media+1]='<media id="'..id..'" src="'..xml('../../../'..rel)..'" type="video/mp4" descriptor="dVideo"/>'
    for _,pair in ipairs({{'abrir','start'},{'parar','stop'},{'pausar','pause'},{'continuar','resume'}}) do
      local label=pair[1]..'_'..id
      areas[#areas+1]='<area id="'..label..'" label="'..label..'"/>'
      links[#links+1]='<link id="l_'..label..'" xconnector="c_'..pair[2]..'">'..
        binding('onBegin','controller',label)..binding(pair[2],id)..'</link>'
    end
    for _,p in ipairs({{'tocando','onBegin','c_inicio'},{'fim','onEnd','c_fim'}}) do
      links[#links+1]='<link id="l_'..p[1]..'_'..id..'" xconnector="'..p[3]..'">'..
        '<linkParam name="valor" value="'..p[1]..':'..id..'"/>'..
        binding(p[2],id)..binding('set','controller','estado')..'</link>'
    end
  end
  map[#map+1]='}\n'
  return table.concat(areas,'\n'),table.concat(media,'\n'),table.concat(links,'\n'),table.concat(map)
end
local function rebuildCatalogue()
  failureTitle='Falha ao atualizar o catalogo'
  lastFailure='';message='Lendo os MP4 do pendrive...';safeDraw()
  -- Read all existing sources before any write. Only files in this app are changed.
  local template=readFile('modelo_v05.ncl')
  local oldNcl=readFile('main_v05.ncl')
  local oldMap=readFile('catalogo_v05.lua')
  local paths,seen={},{ }
  local function walk(path,depth)
    if depth>12 or seen[path] then return end
    seen[path]=true
    for entry in listDirectory(path) do
      local full=tostring(entry)
      if full:sub(1,1)~='/' then full=join(path,full) end
      local name=basename(full)
      if name:sub(1,1)~='.' and within(full) then
        if name:lower():match('%.mp4$') then
          paths[#paths+1]=full
          if #paths>300 then error('Mais de 300 videos. Reduza a biblioteca para atualizar o catalogo neste receptor.') end
        elseif not (path==root and name:lower()=='ginga') and isdir(full) then walk(full,depth+1) end
      end
    end
  end
  walk(root,0)
  table.sort(paths,function(a,b) return a:lower()<b:lower() end)
  local areas,media,links,map=catalogueParts(paths)
  local ncl=template
  for _,p in ipairs({{'<!--USB_AREAS-->',areas},{'<!--USB_MEDIA-->',media},{'<!--USB_LINKS-->',links}}) do
    local marker=p[1]:gsub('(%W)','%%%1')
    local count
    ncl,count=ncl:gsub(marker,function() return p[2] end)
    if count~=1 then error('Modelo do catalogo invalido') end
  end
  -- Stage and verify the new document before replacing the app's entry point.
  writeFile('catalogo_preparado.ncl',ncl)
  if readFile('catalogo_preparado.ncl')~=ncl then error('Verificacao da gravacao falhou') end
  local ok,e=pcall(function() writeFile('main_v05.ncl',ncl);writeFile('catalogo_v05.lua',map) end)
  if not ok then
    pcall(writeFile,'main_v05.ncl',oldNcl);pcall(writeFile,'catalogo_v05.lua',oldMap)
    error(e)
  end
  -- Keep the loaded map: the current NCL is still in memory until reopening.
  mode='restart';message='Catalogo atualizado. Feche o aplicativo e abra Tavinho Play novamente.'
  safeDraw()
end
local function stopToMenu()
  releaseNative()
  pendingToken=pendingToken+1
  mode='menu';paused=false;lastFailure=''
  if active then pcall(signal,'parar') end
  message='Escolha outro video. OK abre.';safeDraw();queueMenuFocus()
end
local function openVideo(item)
  if mode=='loading' then return end
  releaseNative()
  pendingToken=pendingToken+1
  local token=pendingToken
  failureTitle='Falha ao abrir o video'
  lastFailure=''
  selectedFile=item.path
  resetTimeline()
  mode='loading'
  if active then pcall(signal,'parar') end
  local selectedId
  if not item.builtin then
    selectedId=catalogue[hex(relativePath(item.path))]
    if not selectedId then
      fail('Este video ainda nao esta no catalogo. Volte com VERMELHO, pressione AMARELO e depois feche e abra o player.');return
    end
  end
  mode='loading';message=item.name;safeDraw()
  ev.timer(300,function()
    if token~=pendingToken then return end
    removeActive()
    if item.builtin then active='videoTeste';activeBuiltin=true;playbackState='teste'
    else active=selectedId;activeBuiltin=false;playbackState=selectedId end
    message='Solicitando inicio: '..item.name;safeDraw()
    local ok,err=pcall(signal,'abrir')
    if not ok then fail(err);return end
    ev.timer(12000,function()
      if token~=pendingToken or mode~='loading' then return end
      pcall(signal,'parar')
      fail('Nao foi possivel iniciar este video. Tente outro arquivo.')
    end)
  end)
end
local function initialize()
  if not okusb or not usb or type(usb.getCurrentExternalDisk)~='function' then error('Nao foi possivel localizar o pendrive') end
  local detected=tostring(usb.getCurrentExternalDisk() or ''):gsub('/+$','')
  if detected=='' or detected=='/' then error('Pendrive nao localizado; reconecte e abra novamente') end
  root=usbPath(detected)
  displayIndex=displayPrefs.load(readFile)
  pageSize=displayPrefs.profiles[displayIndex].rows
  local okFocus,focusSetup=pcall(require,'focussetup')
  if not okFocus or type(focusSetup)~='table' or type(focusSetup.install)~='function' then
    error('Copie tambem focussetup.lua para a pasta source e reabra o aplicativo.')
  end
  if focusSetup.install(readFile,writeFile) then
    mode='restart';restartTitle='Controle atualizado.'
    message='Feche o aplicativo e abra novamente para concluir a atualizacao.'
    safeDraw();return
  end
  loadTimeModule()
  current=root
  if isdir(join(root,'Videos')) then scan(join(root,'Videos')) else scan(root) end
end
local function moveSelection(delta)
  if #items==0 then return end
  selected=math.max(1,math.min(#items,selected+delta));safeDraw()
end
local function nextVideo(delta)
  local i=selected+delta
  while i>=1 and i<=#items do
    if not items[i].folder then selected=i;openVideo(items[i]);return end
    i=i+delta
  end
end
local function finishVideo()
  releaseNative()
  local nextIndex=nil
  if not activeBuiltin then
    for i=selected+1,#items do
      if not items[i].folder then nextIndex=i;break end
    end
  end
  pendingToken=pendingToken+1
  local token=pendingToken
  paused=false
  if not nextIndex then
    mode='menu'
    message='Fim da lista de videos.'
    safeDraw();return
  end
  mode='loading';message='Proximo video: '..items[nextIndex].name;safeDraw()
  -- Acknowledge the end event before starting a new media in the formatter.
  -- RED cancels this pending transition through pendingToken.
  ev.timer(150,function()
    if token~=pendingToken or mode~='loading' then return end
    selected=nextIndex;mode='menu'
    local ok,err=pcall(openVideo,items[selected])
    if not ok then fail(err) end
  end)
end
local function seekDirection(key)
  key=tostring(key or ''):upper()
  if key=='CURSOR_RIGHT' or key=='RIGHT' or key=='FASTFORWARD' then return 1 end
  if key=='CURSOR_LEFT' or key=='LEFT' or key=='REWIND' then return -1 end
end
local function handleKey(key,kind)
  key=tostring(key or ''):upper()
  local now=ev.uptime()
  if not (mode=='playing' and seekDirection(key)) and key==recentKey and now-recentTime<160 then return end
  recentKey,recentTime=key,now
  local okkey=(key=='ENTER' or key=='OK' or key=='SELECT')
  local red=(key=='RED' or key=='F1' or key=='STOP' or key=='BACK' or key=='BACKSPACE')
  if (key=='BLUE' or key=='F4') and appTheme and
      (mode=='menu' or mode=='about' or mode=='error' or mode=='restart') then
    changeDisplay();return
  end
  if mode=='about' then
    if red or okkey or key=='1' then
      mode='menu';message='OK abre o item selecionado.';safeDraw()
      if key=='BACK' or key=='BACKSPACE' then queueMenuFocus() end
    end
    return
  end
  if mode=='restart' then return end
  if mode=='error' then
    if red then stopToMenu()
    elseif key=='YELLOW' or key=='F3' then rebuildCatalogue() end
    return
  end
  if mode=='playing' then
    if red then stopToMenu()
    elseif okkey or key=='PAUSE' or key=='PLAY' or key=='PLAYPAUSE' then
      paused=not paused;signal(paused and 'pausar' or 'continuar');showTimeline();safeDraw()
    elseif key=='CURSOR_RIGHT' or key=='RIGHT' or key=='FASTFORWARD' then seekVideo(10,kind)
    elseif key=='CURSOR_LEFT' or key=='LEFT' or key=='REWIND' then seekVideo(-10,kind)
    elseif key=='CURSOR_DOWN' or key=='DOWN' then nextVideo(1)
    elseif key=='CURSOR_UP' or key=='UP' then nextVideo(-1)
    end
    return
  end
  if mode=='loading' then if red then stopToMenu() end;return end
  if key=='CURSOR_UP' or key=='UP' then moveSelection(-1)
  elseif key=='CURSOR_DOWN' or key=='DOWN' then moveSelection(1)
  elseif key=='CURSOR_RIGHT' or key=='RIGHT' then moveSelection(pageSize)
  elseif key=='CURSOR_LEFT' or key=='LEFT' then moveSelection(-pageSize)
  elseif red then
    if current~=root then scan(parent(current)) end
    if key=='BACK' or key=='BACKSPACE' then queueMenuFocus() end
  elseif key=='GREEN' or key=='F2' then scan(root)
  elseif key=='YELLOW' or key=='F3' then rebuildCatalogue()
  elseif key=='1' and appTheme then mode='about';safeDraw()
  elseif okkey then
    local item=items[selected]
    if item then if item.folder then scan(item.path) else openVideo(item) end end
  end
end
local initialized=false
local function handler(event)
  local ok,err=pcall(function()
    if event.class=='ncl' and event.type=='presentation' and event.action=='start' and not event.label and not initialized then
      initialized=true;initialize()
    elseif event.class=='ncl' and event.type=='presentation' and (event.action=='stop' or event.action=='abort') and (not event.label or event.label=='') then
      pendingToken=pendingToken+1;mode='closed';releaseNative()
    elseif event.class=='key' then
      local direction=seekDirection(event.key)
      if direction and mode=='playing' then
        local kind=tostring(event.type or '')
        if kind=='release' then
          showTimeline()
          seekQueue:release(direction,ev.uptime());armSeekPump();safeDraw()
        elseif kind=='press' or kind=='repeat' then handleKey(event.key,kind) end
      elseif event.type=='press' then handleKey(event.key,event.type) end
    elseif event.class=='ncl' and event.type=='attribution' and (event.name or event.label)=='estado' and event.action=='start' then
      local value=tostring(event.value or '')
      if value=='fim:'..playbackState and mode=='playing' then
        finishVideo()
      elseif value=='tocando:'..playbackState and mode=='loading' then
        mode='playing';beginTimeline();safeDraw()
      end
      ev.post('out',{class='ncl',type='attribution',name='estado',action='stop'})
    end
  end)
  if not ok then fail(err) end
end
ev.register(handler)
-- Some builds report the initial presentation event before the script registers.
ev.timer(200,function()
  if not initialized then initialized=true;local ok,err=pcall(initialize);if not ok then fail(err) end end
end)
