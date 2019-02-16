require 'selenium-webdriver'

class FillApplication
  attr_accessor :data

  # One more thing to consider would be to store this off in a csv file in case you
  #   ever need to change.  Then you change the csv file, not the code
  PersDtlsClcks = {
    'App_CustList_0__SalCd' => :title,
    'App_CustList_0__DOBDate' => :dobDate,
    'App_CustList_0__DOBMonth' => :dobMonth,
    'App_CustList_0__CountryOfBirthCd' => :country,
    'App_CustList_0__NoOfDep' => :country,
    'App_CustList_0__EdLevelCd' => :educationLevel,
  }

  PersDtlsSends = {
    'App_CustList_0__Nm' => :name,
    'App_CustList_0__FacRelShip_0__NameOnCard' => :nameOnCard,
    'App_CustList_0__MotherMaiden' => :motherMaidenName,
  }

  ContDtlsClcks = {
    'App_CustList_0__CustAdd_0__ResidentStatusCd' => :residentialStatus,
    'App_CustList_0__CustAdd_0__YearsInResidence' => :yearsInResidence,
  }

  ContDtlsSends = {
    'App_CustList_0__MobileNo' => :homeNumber,
    'App_CustList_0__HomeOfficeNo' => :mobileNumber,
    'App_CustList_0__BlockNo' => :homeBlockNumber,
    'App_CustList_0__FloorNo' => :homeFloorNumber,
    'App_CustList_0__UnitNo' => :homeUnitNumber,
    'App_CustList_0__StreetName' => :homeStreet,
  }

  ContOffcSends = {
    'App_CustList_0__CustAdd_1__PostalCode' => :officePostalCode,
    'App_CustList_0__CustAdd_1__BlockNo' => :officeBlockNumber,
    'App_CustList_0__CustAdd_1__FloorNo' => :officeFloorNumber,
    'App_CustList_0__CustAdd_1__UnitNo' => :officeUnitNumber,
    'App_CustList_0__CustAdd_1__StreetName' => :officeStreet,
  }

  EmpDtlsClcks = {
    'App_CustList_0__Emp_OccupationCd' => :occupation,
    'App_CustList_0__Emp_LenOfSvc' => :yearsWithEmployer,
    'App_CustList_0__Emp_BizzTypeCd' => :natureOfBusiness,
    'App_CustList_0__Emp_AnnualIncRangeCd' => :annualIncome,
  }

  def initialize(params)
    @data = params
  end

  def send_request
    return error_response  if errors.any?
    response
  end

  private

  def error_response
    {errors: errors}
  end

  def errors
    FillApplicationValidator.validate(data).errors
  end

  def response
    submit_data_to_ocbc
  end

  def submit_data_to_ocbc
    setup_driver
    pick_the_right_card('365')
    fill_in_personal_details
    fill_in_contact_details
    fill_in_employment_details
    fill_in_income_details
    fill_in_card_options
    fill_in_captcha
    submit_the_form
    parse_response
  end


  private


  def setup_driver
    options = Selenium::WebDriver::Chrome::Options.new
    # options.add_argument('--headless')
    # options.add_argument('--no-sandbox')
    # options.add_argument('--disable-gpu')
    # options.add_argument('--disable-popup-blocking')
    # options.add_argument('--window-size=1366,768')
    options.add_preference(:download, directory_upgrade: true,
                                    prompt_for_download: false,
                                    default_directory: 'tmp')

    options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })


    # two_second_wait = Selenium::WebDriver::Wait.new(:timeout => 2)
    # five_second_wait = Selenium::WebDriver::Wait.new(:timeout => 5)
    # success_wait = Selenium::WebDriver::Wait.new(:timeout => 100)

    # begin
    #   driver.get(Configuration.config.ocbc_base_url)
    #   driver.find_element(css: '[data-card="365"]').click
    #   driver.switch_to.window( driver.window_handles.last)
    #   sleep(2)
    #   driver.find_element(:css, '#App_CustList_0__IsExCust[value="N"]').click
    #   driver.find_element(:id, 'btnApply').click
    #   sleep(2)

    #   #Personal details
    #   driver.find_element(:id, 'App_CustList_0__SalCd').find_element(:css, "option[value=\"#{data[:title]}\"]").click
    # rescue
    #   puts 'retrying'
    #   retry
    # end
    @driver = Selenium::WebDriver.for(:chrome, options: options)

    # bridge = @driver.send(:bridge)
    # path = '/session/:session_id/chromium/send_command'
    # path[':session_id'] = bridge.session_id
    # bridge.http.call(:post, path, cmd: 'Page.setDownloadBehavior',
    #                             params: {
    #                               behavior: 'allow',
    #                               downloadPath: 'tmp'
    #                             })

    puts 'Done setting up the driver'
  end

  def pick_the_right_card(card_name)
    @driver.get(Configuration.config.ocbc_base_url)
    @driver.find_element(css: "[data-card=\"#{card_name}\"]").click
    @driver.switch_to.window( @driver.window_handles.last)
    sleep(2)
    @driver.find_element(:css, '#App_CustList_0__IsExCust[value="N"]').click
    @driver.find_element(:id, 'btnApply').click
    sleep(2)
    puts 'Done picking the card'
  end

  def fill_in_personal_details
    puts 'Beg filling in personal details'
    PersDtlsClcks.each { |key, value| click_on_element(key, value) }
    PersDtlsSends.each { |key, value| send_keys_for_element(key, value) }

    clear_element_for('App_CustList_0__DOBYear')
    @driver.find_element(:id, 'App_CustList_0__DOBYear').send_keys(data[:dobYear])

    yn = (data[:isSingaporean] == 'Singaporean') ? "Y" : "N"
    @driver.find_element(:css, "#App_CustList_0__AreYouSingaporean[value=\"#{yn}\"]").click
    @driver.find_element(:id, 'App_CustList_0__NRIC').send_keys(data[:nric]) if yn == "Y"

    puts 'End filling in personal details'
  end

  def click_on_element(key, value)
    @driver.find_element(:id, key).find_element(:css, "option[value=\"#{@data[value]}\"]").click
  end

  def send_keys_for_element(key, value)
    @driver.find_element(:id, key).send_keys(@data[value])
  end

  def clear_element_for(key)
    @driver.find_element(:id, key).clear()
  end

  def fill_in_contact_details
    puts 'Beg filling in contact details'
    @driver.find_element(:id, 'contact-details').click

    ContDtlsClcks.each {|key, value| click_on_element(key, value) }
    ContDtlsSends.each { |key, value| send_keys_for_element(key, value) }

    clear_element_for('App_CustList_0__Email')
    send_keys_for_element('App_CustList_0__Email', :email)

    ho = (data[:isPreferredAddressHome]) ? "H" : "O"
    @driver.find_element(:css, "#App_CustList_0__PrefMailAdd[value=\"#{ho}\"]").click
    fill_in_office_contact_details if ho == "O"

    @driver.find_element(:id, 'App_CustList_0__IsMrktConsentByPhoneAndSMS').click
    puts 'End filling in contact details'
  end

  def fill_in_office_contact_details
    @driver.find_element(:css, '#App_CustList_0__PrefMailAdd[value="O"]').click
    ContOffcSends.each { |key, value| send_keys_for_element(key, value) }
  end

  def fill_in_employment_details
    @driver.find_element(:id, 'employer-details').click
    send_keys_for_element('App_CustList_0__Emp_EmployerNm', :nameOfEmployer)

    EmpDtlsClcks.each {|key, value| click_on_element(key, value) }

    yn = (data[:isSelfEmployed]) ? "Y" : "N"
    @driver.find_element(:id, 'App_CustList_0__Emp_IsSelfEmployed').find_element(:css, "option[value=\"#{yn}\"]").click

    sleep(2)
    puts 'Done filling in employment details'
  end

  def fill_in_income_details
    if(data[:isCreditLimitAccepted])
      @driver.find_element(:css, '#creditLimitByBankButton a').click
    else
      @driver.find_element(:id, 'App_UserPreferredCreditLimitValue').send_keys(data[:preferredCreditCardLimit])
    end
    @driver.find_element(:id, 'skipcpf').click
    sleep(2)
    puts 'Done filling in income details'
  end

  def fill_in_card_options
    @driver.find_element(:id, 'card-options').click
    @driver.find_element(:id, 'App_FacList_0__ApplyeStt').click if data{:isHardCopyPreferred}
    @driver.find_element(:id, 'App_FacList_0__ApplyCW').click
  end

  def fill_in_captcha
    retry_captcha = 0
    src = @driver.find_element(:id, 'regCaptcha').attribute('src')
    @driver.execute_script('window.open()')
    @driver.switch_to.window(@driver.window_handles.last)
    @driver.get(src)
    sleep(2)

    client = DeathByCaptcha.new(ENV['DEATH_BY_CAPTCHA_UNAME'], ENV['DEATH_BY_CAPTCHA_PWD'], :http)
    begin
      captcha = client.decode!(path: 'tmp/a.jpg')
    rescue Exception => e
      retry_captcha += 1
      puts e.message
      puts retry_captcha
      retry if retry_captcha < 3
    end
    @driver.close
    @driver.switch_to.window(@driver.window_handles.last)
    File.delete('tmp/a.jpg') if File.exist?('tmp/a.jpg')
    @driver.find_element(:id, 'Captcha').send_keys(captcha.text)
  end

  def submit_the_form
    @driver.find_element(:id, 'btnToReview').click
    sleep(5)

    #Summary
    @driver.find_element(:id, 'AgreedDeclaration').click
    @driver.find_element(:id, 'btnSubmitApplication').click
  end

  def parse_response
    #Check-Success
    success_wait = Selenium::WebDriver::Wait.new(:timeout => 100)
    success_wait.until { @driver.find_element(:id, 'frm-apply-credit-card').text.strip.include? 'Thank you, we have received your application.' }
    if @driver.find_element(:id, 'frm-apply-credit-card').text.strip.include? 'Thank you, we have received your application.'
      puts 'Success'
    else
      puts 'Failed'
    end

    @driver.quit
  end

  def get_floor_number(unit)
    unit.split('-')[0]
  end

  def get_unit_number(unit)
    unit.split('-')[1]
  end
end
