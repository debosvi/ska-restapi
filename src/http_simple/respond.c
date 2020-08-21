
#include <sys/socket.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "respond.h"

static request_params_t params_g;

#define MAX_BUF_SIZE (65535)
static char buf[MAX_BUF_SIZE];

// get request header
char *request_header(const char* name)
{
    header_t *h = params_g.hdrs;
    while(h->name) {
        if (strcmp(h->name, name) == 0) return h->value;
        h++;
    }
    return NULL;
}

void respond(int n) {
    int rcvd=recv(n, buf, MAX_BUF_SIZE, 0);

    if (rcvd<0)    // receive error
        fprintf(stderr,("recv() error\n"));
    else if (rcvd==0)    // receive socket closed
        fprintf(stderr,"Client disconnected upexpectedly.\n");
    else    // message received
    {
        buf[rcvd] = '\0';

        params_g.method = strtok(buf,  " \t\r\n");
        params_g.uri    = strtok(NULL, " \t");
        params_g.prot   = strtok(NULL, " \t\r\n"); 

        fprintf(stderr, "\x1b[32m + [%s] %s\x1b[0m\n", params_g.method, params_g.uri);
        
        if (params_g.qs = strchr(params_g.uri, '?'))
        {
            *params_g.qs++ = '\0'; //split URI
        } else {
            params_g.qs = params_g.uri - 1; //use an empty string
        }

        header_t *h = params_g.hdrs;
        char *t=0, *t2=0;
        while(h < params_g.hdrs+MAX_HEADERS) {
            char *k,*v,*t;
            k = strtok(NULL, "\r\n: \t"); if (!k) break;
            v = strtok(NULL, "\r\n");     while(*v && *v==' ') v++;
            h->name  = k;
            h->value = v;
            h++;
            fprintf(stderr, "[H] %s: %s\n", k, v);
            t = v + 1 + strlen(v);
            if (t[1] == '\r' && t[2] == '\n') break;
        }
        t++; // now the *t shall be the beginning of user payload
        t2 = request_header("Content-Length"); // and the related header if there is  
        params_g.payload = t;
        params_g.payload_size = t2 ? atol(t2) : (rcvd-(t-buf));

        route(&params_g);
    }

}