# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Breweries API", type: :request do
  describe "GET /breweries" do
    context "when no params are passed" do
      before do
        create_list(:brewery, 25)
        get "/breweries"
      end

      # NB: Set in /config/initializers/kaminari_config.rb
      it "returns the default number of breweries" do
        expect(json).not_to be_empty
        expect(json.size).to eq(20)
      end

      it "returns status code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns Cache-Control headers" do
        expect(response.headers["Cache-Control"]).to eq(
          "max-age=86400, public"
        )
      end
    end

    context "when invalid params are passed" do
      before do
        create_list(:brewery, 25)
        get "/breweries", params: { page: "invalid", sort: "*bob" }
      end

      it "returns a status of 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the default number of breweries" do
        expect(json).not_to be_empty
        expect(json.size).to eq(20)
      end
    end

    context "when page param is passed" do
      before do
        create_list(:brewery, 25)
        get "/breweries", params: { page: 2 }
      end

      it "returns another page of breweries" do
        expect(json.size).to eq(5)
      end
    end

    context "when per_page param is passed" do
      before do
        create_list(:brewery, 55)
      end

      it "returns a limited number breweries" do
        get "/breweries", params: { per_page: 5 }
        expect(json.size).to eq(5)
      end

      # NB: Set in /config/initializers/kaminari_config.rb
      it "does not exceed the maximum number of breweries per page" do
        get "/breweries", params: { per_page: 55 }
        expect(json.size).to eq(50)
      end
    end

    context "when by_city param is passed" do
      before do
        create_list(:brewery, 8)
        create_list(:brewery, 2, city: "San Diego")
        get "/breweries", params: { by_city: "san Diego" }
      end

      it "returns a filtered list of breweries" do
        expect(json.size).to eq(2)
      end
    end

    context "when by_country param is passed" do
      before do
        create_list(:brewery, 3)
        create_list(:brewery, 2, country: "England")
        get "/breweries", params: { by_country: "England" }
      end

      it "returns a filtered list of breweries" do
        expect(json.size).to eq(2)
      end
    end

    context "when by_name param is passed" do
      before do
        create_list(:brewery, 8)
        create_list(:brewery, 2, name: "McHappy's Brewpub Extravaganza")
        get "/breweries", params: { by_name: "mchappy" }
      end

      it "returns a filtered list of breweries" do
        expect(json.size).to eq(2)
      end
    end

    context "when by_state param is passed" do
      before do
        create_list(:brewery, 2, state: "New York")
        create(:brewery, state: "California")
        create(:brewery, state: "Delaware")
      end

      it "returns a filtered list of breweries" do
        get "/breweries", params: { by_state: "california" }
        expect(json.size).to eq(1)
      end

      it "returns a filtered list of breweries with snake case" do
        get "/breweries", params: { by_state: "new_york" }
        expect(json.size).to eq(2)
      end

      it "does not return a filtered list of breweries with kebab case" do
        get "/breweries", params: { by_state: "new-york" }
        expect(json.size).to eq(0)
      end

      it "does not return a filtered list of breweries when abbreviation" do
        get "/breweries", params: { by_state: "ny" }
        expect(json.size).to eq(0)
      end

      it "does not return a filtered list of breweries when mispelled" do
        get "/breweries", params: { by_state: "delwar" }
        expect(json.size).to eq(0)
      end
    end

    context "when by_type param is passed" do
      before do
        create_list(:brewery, 3, brewery_type: "planned")
        get "/breweries", params: { by_type: "Planned" }
      end

      it "returns a filtered list of breweries" do
        expect(json.size).to eq(3)
      end
    end

    context "when postal param is passed" do
      before do
        create_list(:brewery, 5)
        create_list(:brewery, 3, postal_code: "44107")
        create_list(:brewery, 2, postal_code: "44107-5555")
        create_list(:brewery, 1, postal_code: "WC2N 5DU")
      end

      it "returns a filtered list of breweries for US postal codes" do
        get "/breweries", params: { by_postal: "44107" }
        expect(json.size).to eq(5)
      end

      it "returns a filtered list of breweries for US postal code ZIP+4" do
        get "/breweries", params: { by_postal: "44107-5555" }
        expect(json.size).to eq(2)
      end

      it "returns a filtered list of breweries for international postal codes" do
        get "/breweries", params: { by_postal: "WC2N" }
        expect(json.size).to eq(1)
      end
    end

    context "when sort param is passed" do
      before do
        create(
          :brewery,
          name: "Alesmith",
          brewery_type: "micro"
        )
        create(
          :brewery,
          name: "Ballast Point Brewing Company",
          brewery_type: "regional"
        )
        create(
          :brewery,
          name: "Circle 9 Brewing",
          brewery_type: "micro"
        )
        get "/breweries", params: { sort: "type,-name" }
      end

      it "returns a sorted list of breweries" do
        expect(json.map { |brewery| brewery["name"] }).to eq(
          [
            "Circle 9 Brewing",
            "Alesmith",
            "Ballast Point Brewing Company"
          ]
        )
      end
    end
  end

  describe "GET /breweries/search" do
    before do
      create_list(
        :brewery,
        1,
        name: "Bob's Brewing Co. - Athens, Ohio",
        state: "Ohio",
        city: "Athens"
      )
      create_list(
        :brewery,
        1,
        name: "Jane's Brewing Co. - Alb, NM",
        state: "New Mexico",
        city: "Albuquerque"
      )
      create_list(
        :brewery,
        1,
        name: "Old English Brewery",
        county_province: "East Sussex",
        country: "England"
      )
      create_list(:brewery, 1, state: "Ohio")
      create_list(:brewery, 1, city: "Athens", state: "Ohio")
    end

    context "when no params are passed" do
      before do
        get "/breweries/search"
      end

      it "returns a status of 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns no results" do
        expect(json).to be_empty
      end
    end

    context "when valid params are passed" do
      it "returns a status of 200" do
        get "/breweries/search", params: { query: "bob" }
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct number of breweries for 'bob'" do
        get "/breweries/search", params: { query: "bob" }
        expect(json).not_to be_empty
        expect(json.size).to eq(1)
      end

      it "returns the correct number of breweries for 'athens'" do
        get "/breweries/search", params: { query: "athens" }
        expect(json).not_to be_empty
        expect(json.size).to eq(2)
      end

      it "returns the correct number of breweries for 'ohio'" do
        get "/breweries/search", params: { query: "ohio" }
        expect(json).not_to be_empty
        expect(json.size).to eq(3)
      end

      it "returns the correct number of breweries for 'sussex'" do
        get "/breweries/search", params: { query: "sussex" }
        expect(json).not_to be_empty
        expect(json.size).to eq(1)
      end
    end
  end

  describe "GET /breweries/autocomplete" do
    before do
      create_list(
        :brewery,
        1,
        name: "Bob's Brewing Co. - Athens, Ohio",
        state: "Ohio",
        city: "Athens"
      )
      create_list(
        :brewery,
        1,
        name: "Jane's Brewing Co. - Alb, NM",
        state: "New Mexico",
        city: "Albuquerque"
      )
      create_list(:brewery, 1, state: "Ohio")
      create_list(:brewery, 1, city: "Athens", state: "Ohio")
    end

    context "when no params are passed" do
      before do
        get "/breweries/autocomplete"
      end

      it "returns a status of 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns no results" do
        expect(json).to be_empty
      end
    end

    context "when valid params are passed" do
      it "returns the correct number of breweries for 'bob'" do
        get "/breweries/autocomplete", params: { query: "bob" }
        expect(json).not_to be_empty
        expect(json.size).to eq(1)
      end

      it "returns the correct number of breweries for 'oh'" do
        get "/breweries/autocomplete", params: { query: "oh" }
        expect(json).not_to be_empty
        expect(json.size).to eq(3)
      end

      it "returns the correct number of breweries for 'al'" do
        get "/breweries/autocomplete", params: { query: "al" }
        expect(json).not_to be_empty
        expect(json.size).to eq(1)
      end
    end
  end

  describe "GET /breweries/:id" do
    let!(:brewery) { create(:brewery) }
    let(:brewery_id) { brewery.id }

    before { get "/breweries/#{brewery_id}" }

    context "when the record exists" do
      it "returns the brewery" do
        expect(json).not_to be_empty
        expect(json["id"]).to eq(brewery.id)
        expect(json["name"]).to eq(brewery.name)
        expect(json["brewery_type"]).to eq(brewery.brewery_type)
        expect(json["street"]).to eq(brewery.street)
        expect(json["address_2"]).to eq(brewery.address_2)
        expect(json["address_3"]).to eq(brewery.address_3)
        expect(json["city"]).to eq(brewery.city)
        expect(json["state"]).to eq(brewery.state)
        expect(json["county_province"]).to eq(brewery.county_province)
        expect(json["postal_code"]).to eq(brewery.postal_code)
        expect(json["country"]).to eq(brewery.country)
        # expect(json["tag_list"]).to include("dog-friendly", "patio")
      end

      it "returns status code 200" do
        expect(response).to have_http_status(200)
      end
    end

    context "when the record does not exist" do
      let(:brewery_id) { 100 }

      it "returns status code 404" do
        expect(response).to have_http_status(404)
      end

      it "returns a not found message" do
        expect(response.body).to match(/Couldn't find Brewery/)
      end
    end
  end

  describe "POST /breweries" do
    let(:valid_attributes) { { name: "Awesome Brewery" } }

    context "when the request is valid" do
      # NOTE: Keep for when adding authentication
      # it "creates a brewery" do
      #   expect(json["name"]).to eq("Awesome Brewery")
      # end
      #
      # it "returns status code 201" do
      #   expect(response).to have_http_status(201)
      # end

      it "returns returns a routing error" do
        expect { post "/breweries", params: valid_attributes }.to raise_error(
          ActionController::RoutingError
        )
      end
    end

    # NOTE: Keep for when adding authentication
    # context "when the request is invalid" do
    #   before { post "/breweries", params: { name: "" } }
    #
    #   it "returns status code 422" do
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   it "returns a validation failure message" do
    #     expect(response.body)
    #       .to match(/Validation failed: Name can't be blank/)
    #   end
    # end
  end

  describe "PUT /breweries/:id" do
    let!(:brewery) { create(:brewery) }
    let(:valid_attributes) { { name: "Another Brewery" } }

    context "when the record exists" do
      # NOTE: Keep for when adding authentication
      # before { put "/breweries/#{brewery.id}", params: valid_attributes }
      #
      # it "updates the record" do
      #   expect(response.body).to be_empty
      # end
      #
      # it "returns status code 204" do
      #   expect(response).to have_http_status(204)
      # end

      it "returns a routing error" do
        expect do
          put "/breweries/#{brewery.id}", params: valid_attributes
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe "DELETE /breweries/:id" do
    let!(:brewery) { create(:brewery) }
    let(:valid_attributes) { { name: "Another Brewery" } }

    # NOTE: Keep for when adding authentication
    # before { delete "/breweries/#{brewery.id}" }
    #
    # it "returns status code 204" do
    #   expect(response).to have_http_status(204)
    # end

    it "return a routing error" do
      expect { delete "/breweries/#{brewery.id}" }.to raise_error(
        ActionController::RoutingError
      )
    end
  end
end
