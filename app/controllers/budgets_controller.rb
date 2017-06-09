class BudgetsController < ApplicationController
  include FeatureFlags
  feature_flag :budgets

  load_and_authorize_resource
  before_action :set_default_budget_filter, only: :show
  has_filters %w{not_unfeasible feasible unfeasible unselected selected}, only: :show

  respond_to :html, :js

  def show
    if @budget.groups.count == 1
      redirect_to budget_group_path(@budget, @budget.groups[0])
    end

  end

  def index
    @budgets = @budgets.order(:created_at)
    if @budgets.count == 1
      redirect_to @budgets[0]
    end
  end

end
