# frozen_string_literal: true

class BreweriesController < ApplicationController
  SORT_ORDER = { '+': :asc, '-': :desc }.freeze
  DDOS_ATTACK = ENV['DDOS_ATTACK'] == 'true'

  before_action :set_brewery, only: %i[show]
  before_action :track_analytics

  # FILTER: /breweries?by_city=san%20diego
  has_scope :by_city, only: :index
  # FILTER: /breweries?by_country=scotland
  has_scope :by_country, only: :index
  # FILTER /breweries?by_dist=38.8977,77.0365
  has_scope :by_dist, only: :index
  # FILTER /breweries?by_ids=1,2,3
  has_scope :by_ids, only: :index
  # FILTER: /breweries?by_name=almanac
  has_scope :by_name, only: :index
  # FILTER: /breweries?by_state=california
  has_scope :by_state, only: :index
  # FILTER /breweries?by_postal=44107
  has_scope :by_postal, only: :index
  # FILTER: /breweries?by_type=micro
  has_scope :by_type, only: :index

  # GET /breweries
  def index
    expires_in 1.day, public: true
    @breweries =
      apply_scopes(Brewery)
      .order(order_params)
      .page(params[:page])
      .per(params[:per_page])
    json_response(@breweries)
  end

  # GET /breweries/:id
  def show
    expires_in 1.day, public: true
    json_response(@brewery)
  end

  # GET /breweries/autocomplete
  def autocomplete
    expires_in 1.day, public: true

    if DDOS_ATTACK
      @breweries = { message: 'This endpoint is temporarily disabled.' }
      json_response(@breweries)
    else
      # Ignore pagination for autocomplete
      @breweries = Brewery.autocomplete(
        format_query(params[:query])
      ).page(1).per(15)
      json_response(@breweries.map { |b| { id: b.id, name: b.name } })
    end
  end

  # GET /breweries/search
  def search
    expires_in 1.day, public: true

    @breweries = if DDOS_ATTACK
                   { message: 'This endpoint is temporarily disabled.' }
                 else
                   Brewery.search_breweries(
                     format_query(params[:query])
                   ).page(params[:page]).per(params[:per_page])
                 end

    json_response(@breweries)
  end

  private

    # A list of the param names that can be used for ordering the model list.
    # For example it retrieves a list of breweries in descending order of type.
    # Within a specific type, names are ordered first
    #
    # GET /breweries?sort=-type,name
    # order_params # => { brewery_type: :desc, name: :asc }
    # Brewery.order(brewery_type: :desc, name: :asc)
    #
    def order_params
      return unless params[:sort]

      ordering = {}
      sorted_params = params[:sort].split(',')

      sorted_params.each do |attr|
        sort_sign = /^[+-]/.match?(attr) ? attr.slice!(0) : '+'
        attr = 'brewery_type' if attr == 'type'
        if Brewery.attribute_names.include?(attr)
          ordering[attr] = SORT_ORDER[sort_sign.to_sym]
        end
      end

      ordering
    end

    def set_brewery
      @brewery = Brewery.find(params[:id])
    end

    def track_analytics
      ahoy.track action_name, params
    end

    # Allow _ to be a separator
    def format_query(query)
      return query.gsub('_', ' ') unless query.nil?
    end
end
