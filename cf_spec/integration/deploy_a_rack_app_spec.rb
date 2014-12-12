$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Rack App' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'sinatra_web_app' }
  let(:browser) { Machete::Browser.new(app) }

  after do
    Machete::CF::DeleteApp.new.execute(app)
  end

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_running

      browser.visit_path('/')
      expect(browser).to have_body('Hello world!')

      expect(app.host).not_to have_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_running

      browser.visit_path('/')
      expect(browser).to have_body('Hello world!')
    end
  end
end
