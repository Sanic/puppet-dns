require 'spec_helper'

describe 'dns::zone' do
  let(:pre_condition) { 'include dns::server::params' }

  let(:title) { 'test.com' }

  context 'passing something other than an array' do
    let :facts  do { :osfamily => 'Debian', :concat_basedir => '/dne' } end
    let :params do { :allow_transfer => '127.0.0.1' } end

    it 'should fail input validation' do
      expect { subject }.to raise_error(Puppet::Error, /is not an Array/)
    end
  end

  context 'passing an array to data' do
    let :facts  do { :osfamily => 'Debian', :concat_basedir => '/dne' } end
    let :params do
      { :allow_transfer => [ '192.0.2.0', '2001:db8::/32' ],
        :allow_forwarder => ['8.8.8.8', '208.67.222.222']
      }
    end

    it 'should pass input validation' do
      expect { subject }.to_not raise_error
    end

    it {
      should contain_concat__fragment('named.conf.local.test.com.include').
      with_content(/allow-transfer/)
    }

    it {
      should contain_concat__fragment('named.conf.local.test.com.include').
      with_content(/192\.0\.2\.0/)
    }

    it {
      should contain_concat__fragment('named.conf.local.test.com.include').
      with_content(/forwarders/)
    }

    it {
      should contain_concat__fragment('named.conf.local.test.com.include').
      with_content(/forward first;/)
    }

    it {
      should contain_concat__fragment('named.conf.local.test.com.include').
      with_content(/8.8.8.8/)
    }

    it {
      should contain_concat__fragment('named.conf.local.test.com.include').
      with_content(/2001:db8::\/32/)
    }

    it { 
      should contain_concat('/etc/bind/zones/db.test.com.stage')
    }

    it { should contain_concat__fragment('db.test.com.soa').
      with_content(/_SERIAL_/)
    }

    it {
      should contain_exec('bump-test.com-serial').
      with_refreshonly('true')
    }
  end

  context 'when ask to have a only forward policy' do
    let :facts do { :concat_basedir => '/dne',  } end
    let :params do
      { :allow_transfer => [],
        :allow_forwarder => ['8.8.8.8', '208.67.222.222'],
        :forward_policy => 'only'
      }
    end
      it 'should have a forward only policy' do
          should contain_concat__fragment('named.conf.local.test.com.include').
          with_content(/forward only;/)
      end
  end

  context 'In the default case with no explicit forward policy or forwarder' do
    let :facts do { :concat_basedir => '/dne',  } end
    let :params do
      { :allow_transfer => [ '192.0.2.0', '2001:db8::/32' ],
      }
    end

    it 'should not have any forwarder configuration' do
        should_not contain_concat__fragment('named.conf.local.test.com.include').
        with_content(/forward/)
    end
  end
end

