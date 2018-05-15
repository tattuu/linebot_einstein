class CreateResults < ActiveRecord::Migration[5.2]
  def change
    create_table :results do |t|
      t.text :content

      t.timestamps
    end
  end
end
