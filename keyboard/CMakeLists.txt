cmake_minimum_required(VERSION 3.10)
project(evdev-pointer-daemon LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Для удобства сборки вне исходной папки
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}")

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBEVDEV REQUIRED libevdev)

# Исполняемый файл (используем абсолютный путь относительно исходной директории)
add_executable(evdev-pointer-daemon
    "${SRC_DIR}/main.cpp"
)

# Include dirs (включаем также исходную папку, чтобы main.cpp имел доступ к локальным хедерам при необходимости)
target_include_directories(evdev-pointer-daemon PRIVATE
    ${LIBEVDEV_INCLUDE_DIRS}
    "${SRC_DIR}"
)

# Преобразуем флаги из pkg-config в список и применяем как опции компилятора
if(LIBEVDEV_CFLAGS)
    string(REPLACE " " ";" _libevdev_cflags_list "${LIBEVDEV_CFLAGS}")
    target_compile_options(evdev-pointer-daemon PRIVATE ${_libevdev_cflags_list})
endif()

if(LIBEVDEV_CFLAGS_OTHER)
    string(REPLACE " " ";" _libevdev_cflags_other_list "${LIBEVDEV_CFLAGS_OTHER}")
    target_compile_options(evdev-pointer-daemon PRIVATE ${_libevdev_cflags_other_list})
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(evdev-pointer-daemon PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Линкуем библиотеки
target_link_libraries(evdev-pointer-daemon PRIVATE ${LIBEVDEV_LIBRARIES})

# Указываем директорию вывода бинаря (в build/)
set_target_properties(evdev-pointer-daemon PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${BIN_DIR}"
)

# Правило установки
include(GNUInstallDirs)
install(TARGETS evdev-pointer-daemon
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Понятные сообщения при конфигурации
message(STATUS "evdev-pointer-daemon source dir: ${SRC_DIR}")
message(STATUS "evdev-pointer-daemon binary dir: ${BIN_DIR}")
message(STATUS "libevdev includes: ${LIBEVDEV_INCLUDE_DIRS}")
message(STATUS "libevdev libraries: ${LIBEVDEV_LIBRARIES}")
