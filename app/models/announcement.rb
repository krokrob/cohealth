class Announcement
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes.deep_transform_keys { |key| key.parameterize.underscore.downcase.to_sym }
  end

  def method_missing(method, *args, &block)
    @attributes[method]
  end

  def siren
    @attributes[:n_rcs].delete(' ').match(/\d+/)[0]
  end

  def rcs
    @attributes[:n_rcs].match(/ RCS (.+)/)[1]
  end

  def previous_siren
    @attributes[:precedent_s_proprietaire_s][:n_identification].delete(' ').match(/\d+/)[0]
  end
end
