-- Plain-text display preference in the app's writable source directory.
local M={file='tela.cfg',profiles={
 {id='padrao',name='Padrao',rows=6},
 {id='grande',name='Letras grandes',rows=4},
 {id='crt5',name='CRT 5"',rows=3}
}}
function M.parse(data)
 local id=type(data)=='string' and data:match('^%s*([%w]+)%s*$')
 for i,p in ipairs(M.profiles) do if p.id==id then return i end end
 return 1
end
function M.load(read)
 local ok,data=pcall(read,M.file)
 return ok and M.parse(data) or 1
end
function M.save(write,read,index)
 local profile=M.profiles[index]
 if not profile then return false end
 local data=profile.id..'\n'
 return pcall(function()
  write(M.file,data)
  if read(M.file)~=data then error('Preferencia nao confirmada') end
 end)
end
return M
