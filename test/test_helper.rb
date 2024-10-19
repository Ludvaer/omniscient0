ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'

class ActiveSupport::TestCase
  include Capybara::DSL
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors, with: :threads)
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def no_js_driver
    :rack_test
  end

  # Add more helper methods to be used by all tests here...
  def setup_capybara

    Capybara.default_driver = :selenium
    #Capybara.app_host = "http://localhost:3000"
    Capybara.run_server = true #Whether start server when testing
    Capybara.server_port = 8200
  end

  def with_and_without_js &test_block
      Capybara.use_default_driver
      test_block.call()
      Capybara.current_driver = no_js_driver
      test_block.call()
  end

  def accept_alert
    if Capybara.current_driver == :selenium
      page.driver.browser.switch_to.alert.accept
    end
  end

  def standart_name s
    s + 'name'
  end
  def standart_pass s
    s + 'pass'
  end
  def standart_mail s
    s + '_test_mail@'+ 'example.com'
  end

  def logged_in s
    assert page.has_css?('a.sign', text: 'Profile'),  'Logged in. Profile link'
    assert page.has_css?('a.sign', text: 'Log out'),  'Logged in. Log out link'
  end

  def check_not_logged_in s
    assert page.has_css?('a.sign', text: 'Sign up'),  'Logged out. Sign up link'
    assert page.has_css?('a.sign', text: 'Log in'),  'Logged out. Log in link'
  end

  def user_salt
    html_doc = Nokogiri::HTML(response.body)
    return html_doc.at_css('input#salt')['value']
  end

  def controller_signup s
    get signup_path(default_test_url_options)
    salt = user_salt
    name = standart_name s
    pass = standart_pass s
    mail = standart_mail s
    user_params = { salt: salt, email: mail, name: name, password: pass, password_confirmation: pass }
    post users_url, params: { user: user_params}
    # "#{s} signupped"
    return user_params
  end

  def controller_login s
    get login_path(default_test_url_options)
    salt = user_salt
    name = standart_name s
    pass = standart_pass s
    mail = standart_mail s
    user_params = { name: name, password: pass, salt: salt }
    post login_url, params: { user: user_params}
    return user_params
  end


  def standart_signup_bara s
    visit  signup_path(default_test_url_options)
    name = standart_name s
    pass = standart_pass s
    mail = standart_mail s
    fill_in('user[name]', with: name)
    fill_in('user[password]', with: pass)
    fill_in('user[password_confirmation]', with: pass)
    fill_in('user[email]', with: mail)
    first("input.btn").click()
    wait_for_ajax
    assert page.has_css?('p#notice', text: 'User was successfully created.'), 'standart signup, get success message'
    assert page.has_css?('h2', text: name), 'Standart signup, get profile page header'
    logged_in s
    # "#{s} signupped"
  end

  def standart_login s, remember = false, just_link = false
    name = s + 'name'
    pass = s + 'pass'
    click_link 'Log out' if page.has_css?('a', :text => 'Log out')
    if just_link or page.has_css?('a', :text => 'Log in')
      click_link 'Log in'
      # "#{s} login"
    else
      visit(login_path(default_test_url_options))
      # "#{s} visit login"
    end
    wait_for_ajax
    fill_in('user[name]', :with => name)
    fill_in('user[password]', :with => pass)
    check "Remember me" if remember
    first("input.btn").click()
    wait_for_ajax
    assert page.has_css?('p#notice', text: 'Login successful.'), 'standart login, get success message'
    logged_in s
  end

  def standart_logout s
    if page.has_css?('a', :text => 'Log out')
      # "#{s} logout"
      click_link 'Log out'
    else
      # "#{s} visit logout"
      visit logout_path(default_test_url_options)
    end
    assert page.has_css?('p#notice', text: 'Logout successfull.'), 'standart logout, get success message'
    check_not_logged_in s
  end

  def standart_destroy s
    standart_login s
    click_link 'Profile'
    click_link 'Destroy'
    accept_alert
    assert page.has_css?('p#notice', text: 'User was successfully destroyed.')
    # "#{s} destroyed"
  end

  def wait_for_ajax
    if Capybara.current_driver == no_js_driver
      return
    end
    Timeout.timeout(Capybara.default_max_wait_time) do
        loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def default_test_url_options
    {locale: :en}
  end

end
