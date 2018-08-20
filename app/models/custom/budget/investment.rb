require_dependency Rails.root.join('app', 'models', 'budget', 'investment').to_s

class Budget
  class Investment < ActiveRecord::Base

    def permission_problem(user)
      return :not_logged_in unless user
      return :organization  if user.organization?
      return :not_verified  unless user.can?(:vote, Budget::Investment)
      return :user_locked if user_locked?(user)
      return nil
    end

    private

      def set_denormalized_ids
        self.group_id = self.heading.try(:group_id) if self.heading_id_changed?
        self.budget_id ||= self.heading.try(:group).try(:budget_id)
      end

      def user_locked?(user)
        # Comprobar si está bloqueado sólo para voto presencial
        Budget::LockedUser.where(document_type: user.document_type)
                          .where(document_number: user.document_number)
                          .where(budget_id: budget_id)
                          .count >= 1
      end
  end
end
