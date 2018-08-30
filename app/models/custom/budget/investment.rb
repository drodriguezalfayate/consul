require_dependency Rails.root.join('app', 'models', 'budget', 'investment').to_s

class Budget
  class Investment < ActiveRecord::Base

    has_many :physical_final_votes, as: :signable

    def permission_problem(user)
      return :not_logged_in unless user
      return :organization  if user.organization?
      return :not_verified  unless user.can?(:vote, Budget::Investment)
      return :user_locked if user_locked?(user)
      return nil
    end

    def reason_for_not_being_ballotable_by(user, ballot)
      return permission_problem(user)    if permission_problem?(user)
      return :not_selected               unless selected?
      return :no_ballots_allowed         unless budget.balloting?
      return :different_heading_assigned unless ballot.valid_heading?(heading)
      return :not_enough_money_html      if ballot.present? && !enough_money?(ballot)
      return :user_locked                if user_locked?(user)
    end

    def physical_final_votes_count
      physical_final_votes.to_a.sum(&:total_votes)
    end

    def final_total_votes
      ballot_lines_count + physical_final_votes_count
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
