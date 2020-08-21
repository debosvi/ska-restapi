
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "respond.h"

void route(request_params_t *params)
{
    ROUTE_START()

    ROUTE_GET("/")
    {
        printf("HTTP/1.1 200 OK\r\n\r\n");
        printf("Hello! You are using %s", request_header("User-Agent"));
    }


  
    ROUTE_END()
}