require 'rails_helper'

RSpec.describe "Codigos", type: :request do
  describe "GET /codigos" do
    it "works! (now write some real specs)" do
      get codigos_path
      expect(response).to have_http_status(200)
    end
  end
end
