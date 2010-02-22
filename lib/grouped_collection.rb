module AssociationCollection
  class GroupedCollection
    attr_accessor :association
    attr_accessor :collection

    def initialize(association,collection)
      @association = association
      @collection = collection
    end

    def method_missing(method, *args)
      if association.respond_to?(method)
        if block_given?
          association.send(method, *args) { |*block_args| yield(*block_args) }
        else
          association.send(method, *args)
        end
      end
    end
  end

  def group_by(association,options={})
    reflection = @reflection.klass.class_name.tableize.to_sym
    GroupedCollection.send(:alias_method,reflection,:collection)
    options.stringify_keys!
    collection = []

    load_target unless loaded?
    @target.sort! {|a,b| a.send(options["sort"].to_sym) <=> b.send(options["sort"].to_sym)} unless options["sort"].nil?
    groups = @target.map {|o| o.send(association.to_sym)}.compact.uniq

    key = (association.to_s + '_id').to_sym if options["key"].nil?
    groups.each do |group|
      collection << GroupedCollection.new(group,@target.select {|o| o.send(key) == group.id})
    end

    options["group_sort"] = :name if options["group_sort"].nil?
    if options["group_sort"]
      collection.sort {|a,b| a.send(options["group_sort"].to_sym) <=> b.send(options["group_sort"].to_sym)}
    else
      collection
    end
  end
  
  :group_by
end

ActiveRecord::Associations::AssociationCollection.send(:include,AssociationCollection)