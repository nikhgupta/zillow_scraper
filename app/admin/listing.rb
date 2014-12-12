ActiveAdmin.register Listing do
  menu priority: 3
  decorate_with ListingDecorator
  actions :all, except: [:new, :create, :update, :edit, :destroy]

  index do
    selectable_column

    column(:listing, sortable: :url){|listing| listing.link}
    # column :neighborhood
    column(:realtor, sortable: :realtor_url){|listing| listing.realtor_link}
    column(:bedroom, sortable: :bedroom){|listing| listing.bedroom(nil)}
    column(:bathroom, sortable: :bathroom){|listing| listing.bathroom(nil)}
    column :area, sortable: :area
    column :status
    column :price, sortable: :price

    actions
  end

  show do |listing|
    attributes_table do
      row :property_id
      row :listing
      row :realtor
      row :description
      row :facts
      row :price_with_status
      row :address
      row :updated
    end

    active_admin_comments
  end

  csv do
    column :property_id

    column :url
    column :title
    column :description

    column :realtor_url
    column :realtor_title

    column :area
    column :bedroom
    column :bathroom

    column :price
    column :status

    column :street
    column :neighborhood
    column :city
    column :state
    column :zip

    column :updated_at
  end

  action_item :scraper, if: proc{ scraper_running? } do
    link_to "Stop Scraper", scraping_task_stop_path, method: :post
  end

  action_item :scraper, if: proc{ scraper_stopped? } do
    link_to "Run Scraper", scraping_task_start_path, method: :post
  end

  action_item :purge do
    link_to "Delete Saved Listings", purge_listings_path, method: :post,
      data: { confirm: "Are you sure you want to delete all existing listings from database?" }
  end

  collection_action :purge, method: :post do
    Listing.delete_all
    redirect_to listings_path, notice: "Deleted all existing listings from database."
  end
end
