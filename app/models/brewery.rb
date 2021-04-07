# frozen_string_literal: true

class Brewery < ApplicationRecord
  include PgSearch::Model

  multisearchable against: %i[name city state county_province country]

  pg_search_scope :search_breweries,
                  against: %i[name city state county_province country],
                  using: %i[tsearch trigram]
  pg_search_scope :autocomplete,
                  against: %i[name city state county_province country],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.1 }
                  }

  geocoded_by :address
  after_validation :geocode

  acts_as_mappable lat_column_name: :latitude,
                   lng_column_name: :longitude

  validates :city, presence: true
  validates :country, presence: true
  validates :name, presence: true
  validates :obdb_id, presence: true, uniqueness: true
  validates :state, presence: true

  scope :by_city, ->(city) { where('lower(city) LIKE ?', "%#{city.downcase}%") }
  scope :by_country, lambda { |country|
    where('lower(country) = ?', country.downcase)
  }
  scope :by_dist, lambda { |coords|
    by_distance(origin: coords.split(',').map(&:to_f).first(2))
  }
  scope :by_ids, ->(ids) { where(id: ids.split(',')) }
  scope :by_name, ->(name) { where('lower(name) LIKE ?', "%#{name.downcase}%") }
  scope :by_postal, ->(postal) { where('postal_code LIKE ?', "#{postal}%") }
  scope :by_state, ->(state) { where('lower(state) LIKE ?', state.downcase) }
  scope :by_type, ->(type) { where('lower(brewery_type) = ?', type.downcase) }

  def address
    [street, city, state, country].join(', ')
  end
end
