require 'spec_helper'

describe 'hue' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "hue class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('hue') }
          it { is_expected.to contain_class('hue::params') }
          it { is_expected.to contain_class('hue::install').that_comes_before('hue::config') }
          it { is_expected.to contain_class('hue::config') }
          it { is_expected.to contain_class('hue::service').that_subscribes_to('hue::config') }

          it { is_expected.to contain_file('/etc/hue/conf/hue.ini') }
          it { is_expected.to contain_service('hue') }
          it { is_expected.to contain_package('hue').with_ensure('present') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'hue class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_class('hue') }.to raise_error(Puppet::Error, /Solaris.Nexenta not supported/) }
    end
  end
end
