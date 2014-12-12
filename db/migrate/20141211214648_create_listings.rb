class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.integer :property_id

      t.text :url
      t.text :description
      t.text :listing_website_url

      t.float :area
      t.float :bedroom
      t.float :bathroom

      t.integer :price
      t.string :status

      t.string :state
      t.string :city
      t.string :neighborhood
      t.integer :zip
      t.string :street

      t.timestamps
    end
  end
end
