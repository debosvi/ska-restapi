
set(LOCAL_APPS httpd)

set(LOCAL_SOURCES
    main.c
    respond.c
    route.c
)

add_executable(${LOCAL_APPS} ${LOCAL_SOURCES})

install(TARGETS ${LOCAL_APPS}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib/static
    )
