module MixTrainHelper
  def new_mix_train_url_from_names(source, target)
    source_dialect_id = Dialect.find_by(name: source.downcase)
    target_dialect_id = Dialect.find_by(name: target.downcase)
    url = new_mix_train_url(params: {n: 10, source_dialect_id: source_dialect_id, \
      target_dialect_id: target_dialect_id})
    cap = "[#{source.capitalize} >>> #{target.capitalize}]"
    link_to(cap, url)
  end

  def mix_train_create(train_list, user)
    data_request = {}
    train_list.each do |training|
      name = training[:name]
      params = training[:params].merge(current_user: user)
      data_request[name] ||= Set.new
      puts "creating new #{name} with #{params}"
      data_request[name].merge(name.constantize.create(params).map{|o| o.id})
    end
    return data_request
  end

  def mix_train_list(source, target, n)
    @@train_cache ||= {}
    key = "s=#{source}&t=#{target}&n=#{n}"
    if @@train_cache.key?(key)
      return @@train_cache[key]
    end
    source_dialect_id = (Dialect.find_by(name: source.downcase) || Dialect.find_by(id: source.to_i)).id
    target_dialect_id = (Dialect.find_by(name: target.downcase) || Dialect.find_by(id: target.to_i)).id
    kana_dialect_id = Dialect.find_by(name: 'kana')
    kanji_dialect_id = Dialect.find_by(name: 'kanji')
    name = 'PickWordInSet'
    @@i ||= 1
    pick_list =
      [{name: name, id: @@i = @@i + 1, params: {n: n, source_dialect_id: source_dialect_id, \
      target_dialect_id: target_dialect_id, option_dialect_id: source_dialect_id}},
      {name: name, id: @@i = @@i + 1, params: {n: n, source_dialect_id: source_dialect_id, \
      target_dialect_id: target_dialect_id, option_dialect_id: target_dialect_id}},
      {name: name, id: @@i = @@i + 1, params: {n: n, source_dialect_id: source_dialect_id, \
      target_dialect_id: target_dialect_id, option_dialect_id: kana_dialect_id}},
      {name: name, id: @@i = @@i + 1, params: {n: n, source_dialect_id: source_dialect_id, \
      target_dialect_id: kanji_dialect_id, option_dialect_id: source_dialect_id}},
      {name: name, id: @@i = @@i + 1, params: {n: n, source_dialect_id: source_dialect_id, \
      target_dialect_id: kanji_dialect_id, option_dialect_id: kanji_dialect_id}}]
    @@train_cache[key] = pick_list
    return pick_list
  end


end

#I probably need a pseudotable to support all those exircise types
#Idea of prob estimation for a multiple exercise types
#There is either a probability to be solved first or probability to be solved n-th estimated by probability of previous excercise
#probably estimate as difference in logodds to avoid issues with limtis
#some complexity index?
#sigmoid that describes intial complexity
#mey be wee need some sigmoid shift factor for all exercises types
# !consider not all exercises might be related directly to some words
# exercise instance probably has some rank and may be some conditions
#well currently we can just mop all exercices together giving them some kind of priority based on
#underlying utility and that's all for now
#that all you have been thinking for a half of hour to conclude to do almost nothing???
