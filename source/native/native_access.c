/* Snapshot plus explicit per-playback data repair, RE510 V1.11.0.
 * The report path only reads. Native control is in native_control.inc and
 * requires a separate explicit enable call; it never modifies instructions.
 */
#include <stdarg.h>
#include "native_layout.h"
extern void *fopen(const char *,const char *);
extern int fclose(void *);
extern char *fgets(char *,int,void *);
extern unsigned fread(void *,unsigned,unsigned,void *);
extern int fseeko64(void *,long long,int);
extern int sscanf(const char *,const char *,...);
extern int vsnprintf(char *,unsigned,const char *,va_list);
extern int snprintf(char *,unsigned,const char *,...);
extern int strcmp(const char *,const char *);
extern int strncmp(const char *,const char *,unsigned);
extern char *strstr(const char *,const char *);
extern unsigned strlen(const char *);
extern int memcmp(const void *,const void *,unsigned);
extern void *opendir(const char *);
extern void *readdir64(void *);
extern int closedir(void *);
extern int *__errno_location(void);
extern int setvbuf(void *,char *,int,unsigned);
const char *native_control_note(void);
typedef struct {unsigned start,end;int writable;} Span;
typedef struct {
 Span spans[1024];unsigned count,sdk,dvb;int has_sdk,has_dvb;void *mem;
} Process;
static Process state;
static char output[24576];static unsigned used;
static void line(const char *format,...) {
 va_list ap;int n;
 if(used+2>=sizeof(output))return;
 va_start(ap,format);n=vsnprintf(output+used,sizeof(output)-used,format,ap);va_end(ap);
 if(n<0)return;
 if((unsigned)n>=sizeof(output)-used){used=sizeof(output)-1;output[used]=0;return;}
 used+=(unsigned)n;
 if(used+1<sizeof(output)){output[used++]='\n';output[used]=0;}
}
static int readable(Process *p,unsigned address,unsigned bytes) {
 unsigned i;
 if(!bytes || address+bytes<address)return 0;
 for(i=0;i<p->count;i++)if(address>=p->spans[i].start && address+bytes<=p->spans[i].end)return 1;
 return 0;
}
static int read_at(Process *p,unsigned address,void *out,unsigned bytes) {
 if(!p->mem || !readable(p,address,bytes))return 0;
 if(fseeko64(p->mem,(long long)address,0))return 0;
 return fread(out,1,bytes,p->mem)==bytes;
}
static unsigned word(Process *p,unsigned address) {
 unsigned n=0;read_at(p,address,&n,4);return n;
}
static int code_matches(Process *p,unsigned address,const unsigned char *expected) {
 unsigned char buffer[64];return read_at(p,address,buffer,64) && !memcmp(buffer,expected,64);
}
static void string_at(Process *p,unsigned address,char *out,unsigned cap) {
 unsigned i;unsigned char c=0;
 if(!cap)return;
 for(i=0;i+1<cap;i++) {
  if(!read_at(p,address+i,&c,1) || !c)break;
  out[i]=(c<32 || c==127)?'?':(char)c;
 }
 out[i]=0;
}
static int maps(Process *p,const char *root,const char *pid) {
 char name[256],buffer[1024],perms[8];unsigned start,end,offset;void *f;
 p->count=0;p->has_sdk=p->has_dvb=0;p->sdk=p->dvb=0;p->mem=0;
 snprintf(name,sizeof(name),"%s/%s/maps",root,pid);f=fopen(name,"r");if(!f)return 0;
 while(fgets(buffer,sizeof(buffer),f)) {
  if(sscanf(buffer,"%x-%x %4s %x",&start,&end,perms,&offset)!=4 || end<=start)continue;
  if(perms[0]=='r' && p->count<1024){p->spans[p->count].start=start;p->spans[p->count].end=end;p->spans[p->count++].writable=perms[1]=='w';}
  if(offset==0 && strstr(buffer,"/libMStarSDK.so")){p->sdk=start-SDK_BASE;p->has_sdk=1;}
  if(offset==0 && strstr(buffer,"/libmsrv_dvb.so")){p->dvb=start-DVB_BASE;p->has_dvb=1;}
 }
 fclose(f);return p->has_sdk && p->has_dvb;
}
static void decoder(Process *p,unsigned object) {
 unsigned vt,timefun,durfun,listener,flags;unsigned char init;unsigned op[2];
 if(!readable(p,object,0x14)){line("  DECODER: ponteiro indisponivel");return;}
 vt=word(p,object);listener=word(p,object+4);init=0;read_at(p,object+0x10,&init,1);
 timefun=word(p,vt+0x2c);durfun=word(p,vt+0x30);flags=word(p,object+0xc);
 line("  DECODER=0x%08x VT=0x%08x LISTENER=0x%08x BYTE10=%u FLAGS0C=0x%x",object,vt,listener,init,flags);
 line("  GETTIME_FN=0x%08x GETDURATION_FN=0x%08x",timefun,durfun);
 if(read_at(p,timefun,op,8))line("  GETTIME_OP=%08x %08x%s",op[0],op[1],
    op[0]==0x03e00008u && op[1]==0x2402ffffu?" RETORNO CONSTANTE -1":"");
 if(read_at(p,durfun,op,8))line("  GETDURATION_OP=%08x %08x%s",op[0],op[1],
    op[0]==0x03e00008u && op[1]==0x2402ffffu?" RETORNO CONSTANTE -1":"");
}
static void inspect(Process *p,int selected) {
 unsigned manager,video,head,node,next,item,id,cached,guard,mw,movie,music,handle,global,seen[64],count=0,i;
 char filename[257];int matched=0;
 manager=word(p,p->sdk+SDK_MANAGER_PTR);video=word(p,p->sdk+SDK_VIDEO_PTR);
 line("SDK_VIDEO=0x%08x SDK_MANAGER=0x%08x",video,manager);
 if(video && readable(p,video,0x90))line("VIDEO_VT=0x%08x HANDLER=0x%08x LISTENER=0x%08x",word(p,video),word(p,video+0xc),word(p,video+8));
 if(manager && readable(p,manager,12)) {
  head=manager+4;node=word(p,head);
  while(node && node!=head && count<64) {
   for(i=0;i<count;i++)if(seen[i]==node){line("SDK_LIST: ciclo ou transicao detectada");return;}
   seen[count++]=node;
   if(!readable(p,node,12)){line("SDK_LIST: no deixou de estar disponivel");break;}
   next=word(p,node);item=word(p,node+8);
   if(readable(p,item,0xc0)) {
    id=word(p,item+0x94);cached=word(p,item+0xb8);
    string_at(p,word(p,item+0x84),filename,sizeof(filename));
    line("SDK_ID=%u%s OBJ=0x%08x DURATION_CACHE=%d TYPE=%u FILE=%s",id,id==(unsigned)selected?" [SELECIONADO]":"",item,(int)cached,word(p,item+0x98),filename);
    if(id==(unsigned)selected){matched=1;decoder(p,word(p,item+0x74));}
   }
   node=next;
  }
  if(count && word(p,head)!=seen[0])line("SDK_LIST: mudou durante a leitura; repetir com video estavel");
  if(!matched)line("SDK_ID selecionado nao foi localizado nesta captura");
 } else line("SDK_MANAGER ainda nao disponivel");
 guard=0;read_at(p,p->dvb+DVB_GINGA_GUARD,&guard,1);mw=p->dvb+DVB_GINGA_OBJECT;
 line("MW_GINGA_GUARD=%u OBJ=0x%08x",guard,mw);
 if(guard && readable(p,mw,0xf4)) {
  movie=word(p,mw+0xec);music=word(p,mw+0xf0);
  line("MW_MOVIE=0x%08x MW_MUSIC=0x%08x",movie,music);
  global=word(p,p->dvb+DVB_MOVIE_HANDLE);handle=movie?word(p,movie+0x6c):0;
  line("MOVIE_HANDLE=0x%08x GLOBAL_MOVIE=0x%08x MATCH=%u STATE=%u",handle,global,handle!=0 && handle==global,movie?word(p,movie+0x70):0);
  global=word(p,p->dvb+DVB_MUSIC_HANDLE);handle=music?word(p,music+0x6c):0;
  line("MUSIC_HANDLE=0x%08x GLOBAL_MUSIC=0x%08x MATCH=%u STATE=%u",handle,global,handle!=0 && handle==global,music?word(p,music+0x70):0);
 }
}
static const char *report(const char *root,int selected) {
 void *dir,*entry;char path[256],pid[16],*name;unsigned n,scanned=0,found=0,opened=0;
 used=0;output[0]=0;line("RE510 NATIVO 0.6.3 | GINGA_ID=%d | captura somente de leitura",selected);
 dir=opendir(root);if(!dir){line("Nao foi possivel listar proc: errno=%d",*__errno_location());return output;}
 while((entry=readdir64(dir)) && scanned++<8192 && found<8) {
  name=(char *)entry+19; /* Linux dirent64: ino64, off64, reclen16, type8. */
  for(n=0;name[n] && n<sizeof(pid)-1;n++)if(name[n]<'0' || name[n]>'9')break;
  if(!n || name[n])continue;
  for(n=0;name[n] && n<sizeof(pid)-1;n++)pid[n]=name[n];
  pid[n]=0;
  if(!maps(&state,root,pid))continue;
  found++;line("PID=%s SDK_BIAS=0x%08x DVB_BIAS=0x%08x",pid,state.sdk,state.dvb);
  snprintf(path,sizeof(path),"%s/%s/mem",root,pid);state.mem=fopen(path,"rb");
  if(!state.mem){line("Leitura da memoria nativa indisponivel: errno=%d",*__errno_location());continue;}
  setvbuf(state.mem,0,2,0);
  if(!code_matches(&state,state.sdk+CHECK_sdk_find_VA,check_sdk_find) ||
     !code_matches(&state,state.dvb+CHECK_dvb_gettime_VA,check_dvb_gettime) ||
     !code_matches(&state,state.dvb+CHECK_dvb_instance_VA,check_dvb_instance)) {
   line("Bibliotecas em execucao diferem dos trechos V1.11.0; estrutura nao interpretada");
  } else {opened++;inspect(&state,selected);}
  fclose(state.mem);state.mem=0;
 }
 closedir(dir);
 if(!found)line("Nenhum processo com as duas bibliotecas nativas foi encontrado");
 line("PROCESSOS=%u CAPTURAS=%u | leitura sem parar threads; pode haver transicao",found,opened);
 return output;
}
const char *re510_native_report(int selected){report("/proc",selected);line("CONTROLE: %s",native_control_note());return output;}
#ifdef SNAPSHOT_TEST
extern int puts(const char *);
int main(int argc,char **argv){if(argc!=2)return 2;puts(report(argv[1],5));return 0;}
#endif

#include "native_control.inc"
