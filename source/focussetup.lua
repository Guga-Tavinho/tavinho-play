-- Install static NCL focus links while preserving the existing media catalogue.
local M={}
local MARK='<!--RE510_FOCUS_V0610-->'
local AREA='usbRetomarControle'
local CONNECTOR='c_usbFocus0610'
local ids={AREA,CONNECTOR,'l_usbFocus0610','l_usbKeyMaster0610'}
local connector=[[  <!--RE510_FOCUS_V0610-->
  <causalConnector id="c_usbFocus0610">
   <connectorParam name="valor" />
   <simpleCondition role="onBegin" />
   <simpleAction role="set" value="$valor" />
  </causalConnector>
]]
local links=[[  <link id="l_usbFocus0610" xconnector="c_usbFocus0610">
   <linkParam name="valor" value="1" />
   <bind role="onBegin" component="controller" interface="usbRetomarControle" />
   <bind role="set" component="configuracoes" interface="service.currentFocus" />
  </link>
  <link id="l_usbKeyMaster0610" xconnector="c_usbFocus0610">
   <linkParam name="valor" value="1" />
   <bind role="onBegin" component="controller" interface="usbRetomarControle" />
   <bind role="set" component="configuracoes" interface="service.currentKeyMaster" />
  </link>
]]
local function idCount(xml,id)
  local _,n=xml:gsub('%sid%s*=%s*["\']'..id..'["\']','')
  return n
end
function M.patch(xml)
  assert(type(xml)=='string','Nao foi possivel ler o documento do player.')
  if xml:find(MARK,1,true) then
    for _,id in ipairs(ids) do assert(idCount(xml,id)==1,'Atualizacao do controle incompleta. Recoloque a copia anterior do documento.') end
    return xml,false
  end
  for _,id in ipairs(ids) do assert(idCount(xml,id)==0,'O documento ja usa um identificador reservado para o controle.') end
  assert(idCount(xml,'controller')==1 and idCount(xml,'configuracoes')==1,'Documento do player diferente do esperado.')
  assert(xml:find('service.currentFocus',1,true) and xml:find('service.currentKeyMaster',1,true),'Configuracao do controle ausente.')
  local count
  xml,count=xml:gsub('(<media%s+[^>]-id%s*=%s*["\']controller["\'][^>]*>)(.-)(</media%s*>)',function(open,body,close)
    return open..body..'   <area id="usbRetomarControle" label="usbRetomarControle" />\n  '..close
  end)
  assert(count==1,'Nao foi possivel atualizar o controle do menu.')
  xml,count=xml:gsub('</connectorBase%s*>',function()return connector..' </connectorBase>'end)
  assert(count==1,'Base de conectores diferente do esperado.')
  xml,count=xml:gsub('</body%s*>',function()return links..' </body>'end)
  assert(count==1,'Corpo do documento diferente do esperado.')
  return xml,true
end
function M.install(read,write)
  local names={'modelo_v05.ncl','main_v05.ncl'}
  local old,new,changed={},{},false
  for i,name in ipairs(names) do
    old[i]=read(name)
    local modified
    new[i],modified=M.patch(old[i]);changed=changed or modified
  end
  if not changed then return false end
  -- Back up and verify both staged documents before replacing either source.
  for i,name in ipairs(names) do
    local backup=name:gsub('%.ncl$','_antes_foco0610.ncl')
    local exists=pcall(read,backup)
    if not exists then write(backup,old[i]);assert(read(backup)==old[i],'Falha ao guardar a copia anterior do documento.') end
    local staged=name:gsub('%.ncl$','_foco0610_preparado.ncl')
    write(staged,new[i]);assert(read(staged)==new[i],'Falha ao verificar a atualizacao do controle.')
  end
  local ok=pcall(function()
    for i,name in ipairs(names) do write(name,new[i]);assert(read(name)==new[i]) end
  end)
  if not ok then
    local restored=true
    for i,name in ipairs(names) do
      local r=pcall(function()write(name,old[i]);assert(read(name)==old[i])end)
      restored=restored and r
    end
    if not restored then error('Falha na gravacao. Recoloque as copias *_antes_foco0610.ncl no lugar dos documentos originais.') end
    error('Nao foi possivel instalar o controle. Os documentos anteriores foram restaurados.')
  end
  return true
end
return M
