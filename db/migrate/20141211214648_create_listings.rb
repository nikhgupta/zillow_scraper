class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.integer :property_id
      t.text :description
      t.text :link
      t.integer :area
      t.integer :bedroom
      t.integer :bathroom
      t.integer :cost
      t.string :state
      t.integer :zip
      t.string :street
      t.string :flat

      t.timestamps
    end
  end
end
