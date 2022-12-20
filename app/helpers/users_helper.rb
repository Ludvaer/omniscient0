module UsersHelper
	  # Returns the Gravatar for the given user.
  def gravatar_for(user)
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}"
    link_to(image_tag(gravatar_url, alt: "gravatar", class: "gravatar"), @user, :class => 'avatar' )
  end

  def errors_for(user, field)
    errors = user.errors.to_hash(true)[field]
    errors.map{ |message|  "<div class='error'>#{message}</div>"}.join().html_safe
  end

  def user_name_field(f,is_signup = false)
    render partial: 'users/username_field', locals: { f: f, for_new: is_signup }
  end

  def user_email_field(f,is_signup = false)
    render partial: 'users/email_field', locals: { f: f, for_new: is_signup }
  end

  def user_password_field(f,is_signup = false)
    render partial: 'users/password_field', locals: { f: f, for_new: is_signup }
  end

  def user_old_password_field(f)
    validness_error =  %Q{<div class="error"  #{ 'hidden="hidden"' unless @user.old_password_invalid } id="old-password-invalid">
        Invalid password, or wrong username.</div>}
    %Q{
      <div class="field">
      #{ f.label :old_password, t('Old password') }
      #{ f.password_field :old_password }
      <div class="error"  #{ 'hidden="hidden"' unless @user.old_password_empty } id="old_password-empty">
        Password should not be empty.</div>
      #{ validness_error }
      </div>
    }.html_safe
  end

  def user_password_confirmation_field(f,is_signup = false)
    render partial: 'users/password_confirmation_field', locals: { f: f, for_new: is_signup }
  end

  def user_salt_field
    %Q{<input type="text" style="display: none;" hidden="hidden" name="user[salt]" id = "salt" value="#{ @salt }"/>}.html_safe
  end

  #its crtical for javascript to preserve button id sign-up-button and submit button id as user submit
  def user_form_container form_path,action
    %Q{
      <div id="sign-up-response">
        #{ render form_path }
      </div>

      <input type="button" class="btn" style="display:none;" hidden="true" value="#{action}" id="sign-up-button" onclick="encryptsignup()" />

      <script type="text/javascript">
          init_users_form();
      </script>
    }.html_safe

  end

  def public_key_field
     render partial: 'users/public_key_field'
  end

  def  user_field_error_message(message_id)
    render partial: 'users/field_error_message', locals: { message_id: message_id }
  end

  def  simple_error_message(message_id)
    render partial: 'users/simple_error_message', locals: { message_id: message_id }
  end
end
