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
end
