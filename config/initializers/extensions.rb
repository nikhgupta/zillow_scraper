pattern = Rails.root.join("lib", "extensions", "**", "*.rb")
Dir.glob(pattern).each{|file| require file}
