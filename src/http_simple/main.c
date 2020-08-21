
#include <stdio.h>
#include <skalibs/iopause.h>
#include <skalibs/buffer.h>
#include <skalibs/stralloc.h>

#include "http_parser.h"

typedef struct {
    int all_complete;
} mydata_t;

static int cont=1;
    
static stralloc bufread = STRALLOC_ZERO;
#define BUFLEN (32)

static int on_hdr_field (http_parser *p, const char *buf, size_t len) {
    fprintf(stderr, "ohf: field (%.*s)\n", len, buf);
    return 0;
}

static int on_hdr_value (http_parser *p, const char *buf, size_t len) {
    fprintf(stderr, "ohv: value (%.*s)\n", len, buf);
    return 0;
}

static int on_hdr_complete (http_parser* parser) {
    if(!parser) return -1;
    
    fprintf(stderr, "ohc: call \n");
    fprintf(stderr, "ohc: method (%s)\n", http_method_str(parser->method));
    fprintf(stderr, "ohc: status_code (%d)\n", parser->status_code);
    fprintf(stderr, "ohc: http_major (%d)\n", parser->http_major);
    fprintf(stderr, "ohc: http_minor (%d)\n", parser->http_minor);
    fprintf(stderr, "ohc: content_length (%d)\n", parser->content_length);
    fprintf(stderr, "ohc: should_keep_alive (%d)\n", http_should_keep_alive(parser));
  
    return 0;
}

static int on_msg_complete (http_parser* parser) {
    if(!parser) return -1;

    fprintf(stderr, "omc: call \n");
    
    mydata_t *md=(mydata_t*)parser->data;
    md->all_complete=1;
    return 0;
}

int main(int ac, char **av) {
    iopause_fd x[2] = { { 0, IOPAUSE_READ, 0} , { 1, 0, -1} };
    tain_t deadline;
    
    tain_now_g();
    tain_addsec_g(&deadline, 1);
    
    stralloc_ready(&bufread, BUFLEN);
    
    while(buffer_len(buffer_1small) || cont) {
        x[1].events = (buffer_len(buffer_1small) ? IOPAUSE_WRITE : 0);
        
        int r=iopause_g(x, 2, &deadline);
        if(r<0) {
            
        }
        else if(!r) {
            tain_addsec_g(&deadline, 1);
            continue;
        }
        
        if(x[1].revents & IOPAUSE_WRITE) {
            buffer_flush(buffer_1small);
            cont=0;

            // check n=more events to process
            if(!(--r)) continue;
        }
        
        if(x[0].revents & IOPAUSE_READ) {
            // read chunck
            http_parser parser;
            http_parser_settings settings;
            http_parser_init(&parser, HTTP_REQUEST);
            http_parser_settings_init(&settings);
            ssize_t lp=0;
            int waiting=BUFLEN;
            
            mydata_t mydata = { .all_complete=0 };
            
            parser.data = &mydata;            
            settings.on_headers_complete = on_hdr_complete;
            settings.on_message_complete = on_msg_complete;
            settings.on_header_field = on_hdr_field;
            settings.on_header_value = on_hdr_value;
            
            ssize_t r = sanitize_read(buffer_fill(buffer_0small)) ;
            if (!r) break ;
            if (r < 0) break;
                
            for(;;) {
                size_t blen = buffer_len(buffer_0small);
                if(!blen) break;
                
                stralloc_readyplus(&bufread, blen+1);
                buffer_getnofill(buffer_0small, bufread.s + bufread.len, blen) ;
                bufread.len += blen ;
                bufread.s[bufread.len] = 0 ;                    
                
                fprintf(stderr, "bytes read: %d/%d\n", blen, bufread.len);
                fprintf(stderr, "bytes: %s\n", bufread.s);
                
                lp = http_parser_execute(
                    &parser, &settings,
                    bufread.s, bufread.len
                );  
                
            }
            
            fprintf(stderr, "bytes parsed: %d\n", (int)lp);
            fprintf(stderr, "parser flags: %08x\n", parser.flags);
            fprintf(stderr, "parser errno name: %s\n", http_errno_name(HTTP_PARSER_ERRNO(&parser)));
            fprintf(stderr, "parser errno desc: %s\n", http_errno_description(HTTP_PARSER_ERRNO(&parser)));
            fprintf(stderr, "-------------------------------------\n");
            fprintf(stderr, "-------------------------------------\n");
                        
            if(mydata.all_complete) {
                buffer_puts(buffer_1small, "HTTP/1.1 200 OK\r\n\r\n"); 
                buffer_puts(buffer_1small, "Success"); 
                stralloc_0(&bufread);
            }
            
            // check n=more events to process
            if(!(--r)) continue;
       }
    }
 
    stralloc_free(&bufread);
    
    return 0;
}
