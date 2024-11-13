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
    @request_data.each do |current_type, ids|
      puts ("process_queue try constantize #{current_type}")
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

  def process_records(records, model_class, current_type)
    records_hash = records.each_with_object({}) do |record, hash|
      record_data = record.preloadable_attributes

      if model_class.is_container
        model_class.contained_associations.each do |association|
          related_ids = record.public_send(association).pluck(:id)
          record_data["#{association.to_s.singularize}_ids"] = related_ids
          # Queue related objects if recursive loading is enabled o
          # or they are containers (consider separate marker to force preload)
          class_name = association.to_s.singularize.capitalize
          if class_name.constantize.is_container || @recursive
            queue_related_objects(class_name, related_ids)
          end
        end
      end

      hash[record.id] = record_data
    end

    # Merge the result into the main response data
    @response_data[current_type] ||= {}
    @response_data[current_type].merge!(records_hash)
  end

  def build_record_hash(model_class, records, associations)

  end

  def queue_belongs_to_associations(records, model_class)
    model_class.reflect_on_all_associations(:belongs_to).each do |association|
      # currently autoload all containers even when not recoursive
      # but consider using separate force preload marker
      if(association.class_name.constantize.is_container || @recursive)
        associated_ids = records.pluck(association.foreign_key).compact.uniq
        queue_related_objects(association.class_name, associated_ids)
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
