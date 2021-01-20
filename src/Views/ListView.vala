namespace Notejot {
    public class Views.ListView : Gtk.ListBox {
        private MainWindow win;
        public bool is_modified {get; set; default = false;}

        public ListView (MainWindow win) {
            this.win = win;
            this.vexpand = true;
            is_modified = false;
            set_sort_func (list_sort);
            this.show_all ();

            this.row_selected.connect ((selected_row) => {
                foreach (var row in get_rows ()) {
                    win.settingmenu.controller = ((Widgets.SidebarItem)selected_row);
                    win.main_stack.set_visible_child (((Widgets.SidebarItem)selected_row).textfield);
                    win.titlebar_title_stack.set_visible_child (((Widgets.SidebarItem)selected_row).editablelabel);
                }
            });
        }

        public GLib.List<unowned Widgets.SidebarItem> get_rows () {
            return (GLib.List<unowned Widgets.SidebarItem>) this.get_children ();
        }

        public void clear_column () {
            foreach (Gtk.Widget item in this.get_children ()) {
                item.destroy ();
            }
            win.tm.save_notes ();
        }

        public void new_taskbox (MainWindow win, string title, string contents, string text, string color) {
            var taskbox = new Widgets.SidebarItem (win, title, contents, text, color);
            insert (taskbox, -1);
            win.tm.save_notes ();
            is_modified = true;
        }

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }
    }
}
