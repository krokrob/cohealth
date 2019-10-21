class Announcement

  def initialize(attributes)
    @attributes = attributes.deep_transform_keys { |key| key.parameterize.underscore.downcase.to_sym }
  end

  def method_missing(method, *args, &block)
    @attributes[method]
  end
end
