/*
* Copyright (C) 2017-2021 Lains
*
* This program is free software; you can redistribute it &&/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
namespace Notejot {
    public class Log : Object {
        public string title { get; set; }
        public string subtitle { get; set; }
        public string text { get; set; }
        public string color { get; set; }
        public string notebook { get; set; }
    }

    public class Widgets.Note : Adw.ActionRow {
        public Widgets.TextField textfield;
        public Widgets.FormatBar formatbar;
        private static int uid_counter;
        public int uid;
        private Gtk.CssProvider css_provider;

        public unowned Log log { get; construct; }
        public unowned MainWindow win { get; construct; }

        public Note (MainWindow win, Log? log) {
            Object (log: log,
                    win: win);
            this.uid = uid_counter++;
            this.hexpand = false;

            // Icon intentionally null so it becomes a badge instead.
            var icon = new Gtk.Image.from_icon_name ("");
            icon.halign = Gtk.Align.START;
            icon.valign = Gtk.Align.CENTER;
            icon.get_style_context ().add_class ("notejot-sidebar-dbg-%d".printf(uid));

            textfield = new Widgets.TextField (win);
            var text_scroller = new Gtk.ScrolledWindow ();
            text_scroller.vexpand = true;
            text_scroller.hexpand = true;
            text_scroller.set_child (textfield);
            Gtk.TextIter A, B;
            textfield.get_buffer ().get_bounds (out A, out B);
            textfield.get_buffer ().insert_markup(ref A, log.text, -1);
            textfield.controller = this;

            formatbar = new Widgets.FormatBar ();
            formatbar.controller = textfield;

            var note_grid = new Gtk.Grid ();
            note_grid.attach (text_scroller, 0, 3);
            note_grid.attach (formatbar, 0, 4);
            win.main_stack.add_named (note_grid, "textfield-%d".printf(uid));
            note_grid.get_style_context ().add_class ("notejot-stack-%d".printf(uid));

            set_notebook ();
            sync_subtitles ();
            update_theme (log.color);
            if (log.title == "") {
                this.set_title (_("Loading…"));
                this.set_subtitle (_("Loading…"));
            } else {
                this.set_title (log.title);
            }
            this.get_style_context ().add_class ("notejot-sidebar-box");
            this.add_prefix (icon);

            formatbar.notebooklabel.notify["get-text"].connect (() => {
                log.notebook = formatbar.notebooklabel.get_text();
            });

            win.notebookstore.items_changed.connect (() => {
                win.tm.save_notes.begin (win.notestore);
            });

            Timeout.add_seconds(1, () => {
                sync_subtitles ();
                return true;
            });

            if (!Notejot.Application.gsettings.get_boolean("dark-mode")) {
                win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$uid");
            }

            if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                note_grid.get_style_context ().add_class ("notejot-stack-dark-%d".printf(uid));
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                note_grid.get_style_context ().remove_class ("notejot-stack-dark-%d".printf(uid));
            }

            Notejot.Application.gsettings.changed.connect (() => {
                if (!Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    win.titlebar.get_style_context ().remove_class (@"notejot-action-dark-$uid");
                }

                if (Notejot.Application.gsettings.get_boolean("dark-mode")) {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    textfield.get_style_context ().add_class ("notejot-tview-dark-%d".printf(uid));
                    note_grid.get_style_context ().add_class ("notejot-stack-dark-%d".printf(uid));
                } else {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    textfield.get_style_context ().remove_class ("notejot-tview-dark-%d".printf(uid));
                    note_grid.get_style_context ().remove_class ("notejot-stack-dark-%d".printf(uid));
                }
            });
        }

        public void destroy_item () {
            this.dispose ();
            css_provider.dispose ();
            win.tm.save_notes.begin (win.notestore);
        }

        public void select_item () {
            if (win.main_stack != null) {
                win.main_stack.set_visible_child_name ("textfield-%d".printf(uid));
            }
        }

        public void set_notebook () {
            if (log != null && log.notebook != "") {
                formatbar.notebooklabel.set_label (log.notebook);
            } else {
                formatbar.notebooklabel.set_label (_("No Notebook"));
            }
        }

        public void update_theme(string? color) {
            css_provider = new Gtk.CssProvider();
            string style = null;
            style = (N_("""
            .notejot-sidebar-dbg-%d {
                background: mix(%s, @theme_base_color, 0.5);
                border-radius: 9999px;
                border: 1px solid @borders;
            }
            .notejot-action-%d {
                background: mix(@theme_bg_color, %s, 0.1);
            }
            .notejot-stack-%d {
                background: mix(@theme_bg_color, %s, 0.1);
            }
            .notejot-stack-%d .notejot-bar {
                background: mix(@theme_bg_color, %s, 0.1);
                border-top: 1px solid @borders;
            }
            .notejot-action-dark-%d {
                background: shade(mix(@theme_bg_color, %s, 0.1), 0.75);
            }
            .notejot-stack-dark-%d {
                background: shade(mix(@theme_bg_color, %s, 0.1), 0.75);
            }
            .notejot-stack-dark-%d .notejot-bar {
                background: shade(mix(@theme_bg_color, %s, 0.1), 0.75);
                border-top: 1px solid @borders;
            }
            .notejot-action-%d:backdrop {
                background: mix(%s, @theme_base_color, 0.9);
            }
            .notejot-stack-%d:backdrop {
                background: mix(%s, @theme_base_color, 0.9);
            }
            .notejot-stack-%d:backdrop .notejot-bar {
                background: mix(%s, @theme_base_color, 0.9);
                border-top: 1px solid @borders;
            }
            .notejot-stack-%d box {
                border: none;
            }
            """)).printf(uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid,
                         color,
                         uid
            );

            css_provider.load_from_data(style.data);

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            log.color = color;
            win.tm.save_notes.begin (win.notestore);
        }

        public void sync_subtitles () {
            try {
                var reg = new Regex("""(?m)^.*, (?<day>\d{2})/(?<month>\d{2}) (?<hour>\d{2})∶(?<minute>\d{2})$""");
                GLib.MatchInfo match;

                if (this != null && log != null && log.subtitle != "" && log.text != "") {
                    if (reg.match (log.subtitle, 0, out match)) {
                        var e = new GLib.DateTime.now_local ();
                        var d = new DateTime.local (e.get_year (),
                                                    int.parse(match.fetch_named ("month")),
                                                    int.parse(match.fetch_named ("day")),
                                                    int.parse(match.fetch_named ("hour")),
                                                    int.parse(match.fetch_named ("minute")),
                                                    e.get_second ());

                        Timeout.add_seconds(1, () => {
                            set_title("%s".printf(get_first_line (log.text).replace("|", "")
                                                                           .replace("_", "")
                                                                           .replace("*", "")
                                                                           .replace("~", "")));
                            set_subtitle("%s · %s".printf(Utils.get_relative_datetime_compact(d), get_second_line (log.text).replace("|", "")
                                                                                                                            .replace("_", "")
                                                                                                                            .replace("*", "")
                                                                                                                            .replace("~", "")));
                            set_notebook ();
                            return true;
                        });
                    }
                }
                win.tm.save_notes.begin (win.notestore);
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }
        }

        public string get_first_line (string text) {
            string first_line = "";

            try {
                var reg = new Regex("""(?m)(?<first_line>.+)""");
                GLib.MatchInfo match;

                if (reg.match (text, 0, out match) && text != null) {
                    first_line = match.fetch_named ("first_line");
                } else {
                    first_line = "Empty note";
                }
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }
            return first_line;
        }

        public string get_second_line (string text) {
            string second_line = "";

            try {
                var reg = new Regex("""(?m)\n(?<second_line>.+)$""");
                GLib.MatchInfo match;

                if (reg.match (text, 0, out match) && text != null) {
                    second_line = match.fetch_named ("second_line");
                } else {
                    second_line = _("Empty note");
                }
            } catch (GLib.RegexError re) {
                warning ("%s".printf(re.message));
            }
            return second_line;
        }

        public void popover_listener (Widgets.NoteMenuPopover? popover) {
            popover.color_button_red.clicked.connect (() => {
                update_theme("#c01c28");
            });

            popover.color_button_orange.clicked.connect (() => {
                update_theme("#e66100");
            });

            popover.color_button_yellow.clicked.connect (() => {
                update_theme("#f5c211");
            });

            popover.color_button_green.clicked.connect (() => {
                update_theme("#2ec27e");
            });

            popover.color_button_blue.clicked.connect (() => {
                update_theme("#1c71d8");
            });

            popover.color_button_purple.clicked.connect (() => {
                update_theme("#813d9c");
            });

            popover.color_button_brown.clicked.connect (() => {
                update_theme("#865e3c");
            });

            popover.color_button_reset.clicked.connect (() => {
                update_theme("");
            });
        }
    }
}
