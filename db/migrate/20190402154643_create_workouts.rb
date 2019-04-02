class CreateWorkouts < ActiveRecord::Migration[5.2]
  def change
    create_table :workouts do |t|
      t.uuid :uuid
      t.datetime :date
      t.jsonb :exercises

      t.timestamps
    end
  end
end
