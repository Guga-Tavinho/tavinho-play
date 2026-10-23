/* Explicit per-playback experiment. No instruction/flash/file patches.
 * Writes only mmdec+0x10 and playback+0xb8 after firmware/identity checks.
 * Snapshot reads are still read-only. Remote object lifetime cannot be locked
 * from this process; never restore into a replacement or missing object.
 */
extern unsigned fwrite(const void *,unsigned,unsigned,void *);
extern int fflush(void *);

typedef struct {
 Process p;
 unsigned manager,item,decoder,movie,handle,old_duration,new_duration;
 unsigned char old_flag;
 int id,owns;
 char pid[16],filename[512];
} Control;
static Control control,candidate;
static char control_message[512]="Controle temporario ainda nao ativado";
const char *native_control_note(void){return control_message;}
void native_control_confirmed(int position) {
 snprintf(control_message,sizeof(control_message),"PID=%s ID=%d flag10=1 cache=%u; consulta IPC confirmou posicao=%ds",control.pid,control.id,control.new_duration,position);
}
static int note(const char *message) {
 snprintf(control_message,sizeof(control_message),"%s",message);return 0;
}
static int writable(Process *p,unsigned address,unsigned bytes) {
 unsigned i;
 if(!bytes || address+bytes<address)return 0;
 for(i=0;i<p->count;i++)if(p->spans[i].writable && address>=p->spans[i].start && address+bytes<=p->spans[i].end)return 1;
 return 0;
}
static int write_data(Process *p,unsigned address,const void *data,unsigned bytes) {
 unsigned char verify[4];
 if(bytes>4 || !writable(p,address,bytes))return 0;
 if(fseeko64(p->mem,(long long)address,0) || fwrite(data,1,bytes,p->mem)!=bytes || fflush(p->mem))return 0;
 return read_at(p,address,verify,bytes) && !memcmp(data,verify,bytes);
}
static int guarded(Process *p) {
 return code_matches(p,p->sdk+CHECK_sdk_find_VA,check_sdk_find) &&
        code_matches(p,p->sdk+CHECK_sdk_time_VA,check_sdk_time) &&
        code_matches(p,p->sdk+CHECK_sdk_seek_VA,check_sdk_seek) &&
        code_matches(p,p->dvb+CHECK_dvb_gettime_VA,check_dvb_gettime) &&
        code_matches(p,p->dvb+CHECK_dvb_instance_VA,check_dvb_instance);
}
static unsigned selected_object(Process *p,unsigned manager,int id) {
 unsigned head=manager+4,node,seen[64],n=0,i,item,found=0;
 if(!manager || !readable(p,manager,12))return 0;
 node=word(p,head);
 while(node && node!=head && n<64) {
  for(i=0;i<n;i++)if(seen[i]==node)return 0;
  seen[n++]=node;
  if(!readable(p,node,12))return 0;
  item=word(p,node+8);
  if(readable(p,item,0xc0) && (int)word(p,item+0x94)==id){if(found)return 0;found=item;}
  node=word(p,node);
 }
 if(node!=head || (n && word(p,head)!=seen[0]))return 0;
 return found;
}
static int identity(Control *c) {
 Process *p=&c->p;char file[512];
 if(word(p,p->sdk+SDK_MANAGER_PTR)!=c->manager ||
    selected_object(p,c->manager,c->id)!=c->item ||
    word(p,c->item+0x98)!=4 || word(p,c->item+0x74)!=c->decoder ||
    word(p,c->decoder)!=p->sdk+SDK_MOVIE_VTABLE ||
    word(p,c->decoder+4)!=c->item+0x6c)return 0;
 string_at(p,word(p,c->item+0x84),file,sizeof(file));
 return !strcmp(file,c->filename);
}
static int current_handle(Control *c) {
 Process *p=&c->p;unsigned mw=p->dvb+DVB_GINGA_OBJECT;
 return word(p,mw+0xec)==c->movie && c->handle &&
        word(p,c->movie+0x6c)==c->handle && word(p,p->dvb+DVB_MOVIE_HANDLE)==c->handle;
}
static int eligible(Control *c,const char *file,int id) {
 Process *p=&c->p;unsigned video,guard=0;char name[512];unsigned char flag;
 if(!guarded(p))return 0;
 c->manager=word(p,p->sdk+SDK_MANAGER_PTR);c->item=selected_object(p,c->manager,id);c->id=id;
 if(!c->item || word(p,c->item+0x98)!=4)return 0;
 c->decoder=word(p,c->item+0x74);
 if(!readable(p,c->decoder,0x14) || word(p,c->decoder)!=p->sdk+SDK_MOVIE_VTABLE ||
    word(p,c->decoder+4)!=c->item+0x6c || word(p,c->decoder+0xc)!=3)return 0;
 if(!read_at(p,c->decoder+0x10,&flag,1) || flag!=0 || (int)word(p,c->item+0xb8)!=-1)return 0;
 string_at(p,word(p,c->item+0x84),name,sizeof(name));
 if(strcmp(name,file))return 0;
 video=word(p,p->sdk+SDK_VIDEO_PTR);
 if(!video || word(p,video)!=p->sdk+SDK_VIDEO_VTABLE || word(p,video+0x88)!=c->manager)return 0;
 read_at(p,p->dvb+DVB_GINGA_GUARD,&guard,1);
 if(!guard)return 0;
 c->movie=word(p,p->dvb+DVB_GINGA_OBJECT+0xec);
 c->handle=c->movie?word(p,c->movie+0x6c):0;
 if(!current_handle(c) || word(p,c->movie+0x70)!=2)return 0;
 if(!writable(p,c->decoder+0x10,1) || !writable(p,c->item+0xb8,4))return 0;
 snprintf(c->filename,sizeof(c->filename),"%s",file);
 c->old_flag=flag;c->old_duration=word(p,c->item+0xb8);return 1;
}
/* Restore only values still owned by us and an object still in the SDK list.
 * This is a compare-before-write safeguard, not a cross-process atomic lock. */
int native_control_restore(void) {
 unsigned char flag;int ok=1;
 if(!control.owns)return 1;
 if(!identity(&control)) {
  fclose(control.p.mem);control.p.mem=0;control.owns=0;
  return note("Objeto mudou ou terminou; nenhuma restauracao em endereco substituido");
 }
 if(read_at(&control.p,control.decoder+0x10,&flag,1) && flag==1)
  ok=write_data(&control.p,control.decoder+0x10,&control.old_flag,1);
 if(word(&control.p,control.item+0xb8)==control.new_duration)
  ok=write_data(&control.p,control.item+0xb8,&control.old_duration,4) && ok;
 if(!ok)return note("Falha ao restaurar dados; pare o video e reabra o aplicativo");
 fclose(control.p.mem);control.p.mem=0;control.owns=0;
 note("Dados temporarios restaurados na reproducao original");return 1;
}
int native_control_active(int id) {
 if(!control.owns)return 0;
 if(control.id!=id || !identity(&control) || !current_handle(&control)) {
  native_control_restore();return 0;
 }
 return 1;
}
static int enable_at(const char *root,const char *file,int id,int duration) {
 void *dir,*entry;char *name,pid[16],path[256];unsigned scanned=0,n,found=0;int denied=0;
 unsigned char one=1;
 if(id<0 || !file || file[0]!='/' || strlen(file)>=sizeof(control.filename) || duration<1 || duration>=86400)
  return note("Use um MP4 externo com duracao conhecida menor que 24 horas");
 if(control.owns) {
  if(native_control_active(id) && !strcmp(control.filename,file))return 1;
  if(!native_control_restore())return 0;
 }
 dir=opendir(root);if(!dir)return note("Nao foi possivel listar os processos");
 candidate.p.mem=0;
 while((entry=readdir64(dir)) && scanned++<8192) {
  name=(char *)entry+19;
  for(n=0;name[n] && n<sizeof(pid)-1;n++)if(name[n]<'0'||name[n]>'9')break;
  if(!n || name[n])continue;
  for(n=0;name[n] && n<sizeof(pid)-1;n++)pid[n]=name[n];
  pid[n]=0;
  if(!maps(&state,root,pid))continue;
  snprintf(path,sizeof(path),"%s/%s/mem",root,pid);state.mem=fopen(path,"rb");
  if(!state.mem){denied=1;continue;}
  setvbuf(state.mem,0,2,0);
  candidate.p=state;
  if(eligible(&candidate,file,id)) {
   found++;
   if(found==1){control=candidate;snprintf(control.pid,sizeof(control.pid),"%s",pid);control.p.mem=0;}
  }
  fclose(state.mem);state.mem=0;candidate.p.mem=0;
 }
 closedir(dir);
 if(found!=1)return note(denied?"Acesso ao estado nativo negado":"Estado diferente do diagnostico: nenhuma alteracao realizada");
 snprintf(path,sizeof(path),"%s/%s/mem",root,control.pid);control.p.mem=fopen(path,"r+b");
 if(!control.p.mem){snprintf(control_message,sizeof(control_message),"Escrita dos dados temporarios negada: errno=%d",*__errno_location());return 0;}
 setvbuf(control.p.mem,0,2,0);
 if(!eligible(&control,file,id) || !identity(&control)) {
  fclose(control.p.mem);control.p.mem=0;return note("Estado mudou antes do teste; nenhuma alteracao realizada");
 }
 control.new_duration=(unsigned)duration;control.owns=1;
 if(!write_data(&control.p,control.item+0xb8,&control.new_duration,4) ||
    !identity(&control) || !current_handle(&control) ||
    !write_data(&control.p,control.decoder+0x10,&one,1) || !identity(&control)) {
  if(native_control_restore())note("Teste cancelado: alteracao nao confirmou; dados restaurados");
  return 0;
 }
 snprintf(control_message,sizeof(control_message),"PID=%s ID=%d flag10=1 cache=%d; consulta IPC ainda precisa confirmar",control.pid,id,duration);
 return 1;
}
int native_control_enable(const char *file,int id,int duration){return enable_at("/proc",file,id,duration);}

#ifndef CONTROL_TEST
__attribute__((destructor)) static void unload_control(void){native_control_restore();}
#endif

#ifdef CONTROL_TEST
extern int puts(const char *);
int main(int argc,char **argv) {
 int result;
 if(argc<3)return 2;
 result=enable_at(argv[1],"/usb/sda1/Videos/Ep1.mp4",1,1415);
 puts(native_control_note());
 if(!strcmp(argv[2],"keep"))return result?0:3;
 if(!strcmp(argv[2],"restore")) {
  if(!result)return 4;
  return native_control_restore()?0:5;
 }
 if(!strcmp(argv[2],"replace")) {
  unsigned id=8;
  if(!result)return 6;
  if(!write_data(&control.p,control.item+0x94,&id,4))return 7;
  native_control_restore();puts(native_control_note());return 0;
 }
 return result?8:0;
}
#endif
