require_dependency Rails.root.join('app', 'controllers', 'proposals_controller').to_s

class ProposalsController < ApplicationController

  private

    def load_featured
      nil
    end
end
