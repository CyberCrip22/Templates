module GRE
  class MainWindow < Gtk::ApplicationWindow
    def initialize(application)
      super(application)
      @task_store = TaskStore.new
      
      set_title("GRE - Gerenciador de Tarefas")
      set_default_size(800, 600)
      set_window_position(:center)
      
      setup_ui
      load_tasks
    end
    
    private
    
    def setup_ui
      # Container principal
      vbox = Gtk::Box.new(:vertical, 5)
      
      # Barra de ferramentas
      toolbar = create_toolbar
      vbox.pack_start(toolbar, expand: false, fill: true, padding: 5)
      
      # Campo de busca
      search_box = create_search_box
      vbox.pack_start(search_box, expand: false, fill: true, padding: 5)
      
      # Área de tarefas
      @task_container = Gtk::Box.new(:vertical, 5)
      scrolled = Gtk::ScrolledWindow.new
      scrolled.set_policy(:automatic, :automatic)
      scrolled.add(@task_container)
      vbox.pack_start(scrolled, expand: true, fill: true, padding: 5)
      
      # Barra de status
      @status_label = Gtk::Label.new("Total: 0 tarefas | Pendentes: 0")
      vbox.pack_start(@status_label, expand: false, fill: true, padding: 5)
      
      add(vbox)
    end
    
    def create_toolbar
      toolbar = Gtk::Box.new(:horizontal, 5)
      
      btn_add = Gtk::Button.new(label: "➕ Nova Tarefa")
      btn_add.signal_connect("clicked") { show_task_dialog }
      
      btn_refresh = Gtk::Button.new(label: "↻ Atualizar")
      btn_refresh.signal_connect("clicked") { load_tasks }
      
      toolbar.pack_start(btn_add, expand: false, fill: false, padding: 0)
      toolbar.pack_start(btn_refresh, expand: false, fill: false, padding: 0)
      
      toolbar
    end
    
    def create_search_box
      hbox = Gtk::Box.new(:horizontal, 5)
      
      entry = Gtk::Entry.new
      entry.placeholder_text = "Buscar tarefas..."
      entry.signal_connect("changed") do |widget|
        search_tasks(widget.text)
      end
      
      hbox.pack_start(Gtk::Label.new("Buscar:"), expand: false, fill: false, padding: 0)
      hbox.pack_start(entry, expand: true, fill: true, padding: 0)
      
      hbox
    end
    
    def create_task_widget(task)
      frame = Gtk::Frame.new
      frame.set_shadow_type(:etched_in)
      
      hbox = Gtk::Box.new(:horizontal, 10)
      
      # Checkbox de conclusão
      check = Gtk::CheckButton.new
      check.active = task.completed?
      check.signal_connect("toggled") do
        task.completed = check.active?
        @task_store.update(task)
        update_task_display(frame, task)
        update_status
      end
      
      # Informações da tarefa
      vbox = Gtk::Box.new(:vertical, 5)
      
      title_label = Gtk::Label.new
      title_label.set_markup("<b>#{escape_markup(task.title)}</b>")
      title_label.xalign = 0
      
      desc_label = Gtk::Label.new(task.description)
      desc_label.xalign = 0
      desc_label.ellipsize = :end
      
      # Informações adicionais
      info_box = Gtk::Box.new(:horizontal, 10)
      
      priority_label = Gtk::Label.new("Prioridade: #{Task::PRIORITIES[task.priority]}")
      due_label = Gtk::Label.new("Vencimento: #{task.due_date || 'Sem data'}")
      
      if task.overdue?
        due_label.set_markup("<span foreground='red'>Vencido: #{task.due_date}</span>")
      end
      
      info_box.pack_start(priority_label, expand: false, fill: false, padding: 0)
      info_box.pack_start(due_label, expand: false, fill: false, padding: 0)
      
      vbox.pack_start(title_label, expand: false, fill: true, padding: 0)
      vbox.pack_start(desc_label, expand: false, fill: true, padding: 0)
      vbox.pack_start(info_box, expand: false, fill: true, padding: 0)
      
      # Botões de ação
      btn_box = Gtk::Box.new(:vertical, 5)
      
      btn_edit = Gtk::Button.new(label: "✏️")
      btn_edit.signal_connect("clicked") { show_task_dialog(task) }
      
      btn_delete = Gtk::Button.new(label: "🗑️")
      btn_delete.signal_connect("clicked") do
        if confirm_dialog("Excluir tarefa?", "Deseja realmente excluir esta tarefa?")
          @task_store.delete(task.id)
          frame.destroy
          update_status
        end
      end
      
      btn_box.pack_start(btn_edit, expand: false, fill: false, padding: 0)
      btn_box.pack_start(btn_delete, expand: false, fill: false, padding: 0)
      
      hbox.pack_start(check, expand: false, fill: false, padding: 10)
      hbox.pack_start(vbox, expand: true, fill: true, padding: 0)
      hbox.pack_start(btn_box, expand: false, fill: false, padding: 10)
      
      frame.add(hbox)
      update_task_display(frame, task)
      
      frame
    end
    
    def update_task_display(frame, task)
      style_context = frame.style_context
      style_context.remove_class("task-completed")
      style_context.remove_class("task-pending")
      style_context.remove_class("priority-high")
      style_context.remove_class("priority-medium")
      style_context.remove_class("priority-low")
      
      if task.completed?
        style_context.add_class("task-completed")
      else
        style_context.add_class("task-pending")
      end
      
      style_context.add_class("priority-#{task.priority}")
    end
    
    def show_task_dialog(task = nil)
      dialog = Gtk::Dialog.new(
        title: task ? "Editar Tarefa" : "Nova Tarefa",
        parent: self,
        flags: :modal,
        buttons: [
          [Gtk::Stock::CANCEL, :cancel],
          [Gtk::Stock::OK, :ok]
        ]
      )
      
      # Formulário
      content = dialog.child
      
      grid = Gtk::Grid.new
      grid.row_spacing = 10
      grid.column_spacing = 10
      grid.margin = 10
      
      # Título
      grid.attach(Gtk::Label.new("Título:"), 0, 0, 1, 1)
      title_entry = Gtk::Entry.new
      title_entry.text = task.title if task
      title_entry.width_chars = 30
      grid.attach(title_entry, 1, 0, 2, 1)
      
      # Descrição
      grid.attach(Gtk::Label.new("Descrição:"), 0, 1, 1, 1)
      desc_text = Gtk::TextView.new
      desc_text.buffer.text = task.description if task
      desc_scrolled = Gtk::ScrolledWindow.new
      desc_scrolled.set_policy(:automatic, :automatic)
      desc_scrolled.set_size_request(-1, 100)
      desc_scrolled.add(desc_text)
      grid.attach(desc_scrolled, 1, 1, 2, 1)
      
      # Prioridade
      grid.attach(Gtk::Label.new("Prioridade:"), 0, 2, 1, 1)
      priority_combo = Gtk::ComboBoxText.new
      Task::PRIORITIES.each { |key, value| priority_combo.append(key.to_s, value) }
      priority_combo.active_id = task ? task.priority.to_s : "medium"
      grid.attach(priority_combo, 1, 2, 1, 1)
      
      # Data de vencimento
      grid.attach(Gtk::Label.new("Vencimento:"), 0, 3, 1, 1)
      date_entry = Gtk::Entry.new
      date_entry.text = task.due_date.to_s if task&.due_date
      date_entry.placeholder_text = "YYYY-MM-DD"
      grid.attach(date_entry, 1, 3, 1, 1)
      
      content.pack_start(grid, expand: true, fill: true, padding: 0)
      dialog.show_all
      
      if dialog.run == :ok
        new_task = task || Task.new
        new_task.title = title_entry.text
        new_task.description = desc_text.buffer.text
        new_task.priority = priority_combo.active_id.to_sym
        
        if !date_entry.text.empty?
          begin
            new_task.due_date = Date.parse(date_entry.text)
          rescue
            show_error("Data inválida! Use o formato YYYY-MM-DD")
          end
        end
        
        if task
          @task_store.update(new_task)
        else
          @task_store.create(new_task)
        end
        
        load_tasks
      end
      
      dialog.destroy
    end
    
    def load_tasks
      @task_container.children.each(&:destroy)
      
      @task_store.all.each do |task|
        @task_container.pack_start(create_task_widget(task), expand: false, fill: true, padding: 5)
      end
      
      @task_container.show_all
      update_status
    end
    
    def search_tasks(query)
      @task_container.children.each(&:destroy)
      
      tasks = query.empty? ? @task_store.all : @task_store.search(query)
      
      tasks.each do |task|
        @task_container.pack_start(create_task_widget(task), expand: false, fill: true, padding: 5)
      end
      
      @task_container.show_all
      update_status(tasks)
    end
    
    def update_status(tasks = nil)
      tasks ||= @task_store.all
      total = tasks.size
      pending = tasks.count { |t| !t.completed? }
      
      @status_label.text = "Total: #{total} tarefas | Pendentes: #{pending}"
    end
    
    def confirm_dialog(title, message)
      dialog = Gtk::MessageDialog.new(
        parent: self,
        flags: :modal,
        type: :question,
        buttons: :yes_no,
        message: message
      )
      dialog.title = title
      
      result = dialog.run == :yes
      dialog.destroy
      result
    end
    
    def show_error(message)
      dialog = Gtk::MessageDialog.new(
        parent: self,
        flags: :modal,
        type: :error,
        buttons: :ok,
        message: message
      )
      dialog.run
      dialog.destroy
    end
    
    def escape_markup(text)
      GLib.markup_escape_text(text)
    end
  end
end