class DataPreloadService
  def initialize(request_data, recursive: false)
    @request_data = request_data
    @recursive = recursive
    @response_data = {}
    @requested_data = request_data.each.map { |type, array| [type, array.to_set] }.to_h
    @request_data_next = {}
  end

  def self.fetch_data(request_data, recursive: false)
    DataPreloadService.new(request_data,recursive: recursive).fetch_data
  end

  def fetch_data
    process_queue while @request_data.each_value.any?(&:any?)
    @response_data
  end

  private

  def process_queue
    if @recursive
      queue_related_objects('ClassModel', #add all also all requested types
         @request_data.each.map{|type,ids|type}.reject{|n|n=='ClassModel'})
    end
    @request_data.each do |current_type, ids|
      if current_type == 'ClassModel'
        puts "|current_type, ids| #{current_type}, #{ids}"
        process_class_models(ids)
        next
      end
      model_class = current_type.constantize
      records = model_class.where(id: ids)
      process_records(records, model_class, current_type)
      # Queue eligible `belongs_to` associations
      queue_belongs_to_associations(records, model_class)
    end
    # Update queue for the next cycle
    @request_data = @request_data_next
    @request_data_next = {}
  end

  def process_class_models(ids)
    model_hash = @response_data['ClassModel'] ||= {}
    ids.each do |class_name|
      model_hash[class_name] = get_belongs_to_references(class_name)
    end
  end

  def get_belongs_to_references(model_name)
    puts "get_belongs_to_references constantize model_name = #{model_name}"
    # Convert the model name to a class
    model_class = model_name.constantize
    # Initialize a hash to store references and types
    references = {}
    # Iterate through all belongs_to associations
    model_class.reflect_on_all_associations(:belongs_to).each do |association|
      # Store the association name and class name in the references hash
      references[association.name] = association.class_name
    end
    puts "preloadable_fake_references for #{model_name} are #{model_class.preloadable_fake_references}"
    references.merge!(model_class.preloadable_fake_references)
    if model_class.is_container
      model_class.contained_associations.each do |association_label|
        association = association_from_label(model_class, association_label)
        references[association_label.to_s.singularize] = association.class_name
      end
    end
    puts "all_references for #{model_name} are #{references}"
    references
  end

  def process_records(records, model_class, current_type)
    records_hash = records.each_with_object({}) do |record, hash|
      record_data = record.preloadable_attributes
      if model_class.is_container
          model_class.contained_associations.each do |association_label|
          association = association_from_label(model_class, association_label)
          related_ids = record.public_send(association_label).pluck(:id)
          record_data["#{association_label.to_s.singularize}_ids"] = related_ids
          # Queue related objects if recursive loading is enabled o
          # or they are containers (consider separate marker to force preload)
          class_name = association.class_name
          if class_name.constantize.is_container || @recursive
            queue_related_objects(class_name, related_ids)
            queue_related_objects('ClassModel', [class_name])
          end
        end
      end

      hash[record.id] = record_data
    end

    # Merge the result into the main response data
    @response_data[current_type] ||= {}
    @response_data[current_type].merge!(records_hash)
  end

  def association_from_label(model_class, association_name)
    model_class.reflect_on_association(association_name.to_sym)
  end

  def build_record_hash(model_class, records, associations)

  end

  def queue_belongs_to_associations(records, model_class)
    model_class.reflect_on_all_associations(:belongs_to).each do |association|
      # currently autoload all containers even when not recoursive
      # but consider using separate force preload marker
      key = association.foreign_key
      class_name =association.class_name
      if(class_name.constantize.is_container || @recursive)
        associated_ids = records.pluck(key).compact.uniq
        queue_related_objects(class_name, associated_ids)
        queue_related_objects('ClassModel', [class_name])
      end
    end

    model_class.preloadable_fake_references.each do |key,class_name|
      # currently autoload all containers even when not recoursive
      # but consider using separate force preload marker
      ref_class = class_name.constantize;
      if(ref_class.is_container || @recursive)
        associated_ids = records.map{|r| r.preloadable_attributes[(key.to_s + "_id").to_sym]}.compact.uniq
        puts "preloadable_fake_references plucked is #{associated_ids}"
        queue_related_objects(class_name, associated_ids)
        queue_related_objects('ClassModel', [class_name])
      end
    end

  end

  def queue_related_objects(class_name, related_ids)
    class_key = class_name.to_s
    @requested_data[class_key] ||= Set.new
    # Filter out already requested IDs to prevent redundant queries
    new_ids = related_ids.reject { |id| @requested_data[class_key].include?(id) }
    @request_data_next[class_key] ||= Set.new
    @request_data_next[class_key].merge(new_ids)
    @requested_data[class_key].merge(new_ids)
  end
end
