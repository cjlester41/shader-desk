# ./CMakeLists.txt

cmake_minimum_required(VERSION 3.13)
project(interactive-wallpaper LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Recommended for debugging/IDE convenience
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# --- Paths ---
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(CFG_DIR "~/.config/interactive-wallpaper")

# Define the output path for all plugins. This variable will be inherited.
set(PLUGIN_OUTPUT_DIR "${BIN_DIR}/effects")
file(MAKE_DIRECTORY ${PLUGIN_OUTPUT_DIR})

# --- Dependencies ---
find_package(PkgConfig REQUIRED)
find_package(glm REQUIRED)
find_package(nlohmann_json REQUIRED)

# Wayland/GL ES dependencies via pkg-config
pkg_check_modules(WAYLAND_CLIENT REQUIRED wayland-client)
pkg_check_modules(WAYLAND_EGL REQUIRED wayland-egl)
pkg_check_modules(EGL REQUIRED egl)
pkg_check_modules(GLESv2 REQUIRED glesv2)
pkg_check_modules(LIBEVDEV REQUIRED libevdev)

# Optional system wayland-protocols
pkg_check_modules(WAYLAND_PROTOCOLS wayland-protocols)

# Find wayland-scanner and sed
find_program(WAYLAND_SCANNER NAMES wayland-scanner)
find_program(SED NAMES sed)

# Output folder for generated protocols
set(PROTOCOL_OUTPUT_DIR "${BIN_DIR}")
file(MAKE_DIRECTORY "${PROTOCOL_OUTPUT_DIR}")

set(PROTOCOL_SOURCES "")
set(GENERATED_PROTOCOL_HEADERS "")

if(WAYLAND_SCANNER AND SED)
    message(STATUS "Found wayland-scanner: ${WAYLAND_SCANNER}")
    message(STATUS "Using sed: ${SED}")

    # Third-party protocol dir shipped with project
    set(THIRD_PARTY_PROTO_DIR "${SRC_DIR}/third_party/wlr-protocols")

    #
    # --- wlr-layer-shell (unstable) ---
    #
    set(LAYER_SHELL_XML "${THIRD_PARTY_PROTO_DIR}/unstable/wlr-layer-shell-unstable-v1.xml")
    set(LAYER_SHELL_XML_FIXED "${PROTOCOL_OUTPUT_DIR}/wlr-layer-shell-unstable-v1-fixed.xml")
    set(LAYER_SHELL_HEADER "${PROTOCOL_OUTPUT_DIR}/wlr-layer-shell-unstable-v1-client-protocol.h")
    set(LAYER_SHELL_SOURCE "${PROTOCOL_OUTPUT_DIR}/wlr-layer-shell-unstable-v1-client-protocol.c")

    if(EXISTS "${LAYER_SHELL_XML}")
        add_custom_command(
            OUTPUT "${LAYER_SHELL_XML_FIXED}"
            COMMAND ${CMAKE_COMMAND} -E copy "${LAYER_SHELL_XML}" "${LAYER_SHELL_XML_FIXED}"
            COMMAND ${SED} -i "s/name=\\\"namespace\\\"/name=\\\"namespace_\\\"/g" "${LAYER_SHELL_XML_FIXED}"
            DEPENDS "${LAYER_SHELL_XML}"
            COMMENT "Fixing namespace keyword in layer shell protocol"
            VERBATIM
        )

        add_custom_command(
            OUTPUT "${LAYER_SHELL_HEADER}" "${LAYER_SHELL_SOURCE}"
            COMMAND ${WAYLAND_SCANNER} client-header "${LAYER_SHELL_XML_FIXED}" "${LAYER_SHELL_HEADER}"
            COMMAND ${WAYLAND_SCANNER} private-code  "${LAYER_SHELL_XML_FIXED}" "${LAYER_SHELL_SOURCE}"
            DEPENDS "${LAYER_SHELL_XML_FIXED}"
            COMMENT "Generating wlr-layer-shell protocol"
            VERBATIM
        )

        list(APPEND PROTOCOL_SOURCES "${LAYER_SHELL_SOURCE}")
        list(APPEND GENERATED_PROTOCOL_HEADERS "${LAYER_SHELL_HEADER}")
    else()
        message(WARNING "wlr-layer-shell xml not found at ${LAYER_SHELL_XML}")
    endif()

    #
    # --- viewporter ---
    #
    if(WAYLAND_PROTOCOLS_FOUND)
        set(VIEWPORTER_XML "${WAYLAND_PROTOCOLS_PREFIX}/share/wayland-protocols/stable/viewporter/viewporter.xml")
    else()
        # Try common system paths
        set(VIEWPORTER_XML "/usr/share/wayland-protocols/stable/viewporter/viewporter.xml")
    endif()

    set(VIEWPORTER_HEADER "${PROTOCOL_OUTPUT_DIR}/viewporter-client-protocol.h")
    set(VIEWPORTER_SOURCE "${PROTOCOL_OUTPUT_DIR}/viewporter-client-protocol.c")

    if(EXISTS "${VIEWPORTER_XML}")
        add_custom_command(
            OUTPUT "${VIEWPORTER_HEADER}" "${VIEWPORTER_SOURCE}"
            COMMAND ${WAYLAND_SCANNER} client-header "${VIEWPORTER_XML}" "${VIEWPORTER_HEADER}"
            COMMAND ${WAYLAND_SCANNER} private-code  "${VIEWPORTER_XML}" "${VIEWPORTER_SOURCE}"
            DEPENDS "${VIEWPORTER_XML}"
            COMMENT "Generating viewporter protocol"
            VERBATIM
        )
        list(APPEND PROTOCOL_SOURCES "${VIEWPORTER_SOURCE}")
        list(APPEND GENERATED_PROTOCOL_HEADERS "${VIEWPORTER_HEADER}")
    else()
        # Try alternate location
        set(VIEWPORTER_XML_ALT "/usr/local/share/wayland-protocols/stable/viewporter/viewporter.xml")
        if(EXISTS "${VIEWPORTER_XML_ALT}")
            add_custom_command(
                OUTPUT "${VIEWPORTER_HEADER}" "${VIEWPORTER_SOURCE}"
                COMMAND ${WAYLAND_SCANNER} client-header "${VIEWPORTER_XML_ALT}" "${VIEWPORTER_HEADER}"
                COMMAND ${WAYLAND_SCANNER} private-code  "${VIEWPORTER_XML_ALT}" "${VIEWPORTER_SOURCE}"
                DEPENDS "${VIEWPORTER_XML_ALT}"
                COMMENT "Generating viewporter protocol (alt path)"
                VERBATIM
            )
            list(APPEND PROTOCOL_SOURCES "${VIEWPORTER_SOURCE}")
            list(APPEND GENERATED_PROTOCOL_HEADERS "${VIEWPORTER_HEADER}")
        else()
            message(WARNING "viewporter XML not found. Tried: ${VIEWPORTER_XML} and ${VIEWPORTER_XML_ALT}")
        endif()
    endif()

    #
    # --- xdg-shell (system) ---
    #
    if(WAYLAND_PROTOCOLS_FOUND)
        set(XDG_XML "${WAYLAND_PROTOCOLS_PREFIX}/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml")
    else()
        set(XDG_XML "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml")
    endif()

    set(XDG_HEADER "${PROTOCOL_OUTPUT_DIR}/xdg-shell-client-protocol.h")
    set(XDG_SOURCE "${PROTOCOL_OUTPUT_DIR}/xdg-shell-client-protocol.c")

    if(EXISTS "${XDG_XML}")
        add_custom_command(
            OUTPUT "${XDG_HEADER}" "${XDG_SOURCE}"
            COMMAND ${WAYLAND_SCANNER} client-header "${XDG_XML}" "${XDG_HEADER}"
            COMMAND ${WAYLAND_SCANNER} private-code  "${XDG_XML}" "${XDG_SOURCE}"
            DEPENDS "${XDG_XML}"
            COMMENT "Generating xdg-shell protocol"
            VERBATIM
        )
        list(APPEND PROTOCOL_SOURCES "${XDG_SOURCE}")
        list(APPEND GENERATED_PROTOCOL_HEADERS "${XDG_HEADER}")
    else()
        message(WARNING "xdg-shell xml not found at ${XDG_XML}")
    endif()

    # Custom target to build all protocols
    add_custom_target(wayland_protocols ALL
        DEPENDS ${PROTOCOL_SOURCES} ${GENERATED_PROTOCOL_HEADERS}
    )
else()
    message(WARNING "wayland-scanner or sed not found. CMake will try to use any existing protocol sources in build/ or source tree.")
endif()

#
# If protocol sources were not generated, try to find existing files
#
if(PROTOCOL_SOURCES STREQUAL "")
    set(POSSIBLE_PROTO_SRCS
        "${BIN_DIR}/wlr-layer-shell-unstable-v1-client-protocol.c"
        "${BIN_DIR}/viewporter-client-protocol.c"
        "${BIN_DIR}/xdg-shell-client-protocol.c"
        "${SRC_DIR}/wlr-layer-shell-unstable-v1-client-protocol.c"
        "${SRC_DIR}/viewporter-client-protocol.c"
        "${SRC_DIR}/xdg-shell-client-protocol.c"
    )

    foreach(_psrc IN LISTS POSSIBLE_PROTO_SRCS)
        if(EXISTS "${_psrc}")
            list(APPEND PROTOCOL_SOURCES "${_psrc}")
            message(STATUS "Found existing protocol source: ${_psrc}")
        endif()
    endforeach()
endif()

# --- Main Application Sources ---
set(APP_SRC_FILES
    "${SRC_DIR}/main.cpp"
    "${SRC_DIR}/interactive-wallpaper.cpp"
    "${SRC_DIR}/config-loader.cpp"
    "${SRC_DIR}/pointer-daemon-client.cpp"
    "${SRC_DIR}/plugin-manager.cpp"
    "${SRC_DIR}/audio-daemon-client.cpp"
    "${SRC_DIR}/shader-utils.cpp"
)
list(APPEND APP_SRC_FILES ${PROTOCOL_SOURCES})

add_library(shader_utils SHARED "${SRC_DIR}/shader-utils.cpp")
target_include_directories(shader_utils PRIVATE "${SRC_DIR}")


# --- Build Main Application ---
add_executable(interactive-wallpaper ${APP_SRC_FILES})

target_include_directories(interactive-wallpaper PRIVATE
    "${BIN_DIR}"
    "${PROTOCOL_OUTPUT_DIR}"
    "${SRC_DIR}"
    ${WAYLAND_CLIENT_INCLUDE_DIRS}
    ${WAYLAND_EGL_INCLUDE_DIRS}
    ${EGL_INCLUDE_DIRS}
    ${GLESv2_INCLUDE_DIRS}
)

target_link_libraries(interactive-wallpaper PRIVATE
    ${WAYLAND_CLIENT_LIBRARIES}
    ${WAYLAND_EGL_LIBRARIES}
    ${EGL_LIBRARIES}
    ${GLESv2_LIBRARIES}
    nlohmann_json::nlohmann_json
    glm::glm
    dl
    pthread
    shader_utils
)

# Add dependency if wayland_protocols target was generated
if(TARGET wayland_protocols)
    add_dependencies(interactive-wallpaper wayland_protocols)
endif()


# --- Build Utility for Interrogating Plugins ---
add_executable(plugin-interrogator "${SRC_DIR}/plugin-interrogator.cpp")
target_include_directories(plugin-interrogator PRIVATE "${SRC_DIR}")
target_link_libraries(plugin-interrogator PRIVATE nlohmann_json::nlohmann_json dl)

# --- Include Subdirectories ---
add_subdirectory(plugins)
add_subdirectory(keyboard)

# --- Installation ---
include(GNUInstallDirs)

# Install main binaries
install(TARGETS interactive-wallpaper plugin-interrogator
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install the shared utility library
install(TARGETS shader_utils
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(
    FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/config.json # Source file path
    DESTINATION
        ${CFG_DIR} # Destination path
    # COMPONENT
        # config # Optional: group related filessd
)

message(STATUS "Main project configured. Plugins will be built into: ${PLUGIN_OUTPUT_DIR}")