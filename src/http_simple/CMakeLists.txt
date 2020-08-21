
set(LOCAL_APPS httpd)

set(LOCAL_SOURCES
    main.c
)

add_executable(${LOCAL_APPS} ${LOCAL_SOURCES})

target_link_libraries(${LOCAL_APPS} skarnet)

install(TARGETS ${LOCAL_APPS}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib/static
    )
