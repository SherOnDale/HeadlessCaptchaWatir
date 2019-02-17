
require 'watir' # I'm running 6.16.5
class FirefoxWatirBrowser
  attr_accessor :profile, :headless

  def initialize(headless)
    download_directory = "/home/noah/Downloads" # hack as needed

    # You will need to install the Firefox WebDriver
    @profile = Selenium::WebDriver::Firefox::Profile.new
    @profile['browser.download.folderList'] = 2 # custom location - not sure if needed
    @profile['browser.download.dir'] = download_directory

    # We only really need image/gif here but I kept the samples and image/jpeg didn't work
    @profile['browser.helperApps.neverAsk.saveToDisk'] = 'text/csv,application/pdf,image/jpeg,image/gif'

    @headless = (headless.nil?) ? false : true
  end

  def instantiate_one
    return Watir::Browser.new(:firefox, profile: @profile, headless: @headless)
  end
end
