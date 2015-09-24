require 'spec_helper'
describe 'rk_tomcat' do

  context 'with defaults for all parameters' do
    it { should contain_class('rk_tomcat') }
  end
end
