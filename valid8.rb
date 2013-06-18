require 'active_model'

class SubscriptionRequest < Hash
  attr_accessor  :broadcasters
  include ActiveModel::Validations
  def initialize hsh
    merge! hsh
  end

  validate :is_labeled#, :contains_stuff

  def is_labeled
    errors.add(:base) unless has_key?('label')
  end

  def contains_stuff
    errors.add(:base) unless has_key?('parcel')
  end

  def extant_broadcaster
    errors.add(:base) unless @broadcasters.include? self['parcel']
  end
end

