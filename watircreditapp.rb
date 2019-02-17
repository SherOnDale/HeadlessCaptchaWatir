#!/usr/bin/env ruby

require 'byebug' # very handy for debugging, if you don't already know about this guy read up
require 'rubygems'
require 'watir' # I'm running 6.16.5
require 'timeout'

require 'deep_clone' # A gem for deep copying objects

# review this on the ruby website.  Seems to be the best way to make system calls
# according to a couple of stack overflows I've read on the subject
require 'open3'

require_relative 'firefox_watir_browser'
require_relative 'field_mapper'
require_relative 'array_loader'

class FillApplication
  OcbcHomepage = "http://www.ocbc.com/personal-banking/cards"

  attr_accessor :browser, :data, :click_fields, :send_fields, :office_send_fields,
    :straight_clicks, :clear_and_send

  def initialize(headless)
    # passing anything other than nil causes it to run in headless
    #   mode
    # @browser = FirefoxWatirBrowser.new().instantiate_one
    @browser = FirefoxWatirBrowser.new(headless).instantiate_one

    #  These files could be put in an array and iterated over to load actually
    @click_fields = FieldMapper.new("click_fields.csv").load_elements
    @send_fields = FieldMapper.new("send_fields.csv").load_elements
    @office_send_fields = FieldMapper.new("office_send_fields.csv").load_elements
    @clear_and_send = FieldMapper.new("clear_and_send_fields.csv").load_elements

    @straight_clicks = ArrayLoader.new("straight_click_fields.txt").load_elements
  end

  # This way in theory, you can instantiate this class once and repeatedly
  #   pass in credit card application data as opposed to setting in initialize
  #   which requires an instantiation of this class and a watir for each time
  #   you want to submit a credit card application
  def submit_data_to_ocbc(data)
    @data = data
    start_at_cards_page
    pick_the_right_card('365')
    fill_in_data
    fill_in_captcha
  end

  def terminate_application_runs
    close_the_fucking_browser_goddamit
  end

  private
  def start_at_cards_page
    puts "Going to the bank home page"
    @browser.goto OcbcHomepage
    puts "waiting for page to load"
    @browser.links(text: "Apply Now")[1].wait_until(&:present?) # wait for page to open
    puts "loaded"
  end

  def pick_the_right_card(card_name)
    puts "Picking Card"
    @browser.links(text: "Apply Now")[1].click # 17 links and we want the 2nd one
    @browser.windows.last.use # switch to opened window
    @browser.form(id: "ApplicationForm").wait_until(&:present?) # wait for page to open

    @browser.input(id: "App_CustList_0__IsExCust", value: "N").click
    @browser.link(id: "btnApply").click

    @browser.link(id: "btnToReview").wait_until(&:present?)

    puts 'Done picking the card'
  end

  def fill_in_data
    @click_fields.each {|key, value| click_on_element(key, value)}
    @send_fields.each {|key, value| send_keys_for_element(key, value)}
    @straight_clicks.each {|element| straight_click(element)}
    @clear_and_send.each {|key, value| clear_and_send_element(key, value)}

    singaporean_processing
    home_and_office_processing
    self_employed_processing
    @browser.element(:id, 'App_FacList_0__ApplyeStt').click if @data[:isHardCopyPreferred]
  end


  def click_on_element(key, value)
    @browser.element(:id, key).find_element(:css, "option[value=\"#{@data[value]}\"]").click
  end

  def send_keys_for_element(key, value)
    @browser.element(:id, key).send_keys(@data[value])
  end

  def clear_element_for(key)
    @browser.element(:id, key).clear()
  end

  def straight_click(element)
    @browser.element(:id, element).click
  end

  def clear_and_send_element(key, value)
    clear_element_for(key)
    send_keys_for_element(key, value)
  end

  def singaporean?
    return true if @data[:isSingaporean] == 'Singaporean'
    return false
  end

  def prefer_home?
    return true if (@data[:isPreferredAddressHome])
    return false
  end

  def self_employed?
    return true if @data[:isSelfEmployed]
    return false
  end

  def send_floor_and_unit(zo, data_item) # zo is "0" or "1"
    floor, unit = data_item.split('-')
    @browser.element(:id, "App_CustList_0__CustAdd_#{zo}__FloorNo").send_keys(floor)
    @browser.element(:id, "App_CustList_0__CustAdd_#{zo}__UnitNo").send_keys(unit)
  end

  def singaporean_processing
    yn = (singaporean?) ? "Y" : "N"
    @browser.element(:css, "#App_CustList_0__AreYouSingaporean[value=\"#{yn}\"]").click
    send_keys_for_element('App_CustList_0__NRIC', :nric) if singaporean?
  end

  def home_and_office_processing
    ho = (prefer_home?) ? "H" : "O"
    @browser.element(:css, "#App_CustList_0__PrefMailAdd[value=\"#{ho}\"]").click
    send_floor_and_unit("0", @data[:homeUnitNumber]) # home
    fill_in_office_addy unless prefer_home?
  end

  def self_employed_processing
    yn = (self_employed?) ? "Y" : "N"
    @browser.element(:css, "#App_CustList_0__Emp_IsSelfEmployed[value=\"#{yn}\"]").click
  end

  def fill_in_office_addy
    @office_send_fields.each {|key, value| send_keys_for_element(key, value)}
    send_floor_and_unit("1", @data[:officeUnitNumber]) # home
  end

  #  This one should probably be refactored too.
  def fill_in_captcha
    puts "top of fill_in_captcha"
    @browser.element({id: "regCaptcha"}).wait_until(&:present?) # wait for captcha element
    src = @browser.element({id: "regCaptcha"}).attribute('src') # get the src url
    puts "image source is #{src}"

    # Sadly necessary to get past the image loader url.  If you move on too quickly
    # the image that gets downloaded is the spinner for the captcha image loading
    until !src.include?("ajax-module-loader.gif")
      sleep 1
      src = @browser.element({id: "regCaptcha"}).attribute('src') # get the src url
      puts "image source is now #{src}"
    end

    src = @browser.element({id: "regCaptcha"}).attribute('src') # get the src url

    throwaway = DeepClone.clone @browser # clone the browser session
    throwaway.execute_script('window.open()') # open a new window
    throwaway.windows.last.use # switch to opened window

    # now go there.
    begin
      Timeout::timeout(3) { throwaway.goto src }
    rescue Timeout::Error
    end
  end

  def close_the_fucking_browser_goddamit
    # First, try to quit the browser the normal way
    begin
      Timeout::timeout(2) { @browser.close }
    rescue Timeout::Error
      puts  "Well, that didn't work. Bring in the artillery!"

      # Examples provided by searching are dated and the object you need's a private class
      # Use a system call instead.  stdout will be pumped to variable output as a string
      output = Open3.popen3("ps -aux | grep firefox | grep marionette") { |stdin, stdout, stderr, wait_thr| stdout.read }
      browser_pid = output.split[1].to_i # get the 2nd item in the output and convert it to an integer

      begin # now kill that motherfucker
        ::Process.kill('KILL', browser_pid)
        @browser = nil
      ensure
        @browser.close if @browser
      end
    end
  end
end



fa = FillApplication.new
fa.submit_data_to_ocbc
