class Announcement
  def initialize(attributes)
    @attributes = attributes
  end

  def [](key)
    @attributes[key]
  end
end
