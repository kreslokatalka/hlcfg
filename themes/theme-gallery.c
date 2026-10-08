#define _GNU_SOURCE
#include <gtk/gtk.h>
#include <cairo.h>
#include <stdio.h>

typedef struct {
    const char *id;
    const char *name;
    const char *description;
    const char *mood;
    const char *swatches[5];
    const char *preview[6];
} Theme;

static const Theme themes[] = {
    {
        "light", "Rosewater", "Светлая · мягкий день", "ВОЗДУШНАЯ · ПАСТЕЛЬНАЯ",
        {"#FFF5F7", "#F7A8B8", "#F5C2D1", "#55CDFC", "#263041"},
        {"#F5F7FB", "#FFFFFF", "#F7A8B8", "#BDEEFF", "#263041", "#267B9F"}
    },
    {
        "dark", "Тихий лес", "Тёмная · глубокий зелёный", "СОСРЕДОТОЧЕННАЯ · ЛЕСНАЯ",
        {"#101A16", "#17241E", "#294A38", "#75C99A", "#E4EEE7"},
        {"#101A16", "#17241E", "#20372B", "#315F49", "#E4EEE7", "#75C99A"}
    }
};

typedef struct {
    GtkWindow *window;
    GtkWidget *cards[2];
    GtkWidget *selection_hints[2];
    GtkWidget *apply;
    GtkWidget *current_label;
    int selected;
    int current;
    gboolean applying;
} Gallery;

static void rounded_rect(cairo_t *cr, double x, double y, double w, double h,
                         double radius, const char *color) {
    double r = radius;
    cairo_new_sub_path(cr);
    cairo_arc(cr, x + w - r, y + r, r, -G_PI_2, 0);
    cairo_arc(cr, x + w - r, y + h - r, r, 0, G_PI_2);
    cairo_arc(cr, x + r, y + h - r, r, G_PI_2, G_PI);
    cairo_arc(cr, x + r, y + r, r, G_PI, 3 * G_PI_2);
    cairo_close_path(cr);
    GdkRGBA rgba;
    gdk_rgba_parse(&rgba, color);
    cairo_set_source_rgba(cr, rgba.red, rgba.green, rgba.blue, rgba.alpha);
    cairo_fill(cr);
}

static void preview_draw(GtkDrawingArea *area, cairo_t *cr, int width, int height,
                         gpointer user_data) {
    (void)area;
    const Theme *theme = user_data;
    const char *const *p = theme->preview;
    double scale_x = (double)width / 360.0;
    double scale_y = (double)height / 184.0;
    cairo_save(cr);
    cairo_scale(cr, scale_x, scale_y);

    rounded_rect(cr, 0, 0, 360, 184, 12, p[0]);
    rounded_rect(cr, 12, 14, 336, 156, 10, p[1]);
    rounded_rect(cr, 20, 22, 320, 18, 8, p[2]);
    rounded_rect(cr, 26, 27, 45, 8, 4, p[3]);
    rounded_rect(cr, 275, 27, 26, 8, 4, p[5]);
    rounded_rect(cr, 307, 27, 25, 8, 4, p[4]);
    rounded_rect(cr, 31, 51, 110, 104, 8, p[0]);
    rounded_rect(cr, 151, 51, 174, 47, 8, p[0]);
    rounded_rect(cr, 151, 107, 174, 48, 8, p[0]);

    rounded_rect(cr, 42, 62, 88, 5, 2.5, p[4]);
    rounded_rect(cr, 42, 76, 66, 4, 2, p[2]);
    rounded_rect(cr, 42, 87, 76, 4, 2, p[2]);
    rounded_rect(cr, 42, 102, 54, 16, 6, p[3]);

    rounded_rect(cr, 163, 62, 61, 5, 2.5, p[4]);
    rounded_rect(cr, 163, 75, 116, 4, 2, p[2]);
    rounded_rect(cr, 163, 87, 84, 4, 2, p[2]);
    rounded_rect(cr, 163, 119, 39, 22, 6, p[3]);
    rounded_rect(cr, 211, 119, 39, 22, 6, p[5]);
    rounded_rect(cr, 259, 119, 52, 22, 6, p[2]);
    cairo_restore(cr);
}

static void update_cards(Gallery *gallery) {
    for (int i = 0; i < 2; i++) {
        if (i == gallery->selected)
            gtk_widget_add_css_class(gallery->cards[i], "selected");
        else
            gtk_widget_remove_css_class(gallery->cards[i], "selected");
        gtk_label_set_text(GTK_LABEL(gallery->selection_hints[i]),
                           i == gallery->selected ? "●  Выбрана" : "○  Выбрать тему");
    }
    char *current = g_strdup_printf("ТЕКУЩАЯ ТЕМА  ·  %s", themes[gallery->current].name);
    gtk_label_set_text(GTK_LABEL(gallery->current_label), current);
    g_free(current);
    gtk_widget_set_sensitive(gallery->apply, gallery->selected != gallery->current);
    if (gallery->selected == gallery->current)
        gtk_widget_add_css_class(gallery->apply, "apply-current");
    else
        gtk_widget_remove_css_class(gallery->apply, "apply-current");
}

static void card_clicked(GtkButton *button, gpointer user_data) {
    Gallery *gallery = user_data;
    gallery->selected = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(button), "theme-index"));
    update_cards(gallery);
}

static void swatch_draw(GtkDrawingArea *area, cairo_t *cr, int width, int height,
                        gpointer user_data) {
    (void)area;
    const char *color = user_data;
    GdkRGBA rgba;
    gdk_rgba_parse(&rgba, color);
    double radius = (width < height ? width : height) / 2.0 - 1.0;
    cairo_arc(cr, width / 2.0, height / 2.0, radius, 0, 2 * G_PI);
    cairo_set_source_rgba(cr, rgba.red, rgba.green, rgba.blue, rgba.alpha);
    cairo_fill_preserve(cr);
    cairo_set_source_rgba(cr, 0, 0, 0, 0.12);
    cairo_set_line_width(cr, 1.0);
    cairo_stroke(cr);
}

static GtkWidget *make_swatch(const char *color, int index) {
    GtkWidget *swatch = gtk_drawing_area_new();
    gtk_widget_set_size_request(swatch, 26, 26);
    char *name = g_strdup_printf("swatch-%d-%s", index, color + 1);
    gtk_widget_set_name(swatch, name);
    g_free(name);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(swatch), swatch_draw,
                                   (gpointer)color, NULL);
    return swatch;
}

static GtkWidget *build_card(Gallery *gallery, int index) {
    const Theme *theme = &themes[index];
    GtkWidget *button = gtk_button_new();
    gtk_widget_add_css_class(button, "theme-card");
    gtk_widget_set_hexpand(button, TRUE);
    gtk_widget_set_valign(button, GTK_ALIGN_FILL);
    gtk_widget_set_size_request(button, 340, 362);
    gtk_button_set_has_frame(GTK_BUTTON(button), FALSE);
    g_object_set_data(G_OBJECT(button), "theme-index", GINT_TO_POINTER(index));
    g_signal_connect(button, "clicked", G_CALLBACK(card_clicked), gallery);

    GtkWidget *content = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_add_css_class(content, "card-content");
    gtk_button_set_child(GTK_BUTTON(button), content);

    GtkWidget *preview_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_add_css_class(preview_box, "preview-box");
    GtkWidget *preview = gtk_drawing_area_new();
    gtk_widget_set_size_request(preview, 320, 164);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(preview), preview_draw,
                                   (gpointer)theme, NULL);
    gtk_box_append(GTK_BOX(preview_box), preview);
    gtk_box_append(GTK_BOX(content), preview_box);

    GtkWidget *body = gtk_box_new(GTK_ORIENTATION_VERTICAL, 13);
    gtk_widget_add_css_class(body, "card-body");
    gtk_box_append(GTK_BOX(content), body);

    GtkWidget *topline = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_widget_set_valign(topline, GTK_ALIGN_CENTER);
    GtkWidget *mood = gtk_label_new(theme->mood);
    gtk_widget_add_css_class(mood, "eyebrow");
    gtk_widget_set_halign(mood, GTK_ALIGN_START);
    gtk_widget_set_hexpand(mood, TRUE);
    gtk_box_append(GTK_BOX(topline), mood);
    if (gallery->current == index) {
        GtkWidget *badge = gtk_label_new("АКТИВНА");
        gtk_widget_add_css_class(badge, "current-badge");
        gtk_box_append(GTK_BOX(topline), badge);
    }
    gtk_box_append(GTK_BOX(body), topline);

    GtkWidget *title = gtk_label_new(theme->name);
    gtk_widget_add_css_class(title, "card-title");
    gtk_widget_set_halign(title, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(body), title);
    GtkWidget *description = gtk_label_new(theme->description);
    gtk_widget_add_css_class(description, "card-description");
    gtk_widget_set_halign(description, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(body), description);

    GtkWidget *swatches = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 7);
    gtk_widget_set_margin_top(swatches, 2);
    for (int i = 0; i < 5; i++)
        gtk_box_append(GTK_BOX(swatches), make_swatch(theme->swatches[i], index * 5 + i));
    gtk_box_append(GTK_BOX(body), swatches);

    gallery->selection_hints[index] = gtk_label_new("");
    gtk_widget_add_css_class(gallery->selection_hints[index], "selection-hint");
    gtk_widget_set_halign(gallery->selection_hints[index], GTK_ALIGN_END);
    gtk_widget_set_hexpand(gallery->selection_hints[index], TRUE);
    gtk_box_append(GTK_BOX(body), gallery->selection_hints[index]);
    return button;
}

static gboolean show_error(GtkWindow *parent, const char *message) {
    GtkAlertDialog *dialog = gtk_alert_dialog_new("Не удалось применить тему");
    gtk_alert_dialog_set_detail(dialog, message);
    gtk_alert_dialog_show(dialog, parent);
    g_object_unref(dialog);
    return FALSE;
}

static void theme_apply_finished(GPid pid, gint wait_status, gpointer user_data) {
    Gallery *gallery = user_data;
    GError *error = NULL;
    gboolean success = g_spawn_check_wait_status(wait_status, &error);
    g_spawn_close_pid(pid);

    if (!success) {
        gallery->applying = FALSE;
        gtk_window_set_deletable(gallery->window, TRUE);
        gtk_button_set_label(GTK_BUTTON(gallery->apply), "Применить тему  →");
        for (int i = 0; i < 2; i++)
            gtk_widget_set_sensitive(gallery->cards[i], TRUE);
        update_cards(gallery);
        show_error(gallery->window, error ? error->message : "Не удалось применить тему.");
        g_clear_error(&error);
        return;
    }

    gallery->current = gallery->selected;
    gtk_window_close(gallery->window);
}

static void apply_clicked(GtkButton *button, gpointer user_data) {
    (void)button;
    Gallery *gallery = user_data;
    if (gallery->applying || gallery->selected == gallery->current)
        return;

    const char *script = "/home/kreslo/.config/themes/theme-manager.sh";
    char *argv[] = {(char *)script, "apply", (char *)themes[gallery->selected].id, NULL};
    GError *error = NULL;
    gallery->applying = TRUE;
    gtk_window_set_deletable(gallery->window, FALSE);
    for (int i = 0; i < 2; i++)
        gtk_widget_set_sensitive(gallery->cards[i], FALSE);
    gtk_widget_set_sensitive(gallery->apply, FALSE);
    gtk_button_set_label(GTK_BUTTON(gallery->apply), "Применяем…");

    GPid child_pid = 0;
    if (!g_spawn_async(NULL, argv, NULL,
                       G_SPAWN_SEARCH_PATH | G_SPAWN_DO_NOT_REAP_CHILD |
                       G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL,
                       NULL, NULL, &child_pid, &error)) {
        gallery->applying = FALSE;
        gtk_window_set_deletable(gallery->window, TRUE);
        for (int i = 0; i < 2; i++)
            gtk_widget_set_sensitive(gallery->cards[i], TRUE);
        gtk_button_set_label(GTK_BUTTON(gallery->apply), "Применить тему  →");
        update_cards(gallery);
        show_error(gallery->window, error ? error->message : "Не удалось запустить переключение темы.");
        g_clear_error(&error);
        return;
    }
    g_child_watch_add(child_pid, theme_apply_finished, gallery);
}

static gboolean on_key_pressed(GtkEventControllerKey *controller, guint keyval,
                               guint keycode, GdkModifierType state, gpointer user_data) {
    (void)controller; (void)keycode; (void)state;
    Gallery *gallery = user_data;
    if (gallery->applying)
        return TRUE;
    if (keyval == GDK_KEY_Escape) {
        gtk_window_close(gallery->window);
        return TRUE;
    }
    if (keyval == GDK_KEY_Left || keyval == GDK_KEY_Right) {
        gallery->selected = 1 - gallery->selected;
        update_cards(gallery);
        gtk_widget_grab_focus(gallery->cards[gallery->selected]);
        return TRUE;
    }
    if (keyval == GDK_KEY_Return || keyval == GDK_KEY_KP_Enter) {
        if (gallery->selected != gallery->current)
            apply_clicked(GTK_BUTTON(gallery->apply), gallery);
        return TRUE;
    }
    return FALSE;
}

static void activate(GtkApplication *application, gpointer user_data) {
    (void)user_data;
    Gallery *gallery = g_new0(Gallery, 1);
    gallery->current = 0;
    const char *state_home = g_get_user_state_dir();
    char *state_path = g_build_filename(state_home, "hyprland-theme-gallery", "current", NULL);
    char *saved = NULL;
    if (g_file_get_contents(state_path, &saved, NULL, NULL)) {
        if (g_str_has_prefix(saved, "dark")) gallery->current = 1;
    }
    g_free(saved);
    g_free(state_path);
    gallery->selected = gallery->current;

    GtkCssProvider *provider = gtk_css_provider_new();
    const char *css =
        "window.gallery-window { background: #f6f5f2; color: #202721; }"
        "window.gallery-window.dark-window { background: #101a16; color: #e4eee7; }"
        ".gallery-shell { padding: 30px 34px 24px; }"
        ".eyebrow { color: #64836d; font-size: 10px; font-weight: 700; letter-spacing: 1.6px; }"
        ".dark-window .eyebrow { color: #8fbea0; }"
        ".gallery-title { color: #202721; font-size: 29px; font-weight: 700; }"
        ".dark-window .gallery-title { color: #e7f0e9; }"
        ".gallery-subtitle { color: #707a73; font-size: 13px; }"
        ".dark-window .gallery-subtitle { color: #a9b9ad; }"
        ".theme-card { padding: 0; border: 1px solid #e2e5df; border-radius: 19px; background: #fffefa; color: #263041; box-shadow: 0 5px 18px alpha(#324838, 0.07); transition: border-color 160ms ease, box-shadow 160ms ease; }"
        ".theme-card:hover { border-color: #9ab9a1; box-shadow: 0 8px 24px alpha(#324838, 0.13); }"
        ".theme-card.selected { border: 2px solid #538b67; box-shadow: 0 0 0 3px alpha(#75c99a, 0.18); }"
        ".dark-window .theme-card { border-color: #2b3d32; background: #17241e; color: #e4eee7; box-shadow: 0 6px 20px alpha(#000000, 0.22); }"
        ".dark-window .theme-card:hover { border-color: #648c71; }"
        ".dark-window .theme-card.selected { border: 2px solid #75c99a; box-shadow: 0 0 0 3px alpha(#75c99a, 0.15); }"
        ".preview-box { padding: 10px 10px 0; }"
        ".card-body { padding: 17px 20px 18px; }"
        ".card-title { color: #26352b; font-size: 21px; font-weight: 700; }"
        ".dark-window .card-title { color: #e4eee7; }"
        ".card-description { color: #788078; font-size: 12px; }"
        ".dark-window .card-description { color: #a9b9ad; }"
        ".current-badge { padding: 5px 8px; border-radius: 99px; background: #e7f4e9; color: #356d4d; font-size: 9px; font-weight: 700; letter-spacing: 0.6px; }"
        ".dark-window .current-badge { background: #294a38; color: #b0e3bf; }"
        ".selection-hint { color: #738078; font-size: 11px; }"
        ".dark-window .selection-hint { color: #a9b9ad; }"
        ".apply-button { min-height: 42px; padding: 0 20px; border-radius: 12px; background: #356d4d; color: white; font-weight: 700; }"
        ".apply-button:hover { background: #285a3e; }"
        ".apply-button:disabled { background: #e7ebe6; color: #8b948d; }"
        ".dark-window .apply-button { background: #75c99a; color: #102018; }"
        ".dark-window .apply-button:hover { background: #95ddb1; }"
        ".dark-window .apply-button:disabled { background: #2b3d32; color: #8b9d90; }"
        ".footer-hint { color: #858d86; font-size: 11px; }"
        ".dark-window .footer-hint { color: #84968a; }"
        ".divider { background: #e6e8e3; min-height: 1px; }"
        ".dark-window .divider { background: #2b3d32; }";
    gtk_css_provider_load_from_string(provider, css);
    gtk_style_context_add_provider_for_display(gdk_display_get_default(),
        GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);

    gallery->window = GTK_WINDOW(gtk_application_window_new(application));
    gtk_window_set_title(gallery->window, "Theme gallery");
    gtk_window_set_default_size(gallery->window, 880, 618);
    gtk_window_set_resizable(gallery->window, FALSE);
    gtk_window_set_modal(gallery->window, TRUE);
    gtk_widget_add_css_class(GTK_WIDGET(gallery->window), "gallery-window");
    if (gallery->current == 1)
        gtk_widget_add_css_class(GTK_WIDGET(gallery->window), "dark-window");

    GtkWidget *shell = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_add_css_class(shell, "gallery-shell");
    gtk_window_set_child(gallery->window, shell);

    GtkWidget *eyebrow = gtk_label_new("НАСТРОЕНИЕ РАБОЧЕГО СТОЛА");
    gtk_widget_add_css_class(eyebrow, "eyebrow");
    gtk_widget_set_halign(eyebrow, GTK_ALIGN_START);
    gtk_box_append(GTK_BOX(shell), eyebrow);

    GtkWidget *heading = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 14);
    gtk_widget_set_margin_top(heading, 7);
    gtk_widget_set_valign(heading, GTK_ALIGN_CENTER);
    GtkWidget *title = gtk_label_new("Выберите свою тему");
    gtk_widget_add_css_class(title, "gallery-title");
    gtk_widget_set_halign(title, GTK_ALIGN_START);
    gtk_widget_set_hexpand(title, TRUE);
    gtk_box_append(GTK_BOX(heading), title);
    gallery->current_label = gtk_label_new("");
    gtk_widget_add_css_class(gallery->current_label, "eyebrow");
    gtk_box_append(GTK_BOX(heading), gallery->current_label);
    gtk_box_append(GTK_BOX(shell), heading);

    GtkWidget *subtitle = gtk_label_new("Цвета, свет и детали — собраны в цельный образ для всей системы.");
    gtk_widget_add_css_class(subtitle, "gallery-subtitle");
    gtk_widget_set_halign(subtitle, GTK_ALIGN_START);
    gtk_widget_set_margin_top(subtitle, 5);
    gtk_widget_set_margin_bottom(subtitle, 19);
    gtk_box_append(GTK_BOX(shell), subtitle);

    GtkWidget *cards = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 16);
    gtk_widget_set_vexpand(cards, TRUE);
    gtk_box_set_homogeneous(GTK_BOX(cards), TRUE);
    for (int i = 0; i < 2; i++) {
        gallery->cards[i] = build_card(gallery, i);
        gtk_box_append(GTK_BOX(cards), gallery->cards[i]);
    }
    gtk_box_append(GTK_BOX(shell), cards);

    GtkWidget *footer = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 14);
    gtk_widget_set_margin_top(footer, 17);
    gtk_widget_set_valign(footer, GTK_ALIGN_CENTER);
    GtkWidget *hint = gtk_label_new("← →  выбрать     ·     Esc  закрыть без изменений");
    gtk_widget_add_css_class(hint, "footer-hint");
    gtk_widget_set_halign(hint, GTK_ALIGN_START);
    gtk_widget_set_hexpand(hint, TRUE);
    gtk_box_append(GTK_BOX(footer), hint);
    gallery->apply = gtk_button_new_with_label("Применить тему  →");
    gtk_widget_add_css_class(gallery->apply, "apply-button");
    g_signal_connect(gallery->apply, "clicked", G_CALLBACK(apply_clicked), gallery);
    gtk_box_append(GTK_BOX(footer), gallery->apply);
    gtk_box_append(GTK_BOX(shell), footer);

    GtkEventController *keys = gtk_event_controller_key_new();
    gtk_event_controller_set_propagation_phase(keys, GTK_PHASE_CAPTURE);
    g_signal_connect(keys, "key-pressed", G_CALLBACK(on_key_pressed), gallery);
    gtk_widget_add_controller(GTK_WIDGET(gallery->window), keys);
    update_cards(gallery);
    gtk_window_present(gallery->window);
}

int main(int argc, char **argv) {
    GtkApplication *application = gtk_application_new("org.hyprland.theme-gallery",
        G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(application, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(application), argc, argv);
    g_object_unref(application);
    return status;
}