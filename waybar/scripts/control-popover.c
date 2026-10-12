#include <gtk/gtk.h>
#include <gtk-layer-shell.h>
#include <glib-unix.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
    GtkWidget *value_label;
    gboolean brightness;
    guint update_source;
    double pending_value;
} SliderState;

typedef struct {
    const char *card;
    const char *border;
    const char *icon;
    const char *value;
    const char *trough;
    const char *fill;
    const char *thumb;
    const char *thumb_border;
} SliderPalette;

static SliderState state;
static char previous_follow_mouse[16] = "1";
static char previous_mouse_refocus[8] = "true";
static char previous_pass_mouse_when_bound[8] = "false";
static gboolean follow_mouse_overridden;
static gboolean mouse_refocus_overridden;
static gboolean pass_mouse_when_bound_overridden;
static gboolean follow_mouse_restored;

static gboolean set_follow_mouse(const char *value) {
    char *expression = g_strdup_printf("hl.config({input={follow_mouse=%s}})", value);
    char *argv[] = {"hyprctl", "eval", expression, NULL};
    gint wait_status = 0;
    GError *error = NULL;
    gboolean spawned = g_spawn_sync(NULL, argv, NULL,
        G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL,
        NULL, NULL, NULL, NULL, &wait_status, &error);
    g_free(expression);
    if (!spawned) {
        g_clear_error(&error);
        return FALSE;
    }
    gboolean success = g_spawn_check_wait_status(wait_status, &error);
    g_clear_error(&error);
    return success;
}

static gboolean set_mouse_refocus(const char *value) {
    char *expression = g_strdup_printf("hl.config({input={mouse_refocus=%s}})", value);
    char *argv[] = {"hyprctl", "eval", expression, NULL};
    gint wait_status = 0;
    GError *error = NULL;
    gboolean spawned = g_spawn_sync(NULL, argv, NULL,
        G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL,
        NULL, NULL, NULL, NULL, &wait_status, &error);
    g_free(expression);
    if (!spawned) {
        g_clear_error(&error);
        return FALSE;
    }
    gboolean success = g_spawn_check_wait_status(wait_status, &error);
    g_clear_error(&error);
    return success;
}

static gboolean set_pass_mouse_when_bound(const char *value) {
    char *expression = g_strdup_printf("hl.config({binds={pass_mouse_when_bound=%s}})", value);
    char *argv[] = {"hyprctl", "eval", expression, NULL};
    gint wait_status = 0;
    GError *error = NULL;
    gboolean spawned = g_spawn_sync(NULL, argv, NULL,
        G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL,
        NULL, NULL, NULL, NULL, &wait_status, &error);
    g_free(expression);
    if (!spawned) {
        g_clear_error(&error);
        return FALSE;
    }
    gboolean success = g_spawn_check_wait_status(wait_status, &error);
    g_clear_error(&error);
    return success;
}

static void restore_follow_mouse(void) {
    if (follow_mouse_restored)
        return;
    follow_mouse_restored = TRUE;
    if (pass_mouse_when_bound_overridden)
        set_pass_mouse_when_bound(previous_pass_mouse_when_bound);
    if (mouse_refocus_overridden)
        set_mouse_refocus(previous_mouse_refocus);
    if (follow_mouse_overridden)
        set_follow_mouse(previous_follow_mouse);
}

static gboolean terminate_popover(gpointer user_data) {
    gtk_widget_destroy(GTK_WIDGET(user_data));
    return G_SOURCE_REMOVE;
}

static void window_destroyed(GtkWidget *widget, gpointer user_data) {
    (void)widget;
    (void)user_data;
    restore_follow_mouse();
    if (gtk_main_level() > 0)
        gtk_main_quit();
}

static gboolean apply_pending_value(gpointer user_data) {
    (void)user_data;
    state.update_source = 0;

    char value[16];
    snprintf(value, sizeof(value), "%d", (int)(state.pending_value + 0.5));
    char *argv_brightness[] = {"ddcutil", "--bus", "2", "setvcp", "10", value, NULL};
    char *argv_volume[] = {"wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", NULL, NULL};
    char volume_value[24];
    snprintf(volume_value, sizeof(volume_value), "%.2f", state.pending_value / 100.0);
    argv_volume[3] = volume_value;

    GError *error = NULL;
    if (!g_spawn_async(NULL, state.brightness ? argv_brightness : argv_volume,
                       NULL, G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL |
                       G_SPAWN_STDERR_TO_DEV_NULL, NULL, NULL, NULL, &error)) {
        g_clear_error(&error);
    }
    return G_SOURCE_REMOVE;
}

static void slider_changed(GtkRange *range, gpointer user_data) {
    (void)user_data;
    state.pending_value = gtk_range_get_value(range);
    char value[32];
    snprintf(value, sizeof(value), "%d%%", (int)(state.pending_value + 0.5));
    gtk_label_set_text(GTK_LABEL(state.value_label), value);
    if (state.update_source)
        g_source_remove(state.update_source);
    state.update_source = g_timeout_add(state.brightness ? 180 : 35,
                                        apply_pending_value, NULL);
}

static gboolean key_pressed(GtkWidget *widget, GdkEventKey *event, gpointer data) {
    (void)data;
    if (event->keyval == GDK_KEY_Escape) {
        gtk_widget_destroy(widget);
        return TRUE;
    }
    return FALSE;
}

static int clamp_int(int value, int low, int high) {
    if (value < low) return low;
    if (value > high) return high;
    return value;
}

static gboolean current_theme_is_dark(void) {
    char *state_path = g_build_filename(g_get_user_state_dir(),
        "hyprland-theme-gallery", "current", NULL);
    char *theme = NULL;
    gboolean is_dark = g_file_get_contents(state_path, &theme, NULL, NULL) &&
                       g_str_has_prefix(theme, "dark");
    g_free(theme);
    g_free(state_path);
    return is_dark;
}

int main(int argc, char **argv) {
    if (argc < 8) return 2;
    const char *kind = strcmp(argv[1], "brightness") == 0 ? "brightness" : "volume";
    g_strlcpy(previous_follow_mouse, argv[5], sizeof(previous_follow_mouse));
    for (const char *digit = previous_follow_mouse; *digit; digit++) {
        if (!g_ascii_isdigit(*digit)) {
            g_strlcpy(previous_follow_mouse, "1", sizeof(previous_follow_mouse));
            break;
        }
    }
    if (strcmp(argv[6], "true") == 0 || strcmp(argv[6], "false") == 0)
        g_strlcpy(previous_mouse_refocus, argv[6], sizeof(previous_mouse_refocus));
    if (strcmp(argv[7], "true") == 0 || strcmp(argv[7], "false") == 0)
        g_strlcpy(previous_pass_mouse_when_bound, argv[7], sizeof(previous_pass_mouse_when_bound));
    state.brightness = strcmp(kind, "brightness") == 0;
    char pid_file[256];
    snprintf(pid_file, sizeof(pid_file), "/tmp/waybar-control-popover-%s.pid", kind);
    char lock_file[256];
    snprintf(lock_file, sizeof(lock_file), "/tmp/waybar-control-popover-%s.lock", kind);
    if (!g_file_set_contents(lock_file, argv[0], -1, NULL)) return 1;
    int cursor_x = atoi(argv[2]);
    int cursor_y = atoi(argv[3]);
    double initial_value = atof(argv[4]);

    int gtk_argc = 1;
    char *gtk_argv[] = {argv[0], NULL};
    char **gtk_argv_pointer = gtk_argv;
    gtk_init(&gtk_argc, &gtk_argv_pointer);
    follow_mouse_overridden = set_follow_mouse("0");
    mouse_refocus_overridden = set_mouse_refocus("false");
    pass_mouse_when_bound_overridden = set_pass_mouse_when_bound("true");
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(window), FALSE);
    gtk_window_set_default_size(GTK_WINDOW(window), 74, 206);
    gtk_widget_set_name(window, "control-popover");
    gtk_layer_init_for_window(GTK_WINDOW(window));
    gtk_layer_set_namespace(GTK_WINDOW(window), "waybar-control-popover");
    gtk_layer_set_layer(GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
    gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
    gtk_layer_set_exclusive_zone(GTK_WINDOW(window), -1);
    // Request focus on demand without blocking pointer input outside the popover.
    gtk_layer_set_keyboard_mode(GTK_WINDOW(window), GTK_LAYER_SHELL_KEYBOARD_MODE_ON_DEMAND);

    GdkDisplay *display = gtk_widget_get_display(window);
    GdkMonitor *monitor = gdk_display_get_monitor_at_point(display, cursor_x, cursor_y);
    if (monitor) {
        gtk_layer_set_monitor(GTK_WINDOW(window), monitor);
        GdkRectangle geometry;
        gdk_monitor_get_geometry(monitor, &geometry);
        int width = 74;
        int height = 206;
        int x = clamp_int(cursor_x - geometry.x - width / 2, 4, geometry.width - width - 4);
        int y = clamp_int(cursor_y - geometry.y + 4, 4, geometry.height - height - 4);
        gtk_layer_set_margin(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, x);
        gtk_layer_set_margin(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, y);
    }

    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 7);
    gtk_widget_set_name(box, "slider-card");
    gtk_container_set_border_width(GTK_CONTAINER(box), 9);
    gtk_container_add(GTK_CONTAINER(window), box);

    GtkWidget *icon = gtk_label_new(state.brightness ? "☼" : "♫");
    gtk_widget_set_name(icon, "slider-icon");
    gtk_box_pack_start(GTK_BOX(box), icon, FALSE, FALSE, 0);

    GtkWidget *scale = gtk_scale_new_with_range(GTK_ORIENTATION_VERTICAL, 0,
                                                 state.brightness ? 100 : 150, 1);
    gtk_range_set_value(GTK_RANGE(scale), initial_value);
    // Invert GTK's vertical range so the maximum is at the top and minimum
    // at the bottom. Disable automatic direction flipping for RTL locales.
    gtk_range_set_inverted(GTK_RANGE(scale), TRUE);
    gtk_range_set_flippable(GTK_RANGE(scale), FALSE);
    gtk_scale_set_draw_value(GTK_SCALE(scale), FALSE);
    gtk_widget_set_vexpand(scale, TRUE);
    gtk_widget_set_hexpand(scale, TRUE);
    gtk_widget_set_name(scale, "accent-scale");
    gtk_box_pack_start(GTK_BOX(box), scale, TRUE, TRUE, 0);

    char initial_label[32];
    snprintf(initial_label, sizeof(initial_label), "%d%%", (int)(initial_value + 0.5));
    state.value_label = gtk_label_new(initial_label);
    gtk_widget_set_name(state.value_label, "value-label");
    gtk_box_pack_end(GTK_BOX(box), state.value_label, FALSE, FALSE, 0);
    g_signal_connect(scale, "value-changed", G_CALLBACK(slider_changed), NULL);
    g_signal_connect(window, "key-press-event", G_CALLBACK(key_pressed), NULL);
    g_signal_connect(window, "destroy", G_CALLBACK(window_destroyed), NULL);
    g_unix_signal_add(SIGTERM, terminate_popover, window);
    g_unix_signal_add(SIGINT, terminate_popover, window);

    GtkCssProvider *css = gtk_css_provider_new();
    const SliderPalette light = {
        "#fff8fa", "#F7A8B8", "#e88da5", "#ad536e",
        "#f4d8e0", "#F7A8B8", "#55CDFC", "#ffffff"
    };
    const SliderPalette dark = {
        "#17241e", "#75C99A", "#a8d5b7", "#e4eee7",
        "#294a38", "#75C99A", "#d0e6a8", "#101a16"
    };
    const SliderPalette *palette = current_theme_is_dark() ? &dark : &light;
    char *css_text = g_strdup_printf(
        "#control-popover { background: transparent; }"
        "#slider-card { background: %s; border: 1px solid %s; border-radius: 16px; }"
        "#slider-icon { color: %s; font-family: 'Noto Sans Symbols 2', 'DejaVu Sans'; font-size: 19px; }"
        "#value-label { color: %s; font-weight: 600; font-size: 11px; }"
        "#accent-scale trough { min-width: 8px; background: %s; border-radius: 8px; }"
        "#accent-scale highlight { background: %s; border-radius: 8px; }"
        "#accent-scale slider { min-width: 16px; min-height: 16px; background: %s; border: 2px solid %s; border-radius: 10px; }",
        palette->card, palette->border, palette->icon, palette->value,
        palette->trough, palette->fill, palette->thumb, palette->thumb_border);
    gtk_css_provider_load_from_data(css, css_text, -1, NULL);
    g_free(css_text);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(css), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(css);

    gtk_widget_show_all(window);
    // Request focus for this on-demand layer surface. This lets it receive
    // focus-out when a later click activates a different window.
    gtk_window_present(GTK_WINDOW(window));
    char pid_text[32];
    snprintf(pid_text, sizeof(pid_text), "%d\n", (int)getpid());
    g_file_set_contents(pid_file, pid_text, -1, NULL);
    gtk_main();
    restore_follow_mouse();
    remove(pid_file);
    remove(lock_file);
    return 0;
}