class Admin::PhysicalFinalVotesController < Admin::BaseController

  def index
    @physical_final_votes = PhysicalFinalVote.all
  end

  def new
    @physical_final_vote = PhysicalFinalVote.new
  end

  def create
    @physical_final_vote = PhysicalFinalVote.new(physical_final_vote_params)
    if @physical_final_vote.save
      redirect_to [:admin, @physical_final_vote], notice: I18n.t('flash.actions.create.physical_final_vote')
    else
      render :new
    end
  end

  def show
    @physical_final_vote = PhysicalFinalVote.find(params[:id])
  end

  private

    def physical_final_vote_params
      params.require(:physical_final_vote).permit(:signable_type, :signable_id, :total_votes, :booth)
    end

end