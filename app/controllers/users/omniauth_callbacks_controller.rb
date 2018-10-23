class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def twitter
    sign_in_with :twitter_login, :twitter
  end

  def facebook
    sign_in_with :facebook_login, :facebook
  end

  def google_oauth2
    sign_in_with :google_login, :google_oauth2
  end

  def ldap
    sign_in_with :ldap_login, :ldap
  end

  def codigo
    sign_in_with :codigo_login, :codigo
  end

  def after_sign_in_path_for(resource)
    budgets_path
  end

  private

    def sign_in_with(feature, provider)
      raise ActionController::RoutingError.new('Not Found') unless Setting["feature.#{feature}"]

      auth = env["omniauth.auth"]

      if auth.info.invalid_credentials

        if provider.to_s == 'ldap'
          redirect_to new_ldap_path, alert: 'Datos de acceso incorrectos.'
        else
          redirect_to new_codigo_path, alert: 'Datos de acceso incorrectos.'
        end

        return

      end

      if provider.to_s == 'ldap'
        auth.info.verified = true
      end

      identity = Identity.first_or_create_from_oauth(auth)
      @user = current_user || identity.user || User.first_or_initialize_for_oauth(auth)

      if provider.to_s == 'codigo'
        auth.info.verified = true

        # Buscamos si existe un usuario verificado con el
        # mismo número de documento, si ya existe lo único
        # que hacemos es asignarle el nuevo 'identity'

        registered_user = User.where(document_number: auth.info.document_number).try(:first)

        if registered_user.present?
          @user = registered_user
        end

        @user.skip_email_validation = true
        
        if !@user.level_two_or_three_verified?
          @user.document_type   = auth.info.document_type
          @user.document_number = auth.info.document_number
          @user.confirmed_at = Time.current
          @user.verified_at  = Time.current
        end
      end

      if registered_user.present? || save_user(@user)

        identity.update(user: @user)
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: "#{provider}".capitalize) if is_navigational_format?

      else

        session["devise.#{provider}_data"] = auth

        if provider.to_s == 'ldap'
          redirect new_ldap_path
        else
          redirect_to new_user_registration_url
        end
      end
    end

    def save_user(user)
      @user.save || @user.save_requiring_finish_signup
    end

end
