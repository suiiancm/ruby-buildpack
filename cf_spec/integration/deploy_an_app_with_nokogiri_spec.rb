$: << 'cf_spec'
require 'cf_spec_helper'

describe 'Installing Nokogiri' do
  subject(:app) { Machete.deploy_app(app_name) }
  let(:app_name) { 'mri_187_nokogiri' }

  after do
    Machete::CF::DeleteApp.new.execute(app)
  end

  context 'in an offline environment', if: Machete::BuildpackMode.offline? do
    specify do
      expect(app).to be_running
      expect(app).to have_logged 'Installing nokogiri'
      expect(app.host).not_to have_internet_traffic
    end
  end

  context 'in an online environment', if: Machete::BuildpackMode.online? do
    specify do
      expect(app).to be_running
      expect(app).to have_logged 'Installing nokogiri'
    end
  end
end
