require 'csv'

csv_text = File.read(Rails.root.join('db', 'seeds', 'users','users.csv'))
csv_text.gsub! '"', ''
csv_text.gsub! ' ', ''
csv = CSV.parse(csv_text, :headers => true, :encoding => 'UTF-8', :col_sep => '	')
csv.each do |row|
  unless User.where(name:row['name']).exists?
      puts "regenerate user #{row['name']}"
      user = User.new
      user.id = row['id']
      user.name = row['name']
      user.email = row['email']
      user.downame = row['downame']
      user.activated = row['activated']
      user.password_digest = row['password_digest']
      result = user.save
      puts "gen res #{result}: #{user.errors.to_json}"
  end
end
puts 'users are finished'
User.all.each do |user|
  unless user.activated
    puts "activate user #{user.name}"
    user.update_attribute(:activated, true)
  end
end
puts 'users are activated'
