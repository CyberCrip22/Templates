module GRE
  class Task
    attr_accessor :id, :title, :description, :priority, :due_date, :completed, :created_at, :updated_at
    
    PRIORITIES = {
      high: "Alta",
      medium: "Média",
      low: "Baixa"
    }.freeze
    
    def initialize(attributes = {})
      @id = attributes[:id]
      @title = attributes[:title] || ""
      @description = attributes[:description] || ""
      @priority = attributes[:priority] || :medium
      @due_date = attributes[:due_date]
      @completed = attributes[:completed] || false
      @created_at = attributes[:created_at] || Time.now
      @updated_at = attributes[:updated_at] || Time.now
    end
    
    def completed?
      @completed
    end
    
    def overdue?
      return false unless @due_date
      @due_date < Date.today && !completed?
    end
    
    def to_hash
      {
        id: @id,
        title: @title,
        description: @description,
        priority: @priority,
        due_date: @due_date,
        completed: @completed,
        created_at: @created_at,
        updated_at: @updated_at
      }
    end
  end
end