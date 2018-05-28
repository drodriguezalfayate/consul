class CodigosController < ApplicationController

  skip_before_filter :verify_authenticity_token
#  load_and_authorize_resource
  skip_authorization_check :only => [:api, :create, :new, :solicitar, :comprobar_datos]
  

  # POST /codigos/api
  def api

    if Codigo.exists?(clave: params[:clave])

      @usuario = Codigo.find_by(clave: params[:clave])
      @acceso = Digest::SHA1.hexdigest( @usuario.valor )
      
      if @acceso.to_s == params[:valor]
        render json: @usuario, :except => [:valor]
      else
        error_datos()
      end

    else
      error_datos()
    end
  end

  def solicitar
    @residence = Verification::Residenceva.new
  end

  def comprobar_datos
    document_type = residence_params[:document_type]
    document_number = residence_params[:document_number].gsub(/[^a-z0-9]+/i, "").upcase
    postal_code = residence_params[:postal_code]
    date_of_birth = Date.new(residence_params['date_of_birth(1i)'].to_i, residence_params['date_of_birth(2i)'].to_i, residence_params['date_of_birth(3i)'].to_i) rescue nil
    @error = nil

    if verify_recaptcha && document_type.present? && document_number.present? && postal_code.present? && date_of_birth.present?
      @census_api_response = CensusvaApi.new.call(residence_params[:document_type], document_number)

      if postal_code.start_with?('47') && @census_api_response.valid? && @census_api_response.postal_code == postal_code && @census_api_response.date_of_birth == date_of_birth.strftime("%Y%m%d%H%M%S")
        @codigo = Codigo.find_by(clave: document_number).valor
      else
        @error = t("codigos.errors.census")
      end
    else
      @error = t("codigos.errors.form")
    end

    if @error.present?
      redirect_to codigos_solicitar_path(params: residence_params), flash: { error: @error }
    end
  end

  def error_datos( )
      error = {'error' => 'no encontrado'}.to_json
      render :json => error
  end

  def new

  end

  def create
    valor_sha1 = Digest::SHA1.hexdigest( request['valor'] )
    redirect_to :controller => 'users/omniauth_callbacks', :action => 'codigo', :clave => request['clave'], :valor => valor_sha1
  end

  private
    def residence_params
      params.require(:residence).permit(:document_number, :document_type, :date_of_birth, :postal_code, :terms_of_service, :format)
    end
end
