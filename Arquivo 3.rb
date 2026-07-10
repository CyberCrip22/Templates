module GRE
  class TaskStore
    def initialize
      @db = SQLite3::Database.new("data/tasks.db")
      create_tables
    end
    
    def create_tables
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          priority TEXT DEFAULT 'medium',
          due_date DATE,
          completed BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      SQL
    end
    
    def all
      tasks = []
      @db.execute("SELECT * FROM tasks ORDER BY 
        CASE priority 
          WHEN 'high' THEN 1 
          WHEN 'medium' THEN 2 
          WHEN 'low' THEN 3 
        END, due_date") do |row|
        tasks << Task.new(
          id: row[0],
          title: row[1],
          description: row[2],
          priority: row[3].to_sym,
          due_date: row[4] ? Date.parse(row[4]) : nil,
          completed: row[5] == 1,
          created_at: Time.parse(row[6]),
          updated_at: Time.parse(row[7])
        )
      end
      tasks
    end
    
    def create(task)
      @db.execute(
        "INSERT INTO tasks (title, description, priority, due_date, completed) 
         VALUES (?, ?, ?, ?, ?)",
        [task.title, task.description, task.priority.to_s, 
         task.due_date&.to_s, task.completed? ? 1 : 0]
      )
      task.id = @db.last_insert_row_id
      task
    end
    
    def update(task)
      @db.execute(
        "UPDATE tasks SET 
          title = ?, 
          description = ?, 
          priority = ?, 
          due_date = ?, 
          completed = ?,
          updated_at = CURRENT_TIMESTAMP
         WHERE id = ?",
        [task.title, task.description, task.priority.to_s, 
         task.due_date&.to_s, task.completed? ? 1 : 0, task.id]
      )
    end
    
    def delete(id)
      @db.execute("DELETE FROM tasks WHERE id = ?", [id])
    end
    
    def search(query)
      all.select do |task|
        task.title.downcase.include?(query.downcase) ||
        task.description.to_s.downcase.include?(query.downcase)
      end
    end
  end
end