class CreateSchedules < ActiveRecord::Migration[7.2]
  def change
    create_table :schedules do |t|
      t.string :title, null: false, default: "練習会"
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.string :location
      t.text :description

      t.timestamps
    end
  end
end
