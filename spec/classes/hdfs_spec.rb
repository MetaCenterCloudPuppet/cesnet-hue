require 'spec_helper'

describe 'hue::hdfs' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "hue::hdfs class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('hue::hdfs') }
          it { is_expected.to contain_class('hue::user') }
        end
      end
    end
  end
end

describe 'hue::user' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "hue::user class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('hue::user') }

          it { is_expected.to contain_group('hue') }
          it { is_expected.to contain_user('hue') }
        end
      end
    end
  end
end
