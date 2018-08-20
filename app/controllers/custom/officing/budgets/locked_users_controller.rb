class Officing::Budgets::LockedUsersController < Officing::BaseController

  def index
    @locked_user = Budget::LockedUser.new()
  end

  def create
    if @locked_user = Budget::LockedUser.create(locked_user_params)
      redirect_to officing_budgets_locked_user_path(@locked_user), notice: t('officing.locked_users.create.notice')
    else
      flash.now[:error] = t('officing.locked_users.create.error')
      render :preview
    end
  end

  def show
    @locked_user = Budget::LockedUser.find(params[:id])
  end

  def preview
    byebug
    params[:budget_locked_user][:document_number].upcase
    @locked_user = Budget::LockedUser.new(locked_user_params)
    @already_locked = false
    if @locked_user.valid?
      old_locked_user = Budget::LockedUser.find_by(
        budget_id: locked_user_params[:budget_id],
        document_type: locked_user_params[:document_type],
        document_number: locked_user_params[:document_number])

      if old_locked_user.present?
        @already_locked = true
        @locked_time = old_locked_user.created_at
      else
        document_verification = Verification::Management::Document.new(document_verification_params)
        if document_verification.valid?
          @in_census = false
          if document_verification.in_census?
            @in_census = true
          end
          @has_voted = false
          if document_verification.user?
            @has_voted = Vote
                          .where(voter: document_verification.user)
                          .where(votable_id: @locked_user.budget.investment_ids)
                          .count > 0
          end
        end
      end
    else
      render :index
    end
  end

  private
    def document_verification_params
      params.require(:budget_locked_user).except(:budget_id).permit(:document_type, :document_number)
    end

    def locked_user_params
      params.require(:budget_locked_user).permit(
        :document_type, :document_number, :budget_id
      )
    end
end
