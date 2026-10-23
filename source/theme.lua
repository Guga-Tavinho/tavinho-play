-- Tavinho Play visual theme. Social outline icons: Feather / MIT.
local M={}
local icons={
 ["github"]={{6,0,4,1},{24,0,3,1},{5,1,6,1},{14,1,5,1},{22,1,6,1},{5,2,23,1},{10,3,14,1},{26,3,3,2},{12,4,2,1},{20,4,2,1},{26,5,2,1},{5,3,3,4},{26,6,3,2},{4,7,4,1},{26,8,4,1},{4,8,3,2},{3,10,3,4},{27,9,3,7},{4,14,3,3},{26,16,3,1},{5,17,3,1},{25,17,4,1},{5,18,4,1},{24,18,4,1},{6,19,7,1},{20,19,7,1},{1,20,3,1},{8,20,6,1},{19,20,7,1},{1,21,4,1},{10,21,4,1},{19,21,5,1},{2,22,4,1},{11,22,3,2},{3,23,4,1},{4,24,10,1},{5,25,9,1},{7,26,7,1},{11,27,3,2},{20,22,3,8},{10,29,3,1},{11,30,2,1},{20,30,2,1}},
 ["instagram"]={{6,3,20,1},{5,4,22,1},{4,5,24,1},{3,6,4,1},{25,6,4,1},{22,7,2,1},{26,7,3,1},{27,8,2,1},{22,8,3,2},{15,9,2,1},{12,10,8,1},{11,11,10,1},{10,12,5,1},{18,12,4,1},{19,13,3,1},{10,13,3,2},{9,15,3,2},{20,14,3,4},{10,17,2,1},{10,18,3,1},{19,18,3,1},{10,19,4,1},{18,19,4,1},{11,20,10,1},{12,21,8,1},{15,22,3,1},{27,9,3,15},{3,7,3,18},{26,24,3,2},{3,25,4,1},{4,26,4,1},{24,26,4,1},{5,27,22,1},{6,28,20,1},{9,29,15,1}},
 ["youtube"]={{5,4,22,1},{3,5,27,1},{2,6,29,1},{1,7,4,1},{28,7,3,1},{1,8,3,1},{28,8,4,1},{12,10,2,1},{12,11,4,1},{12,12,6,1},{12,13,7,1},{16,14,5,1},{18,15,4,1},{17,16,5,1},{12,14,3,4},{16,17,4,1},{12,18,7,1},{12,19,5,1},{12,20,3,1},{0,9,3,14},{29,9,3,14},{1,23,3,1},{28,23,3,1},{1,24,10,1},{21,24,10,1},{2,25,28,1},{3,26,26,1},{12,27,8,1}},
 ["folder"]={{3,3,10,1},{2,4,12,1},{2,5,13,1},{12,6,4,1},{13,7,16,1},{13,8,17,1},{15,9,16,1},{1,6,3,20},{28,10,3,16},{2,26,3,1},{27,26,4,1},{2,27,28,1},{3,28,27,1},{5,29,22,1}},
 ["chevron-left"]={{19,7,2,1},{18,8,3,1},{17,9,4,1},{16,10,4,1},{15,11,4,1},{14,12,4,1},{13,13,4,1},{12,14,4,1},{11,15,4,2},{11,17,5,1},{12,18,5,1},{13,19,5,1},{14,20,5,1},{15,21,5,1},{16,22,5,1},{17,23,4,1},{18,24,3,1}},
 ["play"]={{11,6,1,1},{11,7,3,1},{11,8,4,1},{11,9,6,1},{11,10,7,1},{11,11,9,1},{11,12,11,1},{11,13,12,1},{11,14,14,1},{11,15,15,1},{11,16,17,1},{11,17,15,1},{11,18,14,1},{11,19,12,1},{11,20,11,1},{11,21,9,1},{11,22,7,1},{11,23,6,1},{11,24,4,1},{11,25,3,1},{11,26,1,1}},
 ["pause"]={{9,6,5,21},{20,6,5,21}},
}
local widths={
[" "]=0.294,["!"]=0.303,["\""]=0.405,["#"]=0.829,["$"]=0.587,["%"]=0.736,["&"]=0.653,["'"]=0.25,["("]=0.402,[")"]=0.402,["*"]=0.353,["+"]=0.7,[","]=0.26,["-"]=0.371,["."]=0.264,["/"]=0.362,["0"]=0.587,["1"]=0.587,["2"]=0.587,["3"]=0.587,["4"]=0.587,["5"]=0.587,["6"]=0.587,["7"]=0.587,["8"]=0.587,["9"]=0.587,[":"]=0.264,[";"]=0.26,["<"]=0.7,["="]=0.7,[">"]=0.7,["?"]=0.453,["@"]=0.812,["A"]=0.583,["B"]=0.584,["C"]=0.498,["D"]=0.605,["E"]=0.502,["F"]=0.48,["G"]=0.588,["H"]=0.626,["I"]=0.287,["J"]=0.287,["K"]=0.552,["L"]=0.449,["M"]=0.794,["N"]=0.664,["O"]=0.648,["P"]=0.555,["Q"]=0.648,["R"]=0.575,["S"]=0.532,["T"]=0.491,["U"]=0.622,["V"]=0.583,["W"]=0.808,["X"]=0.55,["Y"]=0.538,["Z"]=0.493,["["]=0.404,["\\"]=0.358,["]"]=0.404,["^"]=0.6,["_"]=0.435,["`"]=0.5,["a"]=0.488,["b"]=0.528,["c"]=0.421,["d"]=0.528,["e"]=0.505,["f"]=0.325,["g"]=0.528,["h"]=0.532,["i"]=0.256,["j"]=0.256,["k"]=0.484,["l"]=0.278,["m"]=0.817,["n"]=0.532,["o"]=0.504,["p"]=0.528,["q"]=0.528,["r"]=0.346,["s"]=0.448,["t"]=0.344,["u"]=0.532,["v"]=0.463,["w"]=0.666,["x"]=0.48,["y"]=0.463,["z"]=0.422,["{"]=0.333,["|"]=0.228,["}"]=0.333,["~"]=0.7,["¡"]=0.303,["¢"]=0.587,["£"]=0.587,["¤"]=0.6,["¥"]=0.587,["¦"]=0.6,["§"]=0.6,["¨"]=0.5,["©"]=0.8,["ª"]=0.378,["«"]=0.463,["¬"]=0.7,["®"]=0.8,["¯"]=0.6,["°"]=0.406,["±"]=0.6,["²"]=0.6,["³"]=0.6,["´"]=0.5,["µ"]=0.6,["¶"]=0.641,["·"]=0.264,["¸"]=0.5,["¹"]=0.6,["º"]=0.383,["»"]=0.463,["¼"]=0.9,["½"]=0.9,["¾"]=0.9,["¿"]=0.453,["À"]=0.583,["Á"]=0.583,["Â"]=0.583,["Ã"]=0.583,["Ä"]=0.583,["Å"]=0.583,["Æ"]=0.837,["Ç"]=0.498,["È"]=0.502,["É"]=0.502,["Ê"]=0.502,["Ë"]=0.502,["Ì"]=0.287,["Í"]=0.287,["Î"]=0.287,["Ï"]=0.287,["Ð"]=0.605,["Ñ"]=0.664,["Ò"]=0.648,["Ó"]=0.648,["Ô"]=0.648,["Õ"]=0.648,["Ö"]=0.648,["×"]=0.587,["Ø"]=0.648,["Ù"]=0.622,["Ú"]=0.622,["Û"]=0.622,["Ü"]=0.622,["Ý"]=0.538,["Þ"]=0.555,["ß"]=0.585,["à"]=0.488,["á"]=0.488,["â"]=0.488,["ã"]=0.488,["ä"]=0.488,["å"]=0.488,["æ"]=0.773,["ç"]=0.421,["è"]=0.505,["é"]=0.505,["ê"]=0.505,["ë"]=0.505,["ì"]=0.256,["í"]=0.256,["î"]=0.256,["ï"]=0.256,["ð"]=0.587,["ñ"]=0.532,["ò"]=0.504,["ó"]=0.504,["ô"]=0.504,["õ"]=0.504,["ö"]=0.504,["÷"]=0.587,["ø"]=0.504,["ù"]=0.532,["ú"]=0.532,["û"]=0.532,["ü"]=0.532,["ý"]=0.463,["þ"]=0.528,["ÿ"]=0.463
}

-- Larger screenfont lettering and short lines for the receiver's TV output.
local P={bg={9,14,23},header={12,20,32},panel={12,20,32},card={17,28,43},line={48,65,82},
 white={255,255,255},body={245,248,252},muted={226,234,242},mint={70,225,190},
 selected={19,58,58},amber={255,215,140},red={244,100,109},green={94,209,149},
 pink={244,127,184},youtube={255,105,111}}
local social={
 {name='GitHub',icon='github',host='github.com/',handle='Guga-Tavinho',display='github.com/Guga-Tavinho',url='https://github.com/Guga-Tavinho',color=P.white},
 {name='Instagram',icon='instagram',host='instagram.com/',handle='tavinho.games',display='instagram.com/tavinho.games',url='https://www.instagram.com/tavinho.games',color=P.pink},
 {name='YouTube',icon='youtube',host='youtube.com/',handle='@tavinho-games',display='youtube.com/@tavinho-games',url='https://www.youtube.com/@tavinho-games',color=P.youtube}
}
M.social=social
local function measure(s,size)
 local total=0
 for char in tostring(s):gmatch('[%z\1-\127\194-\244][\128-\191]*') do total=total+(widths[char] or 0.8) end
 return total*size*1.04
end
local function fit(s,width,size)
 s=tostring(s or '')
 if measure(s,size)<=width then return s end
 local tail='...';local available=width-measure(tail,size);local used,out=0,{}
 for char in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
  local advance=measure(char,size)
  if used+advance>available then break end
  out[#out+1]=char;used=used+advance
 end
 return table.concat(out)..tail
end
function M.new(rect,text,clip)
 local ui={}
 local function fill(x,y,w,h,c,a)rect(x,y,w,h,c[1],c[2],c[3],a)end
 local function box(x,y,w,h,c,a)
  local cut=math.min(4,math.floor(math.min(w,h)/3))
  if cut<1 then fill(x,y,w,h,c,a);return end
  fill(x+cut,y,w-2*cut,h,c,a);fill(x,y+cut,w,h-2*cut,c,a)
  fill(x+1,y+1,w-2,h-2,c,a)
 end
 local function label(x,y,s,size,c,width)
  text(x,y,width and fit(s,width,size) or s,size,c[1],c[2],c[3])
 end
 local function icon(name,x,y,size,c)
  for _,r in ipairs(icons[name] or icons.play) do fill(x+r[1]*size/32,y+r[2]*size/32,r[3]*size/32,r[4]*size/32,c) end
 end
 local function wrapped(x,y,s,size,width,c,maxLines)
  local line,count='',0
  for word in tostring(s):gmatch('%S+') do
   local nextLine=line=='' and word or line..' '..word
   if line~='' and measure(nextLine,size)>width then
    label(x,y+count*(size+10),line,size,c,width);count=count+1;line=word
    if count>=(maxLines or 7) then return end
   else line=nextLine end
  end
  if line~='' then label(x,y+count*(size+10),line,size,c,width) end
 end
 local function header(s)
  fill(0,0,1280,124,P.header);fill(36,122,1208,2,P.line)
  box(46,24,70,70,P.mint);icon('play',61,39,39,P.bg)
  label(138,24,'TAVINHO',48,P.white)
  label(353,24,'PLAY',48,P.mint)
  label(140,81,'PLAYER USB',28,P.white)
  label(860,37,'TAVINHO GAMES',32,P.white)
  label(860,81,'Resolução: '..(s.profileName or 'Padrao'),28,P.body)
 end
 local function networks()
  box(832,150,412,478,P.panel)
  label(858,169,'CRÉDITOS',32,P.white)
  for i,site in ipairs(social) do
   local y=219+(i-1)*130
   box(850,y,376,116,P.card)
   icon(site.icon,866,y+10,34,site.color)
   label(922,y+9,site.name,32,P.white)
   label(870,y+49,site.host,28,P.body,334)
   label(870,y+82,site.handle,32,P.white,334)
  end
 end
 local function footer(message)
  fill(36,641,1208,2,P.line)
  label(48,650,message,28,P.body,650)
  label(765,650,'1 Créditos',28,P.white)
  fill(963,660,14,14,{110,177,255});label(993,650,'AZUL Resolução',28,P.white)
  box(48,688,45,30,P.line);label(56,689,'OK',26,P.white)
  label(106,688,'abrir',28,P.white)
  fill(236,697,14,14,P.red);label(265,688,'VERMELHO voltar',28,P.white)
  fill(522,697,14,14,P.green);label(552,688,'VERDE raiz',28,P.white)
  fill(761,697,14,14,P.amber);label(791,688,'AMARELO atualizar',28,P.white)
 end
 local function standardMenu(s)
  header(s);networks()
  box(36,150,770,478,P.panel)
  label(60,169,'Sua biblioteca',34,P.white)
  icon('folder',60,211,28,P.mint)
  label(106,210,s.path,28,P.body,668)
  if s.mode=='restart' then
   box(56,253,730,313,P.card);fill(58,278,4,39,P.mint)
   label(83,279,s.restartTitle,34,P.white,672)
   wrapped(83,344,'Feche este aplicativo e abra Tavinho Play novamente.',30,665,P.white,3)
   wrapped(83,454,'A nova lista e os ajustes ficam disponiveis ao reabrir o player.',28,665,P.body,3)
  elseif s.mode=='error' then
   label(60,266,s.failureTitle,34,P.amber,715)
   wrapped(60,328,s.failure,28,715,P.white,7)
  elseif s.mode=='loading' then
   icon('play',60,278,43,P.mint)
   label(131,279,'Abrindo video...',34,P.white)
   wrapped(60,365,s.message,30,710,P.body,3)
   wrapped(60,522,'VERMELHO cancela e volta para a lista.',28,710,P.white,2)
  elseif #s.items==0 then
   icon('folder',60,277,58,P.mint)
   label(60,366,'Nenhum video MP4 nesta pasta.',32,P.white,710)
   wrapped(60,425,'Coloque seus videos na pasta Videos do pendrive.',30,710,P.white,3)
   wrapped(60,540,'AMARELO atualiza a lista. VERDE abre a raiz.',28,710,P.body,2)
  else
   local first=math.floor((s.selected-1)/s.pageSize)*s.pageSize+1
   for row=0,s.pageSize-1 do
    local index=first+row;local item=s.items[index]
    if item then
     local y=257+row*55;local chosen=index==s.selected
     if chosen then box(52,y-3,738,51,P.selected);fill(52,y+6,4,33,P.mint)
     else fill(65,y+49,707,1,{28,42,58}) end
     icon(item.parent and 'chevron-left' or item.folder and 'folder' or 'play',66,y+8,30,P.mint)
     label(116,y+5,item.name,34,P.white,652)
    end
   end
   label(61,592,string.format('%02d',s.selected)..' / '..tostring(#s.items),28,P.white)
   label(280,592,'ESQ / DIR: paginas',28,P.body)
  end
  footer(s.message)
 end
 local function standardTimeline(s)
  box(36,512,1208,192,{9,17,28},250)
  icon(s.paused and 'pause' or 'play',62,532,32,P.mint)
  label(116,529,s.filename,32,P.white,824)
  label(972,531,s.paused and 'PAUSADO' or 'REPRODUZINDO',28,P.white,246)
  label(62,577,s.clock..' / '..s.total,38,P.white)
  if s.destination then label(690,584,(s.waiting and 'BUSCANDO ' or 'IR PARA ')..s.destination,30,P.amber,528) end
  fill(62,631,1156,10,P.line)
  if s.position and s.duration and s.duration>0 then
   local amount=math.floor(1156*math.max(0,math.min(1,s.position/s.duration)))
   if amount>0 then fill(62,631,amount,10,P.mint) end
  end
  if s.target and s.duration and s.duration>0 then
   local x=62+1156*math.max(0,math.min(1,s.target/s.duration))
   box(math.max(62,math.min(1210,x-4)),625,8,23,P.amber)
  end
  label(62,659,s.notice,28,P.white,1156)
 end

 -- Full-width list layouts leave room for physically larger lettering.
 local function largeHeader(s,title)
  fill(0,0,1280,137,P.header);fill(36,135,1208,2,P.line)
  box(46,25,76,76,P.mint);icon('play',62,40,44,P.bg)
  label(148,26,title or 'TAVINHO PLAY',62,P.white,1080)
  label(150,101,'PLAYER USB',32,P.body)
  if not title then
   if s.profile=='grande' or s.profile=='crt5' then
    for i,site in ipairs(social) do
     local y=12+(i-1)*40
     icon(site.icon,700,y+1,32,site.color)
     label(751,y,site.display,34,P.white,475)
    end
   else label(700,98,'Resolução: '..s.profileName,36,P.white,520) end
  end
 end
 local function largeFooter(s)
  local size=s.profile=='crt5' and 42 or 36
  fill(36,598,1208,2,P.line)
  label(52,610,s.message,size,P.body,665)
  fill(775,623,16,16,{110,177,255})
  label(812,610,'AZUL: Resolução',size,P.white,410)
  label(52,670,'OK Abrir',size,P.white)
  fill(268,683,16,16,P.red);label(300,670,'Voltar',size,P.white)
  fill(470,683,16,16,P.green);label(502,670,'Raiz',size,P.white)
  fill(645,683,16,16,P.amber);label(677,670,'Atualizar',size,P.white)
  label(1005,670,'1 Créditos',size,P.white,215)
 end
 local function largeMenu(s)
  largeHeader(s)
  local tiny=s.profile=='crt5'
  local fileSize=tiny and 60 or 46
  local infoSize=tiny and 44 or 38
  box(36,154,1208,432,P.panel)
  icon('folder',60,173,36,P.mint)
  label(118,170,s.path,infoSize,P.white,1090)
  if s.mode=='restart' then
   label(63,263,s.restartTitle,52,P.white,1140)
   wrapped(63,344,'Feche e abra Tavinho Play novamente.',infoSize,1130,P.white,3)
   wrapped(63,474,'A lista e os ajustes ficam prontos ao reabrir.',infoSize,1130,P.body,2)
  elseif s.mode=='error' then
   label(63,248,s.failureTitle,48,P.amber,1130)
   wrapped(63,324,s.failure,infoSize,1130,P.white,4)
  elseif s.mode=='loading' then
   label(63,250,'Abrindo video...',52,P.white,1130)
   wrapped(63,339,s.message,infoSize,1130,P.white,2)
   label(63,508,'VERMELHO: cancelar',infoSize,P.body,1130)
  elseif #s.items==0 then
   label(63,263,'Nenhum video MP4 nesta pasta.',48,P.white,1130)
   wrapped(63,350,'Coloque os arquivos na pasta Videos do pendrive.',infoSize,1130,P.white,2)
   label(63,515,'AMARELO: atualizar',infoSize,P.body,1130)
  else
   local first=math.floor((s.selected-1)/s.pageSize)*s.pageSize+1
   local step=tiny and 96 or 78
   for row=0,s.pageSize-1 do
    local index=first+row;local item=s.items[index]
    if item then
     local y=(tiny and 235 or 223)+row*step
     if index==s.selected then
      box(52,y-2,1176,step-8,P.selected);fill(52,y+8,5,step-29,P.mint)
     else fill(66,y+step-7,1146,1,P.line) end
     icon(item.parent and 'chevron-left' or item.folder and 'folder' or 'play',69,y+15,tiny and 42 or 36,P.mint)
     label(139,y+10,item.name,fileSize,P.white,1061)
    end
   end
   label(62,548,string.format('%02d',s.selected)..' / '..tostring(#s.items),infoSize,P.white)
   label(535,548,'ESQ / DIR: paginas',tiny and 40 or 36,P.body,675)
  end
  largeFooter(s)
 end
 local function networksPage(s)
  largeHeader(s,'Créditos')
  local size=s.profile=='crt5' and 56 or s.profile=='grande' and 50 or 44
  for i,site in ipairs(social) do
   local y=160+(i-1)*138
   box(36,y,1208,122,P.panel)
   icon(site.icon,63,y+25,53,site.color)
   label(149,y+10,site.name,size,P.white,1055)
   label(149,y+65,site.display,size,P.white,1055)
  end
  fill(36,597,1208,2,P.line)
  label(54,619,'Resolução: '..s.profileName,40,P.white,1150)
  fill(54,685,16,16,P.red);label(89,671,'VOLTAR / OK: lista',40,P.white,660)
  fill(802,685,16,16,{110,177,255});label(835,671,'AZUL: Resolução',40,P.white,380)
 end
 local function largeTimeline(s)
  local tiny=s.profile=='crt5'
  box(36,440,1208,264,{9,17,28},250)
  icon(s.paused and 'pause' or 'play',62,462,38,P.mint)
  label(126,460,(s.paused and 'PAUSADO: ' or '')..s.filename,tiny and 50 or 44,P.white,1085)
  label(62,519,s.clock..' / '..s.total,tiny and 70 or 58,P.white,1156)
  if s.destination then
   label(62,592,(s.waiting and 'BUSCANDO ' or 'IR PARA ')..s.destination,tiny and 46 or 42,P.amber,1156)
  elseif s.paused then label(62,592,'OK: continuar',tiny and 46 or 42,P.body,1156) end
  fill(62,647,1156,12,P.line)
  if s.position and s.duration and s.duration>0 then
   local amount=math.floor(1156*math.max(0,math.min(1,s.position/s.duration)))
   if amount>0 then fill(62,647,amount,12,P.mint) end
  end
  if s.target and s.duration and s.duration>0 then
   local x=62+1156*math.max(0,math.min(1,s.target/s.duration))
   box(math.max(62,math.min(1208,x-5)),639,10,28,P.amber)
  end
  local notice=s.notice
  if notice=='Segure ESQ / DIR para escolher. Solte para ir. OK: pausar' then notice='ESQ / DIR: buscar    OK: pausar' end
  label(62,671,notice,tiny and 40 or 36,P.white,1156)
 end
 function ui.menu(s)
  if s.mode=='about' then networksPage(s)
  elseif s.profile and s.profile~='padrao' then largeMenu(s)
  else standardMenu(s) end
 end
 function ui.timeline(s)
  if s.profile and s.profile~='padrao' then largeTimeline(s) else standardTimeline(s) end
 end
 return ui
end
return M
