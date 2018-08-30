require_dependency Rails.root.join('app', 'models', 'verification', 'management', 'document').to_s

class Verification::Management::Document

  def in_census?
    response = CensusvaApi.new.call(document_type, document_number)
    response.valid? && valid_age?(response)
  end

  def under_age?(response)
    response.date_of_birth.blank? || Age.in_years(response.date_of_birth.to_date) < User.minimum_required_age
  end

end
