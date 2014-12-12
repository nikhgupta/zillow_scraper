class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.integer :property_id

      t.text :url
      t.string :title
      t.text :description
      t.text :realtor_url
      t.string :realtor_title

      t.float :area
      t.float :bedroom
      t.float :bathroom

      t.integer :price
      t.string :status

      t.string :state
      t.string :city
      t.string :neighborhood
      t.string :zip
      t.string :street

      t.timestamps
    end
  end
end
