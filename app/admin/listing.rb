ActiveAdmin.register Listing do
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
end
