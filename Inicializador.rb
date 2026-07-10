#!/usr/bin/env ruby
# encoding: UTF-8

require 'gtk3'
require 'sqlite3'
require_relative '../lib/gre'

# Inicializar CSS
def load_css
  css = Gtk::CssProvider.new
  css.load(data: <<-CSS)
    .task-completed {
      color: #888;
      text-decoration: line-through;
    }
    .task-pending {
      color: #333;
      font-weight: bold;
    }
    .priority-high {
      background-color: #ffcccc;
    }
    .priority-medium {
      background-color: #ffffcc;
    }
    .priority-low {
      background-color: #ccffcc;
    }
  CSS
  
  Gtk::StyleContext.add_provider_for_screen(
    Gtk::Window.default_screen,
    css,
    Gtk::StyleProvider::PRIORITY_USER
  )
end

# Iniciar aplicação
app = Gtk::Application.new("com.gre.taskmanager", :flags_none)

app.signal_connect("activate") do |application|
  load_css
  window = GRE::MainWindow.new(application)
  window.show_all
end

app.run