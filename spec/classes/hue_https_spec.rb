require 'spec_helper'

describe 'hue' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        let(:params) do
          {
            :hdfs_hostname => 'localhost',
            :https => true,
          }
        end

        context "hue class with https" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('hue') }

          it { is_expected.to contain_file('/etc/hue/conf/hostcert.pem') }
          it { is_expected.to contain_file('/etc/hue/conf/hostkey.pem') }
        end
      end
    end
  end
end
