
#include <stdio.h>
#include <skalibs/iopause.h>
#include <skalibs/buffer.h>
#include <skalibs/stralloc.h>

static int cont=1;
    
static stralloc bufread = STRALLOC_ZERO;
#define BUFLEN (32)

int main(int ac, char **av) {
    iopause_fd x[2] = { { 0, IOPAUSE_READ, 0} , { 1, 0, -1} };
    tain_t deadline;
    
    tain_now_g();
    tain_addsec_g(&deadline, 1);
    
    stralloc_ready(&bufread, BUFLEN);
    
    while(cont) {
        
        int r=iopause_g(x, 2, &deadline);
        if(r<0) {
            
        }
        else if(!r) {
            tain_addsec_g(&deadline, 1);
            continue;
        }
        
        if(x[0].revents & IOPAUSE_READ) {
            // read chunck
            int w=buffer_get (buffer_0small, bufread.s, BUFLEN);
            fprintf(stderr, "bytes read: %d\n", w);
            cont=0;
        }
    }
    
    return 0;
}
