#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/socket.h>
#include <sys/un.h>

/* =========================================================================
 * 1. Hyprland IPC Translation Hooks (connect, write, send, close)
 * Translates legacy Hyprland v1 dispatch syntax to Hyprland Lua dispatch
 * ========================================================================= */

static int (*real_connect)(int sockfd, const struct sockaddr *addr, socklen_t addrlen) = NULL;
static ssize_t (*real_write)(int fd, const void *buf, size_t count) = NULL;
static ssize_t (*real_send)(int fd, const void *buf, size_t count, int flags) = NULL;
static int (*real_close)(int fd) = NULL;

#define MAX_FD 65536
static char is_hypr_cmd_sock[MAX_FD] = {0};

static int escape_lua_string(const char *input, char *output, size_t output_max) {
    size_t j = 0;
    for (size_t i = 0; input[i] != '\0'; i++) {
        unsigned char ch = (unsigned char)input[i];
        if (ch < 0x20) return 0;
        if (ch == '"' || ch == '\\') {
            if (j + 2 >= output_max) return 0;
            output[j++] = '\\';
        } else if (j + 1 >= output_max) {
            return 0;
        }
        output[j++] = (char)ch;
    }
    output[j] = '\0';
    return 1;
}

__attribute__((constructor))
static void init_hooks(void) {
    if (!real_connect) real_connect = (int (*)(int, const struct sockaddr *, socklen_t))dlsym(RTLD_NEXT, "connect");
    if (!real_write) real_write = (ssize_t (*)(int, const void *, size_t))dlsym(RTLD_NEXT, "write");
    if (!real_send) real_send = (ssize_t (*)(int, const void *, size_t, int))dlsym(RTLD_NEXT, "send");
    if (!real_close) real_close = (int (*)(int))dlsym(RTLD_NEXT, "close");
}

int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    if (!real_connect) init_hooks();
    int res = real_connect(sockfd, addr, addrlen);
    if (res == 0 && addr && addr->sa_family == AF_UNIX) {
        const struct sockaddr_un *un = (const struct sockaddr_un *)addr;
        if (un->sun_path[0] != '\0') {
            size_t len = strnlen(un->sun_path, sizeof(un->sun_path));
            // Match .socket.sock (Hyprland command socket), but NOT .socket2.sock (events)
            if (len >= 12 && strcmp(un->sun_path + len - 12, ".socket.sock") == 0) {
                if (sockfd >= 0 && sockfd < MAX_FD) {
                    is_hypr_cmd_sock[sockfd] = 1;
                }
            }
        }
    }
    return res;
}

int close(int fd) {
    if (!real_close) init_hooks();
    if (fd >= 0 && fd < MAX_FD) {
        is_hypr_cmd_sock[fd] = 0;
    }
    return real_close(fd);
}

static int translate_hypr_cmd(const char *buf, size_t count, char *out, size_t out_max) {
    const char *cmd = buf;
    if (count > 0 && *cmd == '/') {
        cmd++;
        count--;
    }
    if (count < 9 || strncmp(cmd, "dispatch ", 9) != 0) {
        return 0;
    }
    const char *args = cmd + 9;
    size_t args_len = count - 9;

    // 1. workspace <id/name>
    if (args_len >= 10 && strncmp(args, "workspace ", 10) == 0) {
        const char *ws = args + 10;
        size_t ws_len = args_len - 10;
        char ws_buf[128] = {0};
        if (ws_len >= sizeof(ws_buf)) ws_len = sizeof(ws_buf) - 1;
        memcpy(ws_buf, ws, ws_len);
        while (ws_len > 0 && (ws_buf[ws_len - 1] == '\n' || ws_buf[ws_len - 1] == ' ' || ws_buf[ws_len - 1] == '\r')) {
            ws_buf[--ws_len] = '\0';
        }
        char escaped[256] = {0};
        if (!escape_lua_string(ws_buf, escaped, sizeof(escaped))) return 0;
        snprintf(out, out_max, "/dispatch hl.dsp.focus({ workspace = \"%s\" })", escaped);
        return 1;
    }

    // 2. focusworkspaceoncurrentmonitor <id/name>
    if (args_len >= 31 && strncmp(args, "focusworkspaceoncurrentmonitor ", 31) == 0) {
        const char *ws = args + 31;
        size_t ws_len = args_len - 31;
        char ws_buf[128] = {0};
        if (ws_len >= sizeof(ws_buf)) ws_len = sizeof(ws_buf) - 1;
        memcpy(ws_buf, ws, ws_len);
        while (ws_len > 0 && (ws_buf[ws_len - 1] == '\n' || ws_buf[ws_len - 1] == ' ' || ws_buf[ws_len - 1] == '\r')) {
            ws_buf[--ws_len] = '\0';
        }
        char escaped[256] = {0};
        if (!escape_lua_string(ws_buf, escaped, sizeof(escaped))) return 0;
        snprintf(out, out_max, "/dispatch hl.dsp.focus({ workspace = \"%s\", on_current_monitor = true })", escaped);
        return 1;
    }

    // 3. togglespecialworkspace [<name>]
    if (args_len >= 21 && strncmp(args, "togglespecialworkspace", 21) == 0) {
        const char *ws = args + 21;
        size_t ws_len = args_len - 21;
        if (ws_len > 0 && *ws == ' ') {
            ws++;
            ws_len--;
        }
        char ws_buf[128] = {0};
        if (ws_len >= sizeof(ws_buf)) ws_len = sizeof(ws_buf) - 1;
        memcpy(ws_buf, ws, ws_len);
        while (ws_len > 0 && (ws_buf[ws_len - 1] == '\n' || ws_buf[ws_len - 1] == ' ' || ws_buf[ws_len - 1] == '\r')) {
            ws_buf[--ws_len] = '\0';
        }
        if (ws_len == 0) {
            snprintf(out, out_max, "/dispatch hl.dsp.workspace.toggle_special()");
        } else {
            char escaped[256] = {0};
            if (!escape_lua_string(ws_buf, escaped, sizeof(escaped))) return 0;
            snprintf(out, out_max, "/dispatch hl.dsp.workspace.toggle_special(\"%s\")", escaped);
        }
        return 1;
    }

    return 0;
}

ssize_t write(int fd, const void *buf, size_t count) {
    if (!real_write) init_hooks();
    if (fd >= 0 && fd < MAX_FD && is_hypr_cmd_sock[fd] && count > 0) {
        char translated[512];
        if (translate_hypr_cmd((const char *)buf, count, translated, sizeof(translated))) {
            size_t tlen = strlen(translated);
            ssize_t result = real_write(fd, translated, tlen);
            return result < 0 ? result : (ssize_t)count;
        }
    }
    return real_write(fd, buf, count);
}

ssize_t send(int fd, const void *buf, size_t count, int flags) {
    if (!real_send) init_hooks();
    if (fd >= 0 && fd < MAX_FD && is_hypr_cmd_sock[fd] && count > 0) {
        char translated[512];
        if (translate_hypr_cmd((const char *)buf, count, translated, sizeof(translated))) {
            size_t tlen = strlen(translated);
            ssize_t result = real_send(fd, translated, tlen, flags);
            return result < 0 ? result : (ssize_t)count;
        }
    }
    return real_send(fd, buf, count, flags);
}

/* =========================================================================
 * 2. GTK Tooltip Positioning Hook
 * Intercepts gdk_window_move_to_rect for tooltips so they appear vertically
 * centered relative to the hovered icon and extend outward to the right
 * instead of dropping to the bottom.
 * ========================================================================= */

typedef void GdkWindow;
typedef struct {
    int x;
    int y;
    int width;
    int height;
} GdkRectangle;

typedef enum {
  GDK_GRAVITY_NORTH_WEST = 1,
  GDK_GRAVITY_NORTH,
  GDK_GRAVITY_NORTH_EAST,
  GDK_GRAVITY_WEST,
  GDK_GRAVITY_CENTER,
  GDK_GRAVITY_EAST,
  GDK_GRAVITY_SOUTH_WEST,
  GDK_GRAVITY_SOUTH,
  GDK_GRAVITY_SOUTH_EAST,
  GDK_GRAVITY_STATIC
} GdkGravity;

typedef enum {
  GDK_ANCHOR_FLIP_X   = 1 << 0,
  GDK_ANCHOR_FLIP_Y   = 1 << 1,
  GDK_ANCHOR_SLIDE_X  = 1 << 2,
  GDK_ANCHOR_SLIDE_Y  = 1 << 3,
  GDK_ANCHOR_RESIZE_X = 1 << 4,
  GDK_ANCHOR_RESIZE_Y = 1 << 5,
  GDK_ANCHOR_FLIP_RADIAL = 1 << 6
} GdkAnchorHints;

static void (*real_gdk_window_move_to_rect)(GdkWindow *window,
                                            const GdkRectangle *rect,
                                            GdkGravity rect_anchor,
                                            GdkGravity window_anchor,
                                            GdkAnchorHints anchor_hints,
                                            int rect_anchor_dx,
                                            int rect_anchor_dy) = NULL;

static void (*real_gdk_window_get_user_data)(GdkWindow *window, void **data) = NULL;
static const char *(*real_g_type_name_from_instance)(void *instance) = NULL;

void gdk_window_move_to_rect(GdkWindow *window,
                             const GdkRectangle *rect,
                             GdkGravity rect_anchor,
                             GdkGravity window_anchor,
                             GdkAnchorHints anchor_hints,
                             int rect_anchor_dx,
                             int rect_anchor_dy) {
    if (!real_gdk_window_move_to_rect) {
        real_gdk_window_move_to_rect = (void (*)(GdkWindow *, const GdkRectangle *, GdkGravity, GdkGravity, GdkAnchorHints, int, int))dlsym(RTLD_NEXT, "gdk_window_move_to_rect");
    }
    if (!real_gdk_window_get_user_data) {
        real_gdk_window_get_user_data = (void (*)(GdkWindow *, void **))dlsym(RTLD_DEFAULT, "gdk_window_get_user_data");
    }
    if (!real_g_type_name_from_instance) {
        real_g_type_name_from_instance = (const char *(*)(void *))dlsym(RTLD_DEFAULT, "g_type_name_from_instance");
    }

    void *user_data = NULL;
    const char *type_name = NULL;
    if (window && real_gdk_window_get_user_data) {
        real_gdk_window_get_user_data(window, &user_data);
        if (user_data && real_g_type_name_from_instance) {
            type_name = real_g_type_name_from_instance(user_data);
        }
    }

    if (type_name && (strstr(type_name, "Tooltip") != NULL || strcmp(type_name, "GtkTooltipWindow") == 0)) {
        // Vertical bar on left: anchor tooltip to EAST of the bar (x=50), extending to WEST (rightward)
        // Vertically centered relative to the hovered icon (dy = 0)
        GdkRectangle mod_rect;
        if (rect) {
            mod_rect = *rect;
            mod_rect.x = 0;
            mod_rect.width = 50; // Bar width is 50px
        }

        real_gdk_window_move_to_rect(window,
                                     rect ? &mod_rect : NULL,
                                     GDK_GRAVITY_EAST,
                                     GDK_GRAVITY_WEST,
                                     GDK_ANCHOR_FLIP_X | GDK_ANCHOR_SLIDE_Y,
                                     8,  // 8px gap to the right of the bar border
                                     0); // 0 vertical offset -> centered vertically
        return;
    }

    real_gdk_window_move_to_rect(window, rect, rect_anchor, window_anchor, anchor_hints, rect_anchor_dx, rect_anchor_dy);
}
