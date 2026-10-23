-- Lua 5.1. Reads MP4 metadata only; never reads the mdat payload into memory.
-- The RE510 secure.lua interprets absolute /usb paths relative to the app when
-- usbmonitor returns the equivalent /Customer/usb name. extMem selects the disk.
local M={}
local function u32(s,p)
  local a,b,c,d=s:byte(p,p+3)
  if not d then return nil end
  return ((a*256+b)*256+c)*256+d
end
local function u64(s,p)
  local hi,lo=u32(s,p),u32(s,p+4)
  if not hi or not lo or hi>2097151 then return nil end
  return hi*4294967296+lo
end
function M.usbURI(path,root)
  path=tostring(path or '');root=tostring(root or ''):gsub('/+$','')
  if root~='' and path:sub(1,#root+1)==root..'/' then
    return 'file:///extMem/'..path:sub(#root+2)
  end
  return path
end
function M.duration(path,root)
  local uri=M.usbURI(path,root)
  local f,reason=io.open(uri,'rb')
  if not f then return nil,'Leitura MP4: '..tostring(reason or 'arquivo indisponivel') end
  local function parse()
    local size,e=f:seek('end')
    if not size then return nil,'Nao foi possivel medir o MP4: '..tostring(e) end
    local boxes=0
    local function find(kind,first,last)
      local pos=first
      while pos+8<=last do
        boxes=boxes+1;if boxes>16384 then return nil,'Limite de caixas MP4 atingido' end
        if f:seek('set',pos)~=pos then return nil,'Falha ao posicionar leitura do MP4' end
        local b=f:read(8);if not b or #b~=8 then return nil,'Cabecalho MP4 incompleto' end
        local length,head=u32(b,1),8
        if length==1 then
          local large=f:read(8)
          if not large or #large~=8 then return nil,'Tamanho MP4 incompleto' end
          length,head=u64(large,1),16
        elseif length==0 then length=last-pos end
        if not length or length<head or length>last-pos then return nil,'Caixa MP4 invalida: '..b:sub(5,8) end
        if b:sub(5,8)==kind then return pos+head,pos+length end
        pos=pos+length
      end
      return nil,'Caixa '..kind..' nao encontrada'
    end
    local moov,last=find('moov',0,size)
    if not moov then return nil,last end
    local mvhd,finish=find('mvhd',moov,last)
    if not mvhd then return nil,finish end
    if f:seek('set',mvhd)~=mvhd then return nil,'Falha ao ler mvhd' end
    local b=f:read(math.min(32,finish-mvhd))
    if not b or #b<20 then return nil,'mvhd incompleto' end
    local scale,length,version=u32(b,13),u32(b,17),b:byte(1)
    if version==1 then
      if #b<32 then return nil,'mvhd versao 1 incompleto' end
      scale,length=u32(b,21),u64(b,25)
    elseif version~=0 then return nil,'Versao mvhd desconhecida: '..tostring(version) end
    if not scale or scale<=0 then return nil,'Escala de tempo MP4 invalida' end
    if not length or length==0 or (version==0 and length==4294967295) then
      return nil,'MP4 sem duracao final no mvhd'
    end
    local seconds=length/scale
    if seconds<=0 or seconds~=seconds or seconds==math.huge then return nil,'Duracao MP4 invalida' end
    return seconds,'mvhd v'..version..' | escala='..scale..' | arquivo='..size..' bytes'
  end
  local ok,value,detail=pcall(parse)
  f:close()
  if not ok then return nil,'Falha ao ler MP4: '..tostring(value) end
  return value,detail
end
return M
