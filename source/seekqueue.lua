-- Lua 5.1. Select a destination on key repeats; commit after input settles.
-- At most one accepted native request is awaiting position confirmation.
local M={}
local Queue={};Queue.__index=Queue

function M.new(options)
  local q=setmetatable({},Queue)
  q.options=options or {}
  q.quiet=q.options.quiet or 650
  q.timeout=q.options.timeout or 5000
  q.cooldown=q.options.cooldown or 250
  q.minStep=q.options.minStep or 120
  q.epoch=0;q:reset()
  return q
end
function Queue:emit(kind,data)
  if self.options.event then self.options.event(kind,data or {}) end
end
function Queue:reset()
  self.epoch=self.epoch+1
  self.real=nil;self.id=nil;self.duration=nil;self.paused=false
  self.target=nil;self.dirty=false;self.flight=nil;self.revision=0
  self.lastInput=-math.huge;self.lastStep=-math.huge;self.lastDirection=nil
  self.readyAt=0;self.settleAt=0;self.halted=false
  self.stats={steps=0,filtered=0,sent=0,confirmed=0,reached=0,timeouts=0,failed=0,cancelled=0,noops=0}
end
function Queue:cancel(reason)
  local active=self.target~=nil or self.flight~=nil
  self.epoch=self.epoch+1
  self.target=nil;self.dirty=false;self.flight=nil;self.halted=false
  self.lastInput=-math.huge;self.lastStep=-math.huge;self.lastDirection=nil
  self.readyAt=0;self.settleAt=0
  if active then self.stats.cancelled=self.stats.cancelled+1;self:emit('cancelled',{reason=reason}) end
end
function Queue:busy() return self.flight~=nil end
function Queue:selection() return self.target end
function Queue:needsPosition(now)
  return not self.flight and self.target==nil and (not self.halted or now-self.lastInput>=self.quiet)
end
function Queue:ready(now)
  return self.target~=nil and self.dirty and not self.flight and
    now>=self.readyAt and now>=self.settleAt
end
function Queue:delay(now)
  if self.flight then return math.max(1,math.min(250,self.flight.deadline-now)) end
  if self.target~=nil and self.dirty then return math.max(1,math.max(self.readyAt,self.settleAt)-now) end
  return nil
end
function Queue:move(delta,now)
  if not self.real or not self.id or not self.duration then return false,'not_ready' end
  local previous=self.lastInput
  self.lastInput=now;self.readyAt=now+self.quiet
  if self.halted then
    if now-previous<self.quiet then self.stats.filtered=self.stats.filtered+1;return false,'halted' end
    self.halted=false
  end
  local direction=delta<0 and -1 or 1
  if direction==self.lastDirection and now-self.lastStep<self.minStep then
    self.stats.filtered=self.stats.filtered+1;return false,'filtered'
  end
  self.lastStep=now;self.lastDirection=direction
  local base=self.target or self.real
  local limit=math.max(0,math.floor(self.duration)-1)
  local target=math.max(0,math.min(limit,math.floor(base+delta)))
  if self.target==nil or target~=self.target then
    self.target=target;self.dirty=true;self.revision=self.revision+1
    self.stats.steps=self.stats.steps+1
    self:emit('selected',{target=target,real=self.real})
  end
  return true
end
function Queue:release(direction,now)
  -- Some receivers produce release for each IR burst. Do not commit on every
  -- release: wait for the quiet window, also supporting press-only remotes.
  if self.target and direction==self.lastDirection then
    self.readyAt=math.max(self.lastInput+self.quiet,now+120)
  end
end
function Queue:observe(position,id,now,paused,duration)
  if type(position)~='number' or position<0 or type(id)~='number' then return end
  if self.id and self.id~=id then self:cancel('media_changed') end
  self.real=position;self.id=id;self.paused=not not paused;self.duration=duration
  local flight=self.flight
  if not flight then return end
  flight.ordinary=flight.ordinary+(flight.paused and 0 or (now-flight.observedAt)/1000)
  flight.observedAt=now;flight.paused=self.paused
  if now>flight.deadline then return end
  local near=math.abs(position-flight.target)<=3
  local jumped=math.abs(position-flight.ordinary)>=4
  local small=math.abs(flight.target-flight.before)<6 and
    math.abs(position-flight.target)<=1 and now>=flight.requestedAt+200
  if (near and jumped) or small then
    self.flight=nil;self.settleAt=now+self.cooldown
    local kind=(near and jumped) and 'confirmed' or 'reached'
    self.stats[kind]=self.stats[kind]+1
    if self.revision==flight.revision then self.target=nil;self.dirty=false end
    self:emit(kind,{target=flight.target,position=position})
  end
end
function Queue:tick(now)
  if self.flight then
    if now>=self.flight.deadline then
      local target=self.flight.target
      self.flight=nil;self.target=nil;self.dirty=false;self.halted=true
      self.stats.timeouts=self.stats.timeouts+1
      self:emit('timeout',{target=target,position=self.real})
    end
    return
  end
  if not self:ready(now) then return end
  if math.abs(self.target-self.real)<1 then
    local target=self.target;self.target=nil;self.dirty=false
    self.stats.noops=self.stats.noops+1;self:emit('noop',{target=target,position=self.real});return
  end
  local target,id,revision,epoch=self.target,self.id,self.revision,self.epoch
  local before=self.real
  local ok,reply,reason=pcall(self.options.send,target,id)
  -- The native call can synchronously end/cancel a presentation.
  if epoch~=self.epoch then return end
  if not ok or reply==nil or not tonumber(reply) or tonumber(reply)<0 then
    self.target=nil;self.dirty=false;self.halted=true
    self.stats.failed=self.stats.failed+1
    self:emit('failed',{target=target,reply=reply,reason=tostring(reason or reply)})
    return
  end
  self.dirty=false
  self.flight={target=target,id=id,revision=revision,before=before,ordinary=before,
    requestedAt=now,observedAt=now,deadline=now+self.timeout,paused=self.paused}
  self.stats.sent=self.stats.sent+1
  self:emit('sent',{target=target,reply=reply})
end
function Queue:summary()
  local s=self.stats
  return 'DESTINO='..tostring(self.target)..' PENDENTE='..tostring(self.flight and self.flight.target)..
    ' PASSOS='..s.steps..' FILTRADOS='..s.filtered..' PEDIDOS='..s.sent..
    ' CONFIRMADOS='..s.confirmed..' ALCANCADOS='..s.reached..
    ' TIMEOUTS='..s.timeouts..' FALHAS='..s.failed..' CANCELADOS='..s.cancelled..' SEM_SALTO='..s.noops
end
return M
