require "rails_helper"

RSpec.describe CodigosController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/codigos").to route_to("codigos#index")
    end

    it "routes to #new" do
      expect(:get => "/codigos/new").to route_to("codigos#new")
    end

    it "routes to #show" do
      expect(:get => "/codigos/1").to route_to("codigos#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/codigos/1/edit").to route_to("codigos#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/codigos").to route_to("codigos#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/codigos/1").to route_to("codigos#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/codigos/1").to route_to("codigos#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/codigos/1").to route_to("codigos#destroy", :id => "1")
    end

  end
end
