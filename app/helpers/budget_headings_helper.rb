module BudgetHeadingsHelper

  def budget_heading_select_options(budget)
    budget.headings.order_by_id.map do |heading|
      [heading.name, heading.id]
    end
  end

end
