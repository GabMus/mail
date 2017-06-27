// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Mail.ConversationListItem : Gtk.ListBoxRow {
    private const string UNREAD_MESSAGE_CLASS_CSS = """
        .unread-message {
            font-weight: bolder;
        }
    """;


    public Camel.FolderThreadNode node { get; private set; }
    Gtk.Label source;
    Gtk.Label messages;
    Gtk.Label topic;
    Gtk.Label date;
    public ConversationListItem (Camel.FolderThreadNode node) {
        this.node = node;
        var num_messages = count_thread_messages (node);
        messages.label = num_messages > 1 ? "%u".printf(num_messages) : null;
        messages.no_show_all = num_messages <= 1;
        messages.visible = num_messages > 1;
        topic.label = node.message.subject;
        var from_parts = node.message.from.split ("<");
        var from_name = GLib.Markup.escape_text (from_parts[0].strip ());
        source.label = "<span size=\"larger\">%s</span>".printf (from_name);
        if (!(Camel.MessageFlags.SEEN in (int)node.message.flags)) {
            get_style_context ().add_class ("unread-message");
        }
        
        var received_date = new DateTime.from_unix_utc (node.message.date_received);
        date.label = Date.pretty_print (received_date, GearyApplication.instance.config.clock_format);
    }

    construct {
        source = new Gtk.Label (null);
        source.hexpand = true;
        source.ellipsize = Pango.EllipsizeMode.END;
        source.xalign = 0;
        source.use_markup = true;
        messages = new Gtk.Label (null);
        messages.halign = Gtk.Align.END;
        var messages_style = messages.get_style_context ();
        messages_style.add_class (Granite.StyleClass.BADGE);
        messages_style.add_class ("source-list");
        topic = new Gtk.Label (null);
        topic.hexpand = true;
        topic.ellipsize = Pango.EllipsizeMode.END;
        topic.xalign = 0;
        date = new Gtk.Label (null);
        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.attach (source, 0, 0, 1, 1);
        grid.attach (date, 1, 0, 2, 1);
        grid.attach (topic, 0, 1, 2, 1);
        grid.attach (messages, 2, 1, 1, 1);
        add (grid);

        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (UNREAD_MESSAGE_CLASS_CSS);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            critical (e.message);
        }

        show_all ();
    }

    private static uint count_thread_messages (Camel.FolderThreadNode node) {
        unowned Camel.FolderThreadNode? child = (Camel.FolderThreadNode?) node.child;
        uint i = 1;
        while (child != null) {
            i += count_thread_messages (child);
            child = (Camel.FolderThreadNode?) child.next;
        }

        return i;
    }
}