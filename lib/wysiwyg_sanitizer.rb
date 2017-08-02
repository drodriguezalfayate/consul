class WYSIWYGSanitizer

  ALLOWED_TAGS = %w(p ul ol li strong em u s)
  ALLOWED_TAGS_ADMIN = %w(p ul ol li strong em u s a)
  ALLOWED_ATTRIBUTES = []
  ALLOWED_ATTRIBUTES_ADMIN = %w(href target)

  def sanitize(html)
    ActionController::Base.helpers.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end

  def sanitize_admin(html)
  	ActionController::Base.helpers.sanitize(html, tags: ALLOWED_TAGS_ADMIN, attributes: ALLOWED_ATTRIBUTES_ADMIN)
  end

end
