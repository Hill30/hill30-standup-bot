class CreateTimesheets < ActiveRecord::Migration
  def change
    create_table :timesheets do |t|
      t.integer :user_id
      t.string :description
      t.datetime :created_at
      t.boolean :send_timesheet_remider, default: true

      t.timestamps null: false
    end
  end
end
