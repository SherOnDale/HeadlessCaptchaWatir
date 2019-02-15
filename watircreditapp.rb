#!/usr/bin/env ruby

require 'byebug' # very handy for debugging, if you don't already know about this guy read up
require 'rubygems'
require 'watir' # I'm running 6.16.5

class FillApplication
  attr_accessor :browser
  def initialize
    download_directory = "/home/noah/Downloads" # hack as needed

    # You will need to install the Firefox WebDriver
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile['browser.download.folderList'] = 2 # custom location - not sure if needed
    profile['browser.download.dir'] = download_directory

    # We only really need image/gif here but I kept the samples and image/jpeg didn't work
    profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv,application/pdf,image/jpeg,image/gif'

    # Observe headless parameter
    @driver = Watir::Browser.new(:firefox, profile: profile, headless: true)
  end

  # I only included the relevant methods here.
  def submit_data_to_ocbc
    pick_the_right_card('365')
    fill_in_captcha
    @driver.close if @driver # shut down driver at end
  end


  private
  def pick_the_right_card(card_name)
    puts "Going to the bank home page"
    @driver.goto("http://www.ocbc.com/personal-banking/cards")

    @driver.links(text: "Apply Now")[1].click # 17 links and we want the 2nd one
    @driver.windows.last.use # switch to opened window
    @driver.form(id: "ApplicationForm").wait_until(&:present?) # wait for page to open

    @driver.input(id: "App_CustList_0__IsExCust", value: "N").click
    @driver.link(id: "btnApply").click

    @driver.link(id: "btnToReview").wait_until(&:present?)

    puts 'Done picking the card'
  end

  def fill_in_captcha
    puts "top of fill_in_captcha"
    @driver.element({id: "regCaptcha"}).wait_until(&:present?) # wait for captcha element

    # Sadly necessary to get past the image loader url.  If you move on too quickly
    # the image that gets downloaded is the spinner for the captcha image loading
    sleep 2

    src = @driver.element({id: "regCaptcha"}).attribute('src') # get the src url
    @driver.execute_script('window.open()') # open a new window
    @driver.windows.last.use # switch to opened window
    # now go there.  Note that it hangs here.  Look at the Watir documentation
    # to see if there's a way to get past this
    @driver.goto src

    # Never gets here
    puts "image source is #{src}"
  end

end



fa = FillApplication.new
fa.submit_data_to_ocbc
