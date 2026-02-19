#include <libevdev/libevdev.h>
#include <linux/input.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <dirent.h>
#include <poll.h>
#include <unistd.h>
#include <csignal>
#include <cstring>
#include <iostream>
#include <sstream>
#include <vector>
#include <chrono>

static volatile sig_atomic_t running = 1;
static void handle_sig(int) { running = 0; }

struct Device {
    int fd = -1;
    libevdev* dev = nullptr;
    std::string path;
    std::string name;
    bool has_abs = false;
};

// Global state to track if the modifier key is pressed
static bool mod_pressed = false;

static std::string default_socket_path() {
    const char* xr = std::getenv("XDG_RUNTIME_DIR");
    if (xr && xr[0]) return std::string(xr) + "/evdev-pointer.sock";
    return "/tmp/evdev-pointer-" + std::to_string(getuid()) + ".sock";
}

static std::string make_json(const Device& d, double dx, double dy) {
    using namespace std::chrono;
    auto now = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
    std::ostringstream oss;
    oss << "{"
        << "\"device\":\"" << d.path << "\","
        << "\"name\":\"" << d.name << "\","
        << "\"type\":\"rel\","
        << "\"normalized\":false,"
        << "\"dx\":" << dx << ","
        << "\"dy\":" << dy << ","
        << "\"vx\":0.0,"
        << "\"vy\":0.0,"
        << "\"dt\":0.0,"
        << "\"ts\":" << now
        << "}";
    return oss.str();
}

static void send_to_socket(int sockfd, const std::string& path, const std::string& json) {
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path.c_str(), sizeof(addr.sun_path) - 1);
    sendto(sockfd, json.c_str(), json.size(), 0, (struct sockaddr*)&addr, sizeof(addr));
}

int main() {
    std::string dest_socket = default_socket_path();
    signal(SIGINT, handle_sig);

    std::vector<Device> devices;
    const char* devdir = "/dev/input";
    DIR* d = opendir(devdir);
    if (d) {
        struct dirent* ent;
        while ((ent = readdir(d)) != nullptr) {
            if (strncmp(ent->d_name, "event", 5) == 0) {
                std::string path = std::string(devdir) + "/" + ent->d_name;
                int fd = open(path.c_str(), O_RDONLY | O_NONBLOCK);
                if (fd < 0) continue;
                
                libevdev* dev = nullptr;
                if (libevdev_new_from_fd(fd, &dev) >= 0) {
                    if (libevdev_has_event_code(dev, EV_KEY, KEY_H)) {
                        devices.push_back({fd, dev, path, libevdev_get_name(dev), false});
                    } else {
                        libevdev_free(dev); close(fd);
                    }
                }
            }
        }
        closedir(d);
    }

    int send_sock = socket(AF_UNIX, SOCK_DGRAM | SOCK_NONBLOCK, 0);
    const int base_step = 20;

    while (running) {
        for (auto &dptr : devices) {
            struct input_event ev;
            while (libevdev_next_event(dptr.dev, LIBEVDEV_READ_FLAG_NORMAL, &ev) == LIBEVDEV_READ_STATUS_SUCCESS) {
                
                // Track Modifier Key (using Left Meta/Super as the Mod key)
                if (ev.type == EV_KEY && ev.code == KEY_LEFTMETA) {
                    mod_pressed = (ev.value != 0); // true if pressed or repeating, false if released
                    continue;
                }

                // Trigger movement on Key Down (1) or Key Repeat (2)
                if (ev.type == EV_KEY && (ev.value == 1 || ev.value == 2)) {
                    double dx = 0, dy = 0;
                    bool move = false;
                    
                    // Determine multiplier based on Mod key state
                    int current_step = mod_pressed ? (base_step * 100) : base_step;

                    switch (ev.code) {
                        case KEY_H: dx = -current_step; move = true; break;
                        case KEY_J: dy =  current_step; move = true; break;
                        case KEY_K: dy = -current_step; move = true; break;
                        case KEY_L: dx =  current_step; move = true; break;
                        default: break;
                    }
                    
                    if (move) {
                        std::string json = make_json(dptr, dx, dy);
                        send_to_socket(send_sock, dest_socket, json);
                    }
                }
            }
        }
        usleep(10000); 
    }

    for (auto &d : devices) { libevdev_free(d.dev); close(d.fd); }
    close(send_sock);
    return 0;
}