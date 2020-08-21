#ifndef __RESPOND_H__
#define __RESPOND_H__

typedef struct { char *name, *value; } header_t;
#define MAX_HEADERS	(20)

typedef struct {
	char    *method,    // "GET" or "POST"
			*uri,       // "/index.html" things before '?'
			*qs,        // "a=1&b=2"     things after  '?'
			*prot;      // "HTTP/1.1"

	char    *payload;     // for POST
	int      payload_size;
	header_t hdrs[MAX_HEADERS];
} request_params_t;

char *request_header(const char* name);
void respond(int n);
void route(request_params_t *params);

// some interesting macro for `route()`
#define ROUTE_START()       if (0) {
#define ROUTE(METHOD,URI)   } else if (strcmp(URI,params->uri)==0&&strcmp(METHOD,params->method)==0) {
#define ROUTE_GET(URI)      ROUTE("GET", URI) 
#define ROUTE_POST(URI)     ROUTE("POST", URI) 
#define ROUTE_END()         } else printf(\
                                "HTTP/1.1 500 Not Handled\r\n\r\n" \
                                "The server has no handler to the request.\r\n" \
                            );

#endif // __RESPOND_H__
