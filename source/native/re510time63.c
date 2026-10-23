/* RE510 V1.11.0: guarded, explicit per-playback data repair.
 * enable() writes only the active SDK object's time gate and duration cache.
 * status() uses native IPC position after enable succeeds; no clock offsets.
 * restore() compares identity before restoring only values still owned here.
 */
typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State *);
typedef struct { const char *name; lua_CFunction func; } luaL_Reg;
extern void luaL_register(lua_State *, const char *, const luaL_Reg *);
extern int luaL_error(lua_State *,const char *,...);
extern void lua_pushnil(lua_State *);
extern void lua_pushstring(lua_State *, const char *);
extern void lua_pushinteger(lua_State *, long);
extern long luaL_checkinteger(lua_State *, int);
extern void lua_createtable(lua_State *, int, int);
extern void lua_setfield(lua_State *, int, const char *);
extern const char *luaL_checklstring(lua_State *,int,unsigned *);
extern int native_control_enable(const char *,int,int);
extern int native_control_active(int);
extern int native_control_restore(void);
extern void native_control_confirmed(int);
extern const char *native_control_note(void);
extern int ipc_time(void *,int) __asm__("_ZN9dynavideo16IpcClientManager14getCurrentTimeEi");
extern int ipc_duration(void *,int) __asm__("_ZN9dynavideo16IpcClientManager11getDurationEi");
extern int pthread_mutex_lock(void *);
extern int pthread_mutex_unlock(void *);

extern void *ncl_instance(void) __asm__("_ZN9dynavideo19NclIpcClientManager11getInstanceEv");
extern void ncl_add(void *,void *) __asm__("_ZN9dynavideo19NclIpcClientManager19addIpcMediaListenerEP16IpcMediaListener");
extern double av_duration(void *) __asm__("_ZN2br6pucrio9telemidia5ginga4core6player8AVPlayer17getTotalMediaTimeEv");
extern void av_open(void *) __asm__("_ZN2br6pucrio9telemidia5ginga4core6player8AVPlayer4openEv");
extern char av_rtti[] __asm__("_ZTIN2br6pucrio9telemidia5ginga4core6player8AVPlayerE");
extern int ipc_seek(void *,int,int,int) __asm__("_ZN9dynavideo16IpcClientManager14setCurrentTimeEiii");
extern double player_time(void *) __asm__("_ZN2br6pucrio9telemidia5ginga4core6player6Player12getMediaTimeEv");

static int error(lua_State *L,const char *s) {
    lua_pushnil(L); lua_pushstring(L,s); return 2;
}
static int compatible(void) {
    const unsigned *a=(const unsigned *)(void *)av_duration;
    const unsigned *n=(const unsigned *)(void *)ncl_add;
    const unsigned *o=(const unsigned *)(void *)av_open;
    const unsigned *t=(const unsigned *)(void *)player_time;
    /* IDs, list begin/end, mutex, listener offset and the base clock fields
     * (status +0xc8, start +0xd8, offset +0xe0) must match exactly. */
    return a[0x30/4]==0x8c85015c && n[0x24/4]==0x24910030 &&
           n[0x38/4]==0x8e050020 && n[0x3c/4]==0x8e020024 &&
           o[0x7e4/4]==0x26450128 && t[0x20/4]==0x848300c8 &&
           t[0x38/4]==0xd49400e0 && t[0x44/4]==0xd60000d8;
}
typedef struct { void *player; void *client; int id; } Active;
static int active(Active *out) {
    char *n=(char *)ncl_instance();
    void **begin,**end,**it; int count=0;
    if (!n) return 0;
    pthread_mutex_lock(n+0x30);
    begin=*(void ***)(n+0x1c); end=*(void ***)(n+0x20);
    if ((unsigned)end>=(unsigned)begin &&
        ((unsigned)end-(unsigned)begin)<=4*1024) {
        for (it=begin;it!=end;++it) {
            char *listener=(char *)*it; void **vt; char *p; int id;
            if (!listener) continue;
            vt=*(void ***)listener;
            if (!vt || (int)vt[-2]!=-0x128 || vt[-1]!=(void *)av_rtti) continue;
            p=listener-0x128; id=*(int *)(p+0x15c);
            if (id<0 || !*(void **)(p+0x158)) continue;
            out->player=p; out->client=*(void **)(p+0x158); out->id=id;
            ++count;
        }
    }
    pthread_mutex_unlock(n+0x30);
    return count;
}
static void field(lua_State *L,const char *name,long value) {
    lua_pushinteger(L,value);lua_setfield(L,-2,name);
}
static int status(lua_State *L) {
    Active a; long clock;
    if (!compatible()) return error(L,"Modulo de tempo incompativel com este firmware");
    if (active(&a)!=1) return error(L,"Aguardando um unico video ativo");
    /* Integer milliseconds: avoids depending on the firmware's lua_Number.
     * Validate after truncating: the firmware itself never uses FP compares or
     * mthc1, so keep to the FPU instructions it does use (mul.d, trunc.w.d).
     * NaN and overflow truncate to 0x7fffffff, which the range check rejects. */
    clock=(long)(player_time(a.player)*1000.0);
    if (clock<0 || clock>=86400000L) return error(L,"Relogio do Ginga ainda nao iniciou");
    lua_createtable(L,0,2);
    field(L,"id",a.id); field(L,"clock",clock);
    if(native_control_active(a.id)) {
        int position=ipc_time(a.client,a.id);
        if(position<0 || position>=86400)return error(L,"Consulta nativa da posicao falhou");
        field(L,"native",1);field(L,"position",position);
        field(L,"serviceDuration",ipc_duration(a.client,a.id));
    } else field(L,"native",0);
    return 1;
}
static int seek(lua_State *L) {
    int target=(int)luaL_checkinteger(L,1);
    int expected=(int)luaL_checkinteger(L,2);
    Active a;
    if (!compatible()) return error(L,"Modulo de tempo incompativel com este firmware");
    if (active(&a)!=1 || a.id!=expected) return error(L,"O video ativo mudou; tente novamente");
    if (!native_control_active(a.id)) return error(L,"Pressione 9 durante o video para habilitar o controle nativo");
    if (target<0) return error(L,"Posicao fora do video");
    /* Third IPC argument is unused by this firmware's playback manager. */
    lua_pushinteger(L,ipc_seek(a.client,a.id,target,0));
    return 1;
}
static int enable(lua_State *L) {
    unsigned len=0;const char *path=luaL_checklstring(L,1,&len);
    int duration=(int)luaL_checkinteger(L,2),expected=(int)luaL_checkinteger(L,3);
    Active a,after;int position;
    if(!compatible())return error(L,"Modulo incompativel com este firmware");
    if(active(&a)!=1 || a.id!=expected)return error(L,"O video ativo mudou; tente novamente");
    if(!len || len>=512)return error(L,"Caminho do video invalido");
    if(!native_control_enable(path,a.id,duration))return error(L,native_control_note());
    position=ipc_time(a.client,a.id);
    if(position<0 || position>duration+5 || active(&after)!=1 || after.id!=a.id || after.player!=a.player || !native_control_active(a.id)) {
        native_control_restore();return error(L,"Consulta nativa nao confirmou; controle cancelado");
    }
    native_control_confirmed(position);
    lua_createtable(L,0,3);field(L,"id",a.id);field(L,"position",position);field(L,"native",1);
    return 1;
}
static int restore(lua_State *L) {lua_pushinteger(L,native_control_restore());return 1;}
extern const char *re510_native_report(int);
static int diagnostic(lua_State *L) {
    Active a;
    if (!compatible()) return error(L,"Modulo de tempo incompativel com este firmware");
    if (active(&a)!=1) return error(L,"Aguardando um unico video ativo");
    lua_pushstring(L,re510_native_report(a.id));return 1;
}
static const luaL_Reg methods[]={{"status",status},{"seek",seek},{"diagnostic",diagnostic},{"enable",enable},{"restore",restore},{0,0}};
int luaopen_re510time63(lua_State *L) {
    if (!compatible()) return luaL_error(L,"Modulo de tempo incompativel com este firmware");
    luaL_register(L,"re510time63",methods);return 1;
}
