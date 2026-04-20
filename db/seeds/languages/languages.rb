csv_text = File.read(Rails.root.join('db', 'seeds', 'languages', 'languages.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  unless Language.where(name:row['name']).exists?
      language = Language.new
      language.name = row['name']
      language.save
  end
  unless Dialect.where(name:row['name']).exists?
      language = Language.find_by(name:row['name'])
      dialect = Dialect.new
      dialect.name = row['name']
      dialect.language_id = language.id
      dialect.save
  end
end
zero_language = Language.find_or_create_by!(id:0)
puts 'languages are finished'

csv_text = File.read(Rails.root.join('db', 'seeds', 'languages', 'dialects.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  language = Language.find_by(name:row['language'])
  unless Dialect.where(name:row['dialect']).exists?
      dialect = Dialect.new
      dialect.name = row['dialect']
      dialect.language_id = language.id
      dialect.save
  end
end
zero_dialect = Dialect.find_or_create_by!(id:0, language_id:0)
puts 'dialects are finished'
