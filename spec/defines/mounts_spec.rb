#
# behaviour testing for the mounts puppet module
# 
require 'spec_helper'

describe 'mounts' do
  let(:node) { 'testhost.example.org' }
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  
  let(:facts) {{
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
  }}
   
  context 'simple mount of local filesystem' do
    let(:title) { 'Sample local mount' }
    let(:params) { {
      :source => '/dev/sdb2',
      :dest   => '/a/path/to/data',
      :type   => 'ext4',
    } }

    it do

      should have_fstab_resource_count(1)
      
    end
  end
  
  context 'a test of an nfs mount' do
    let(:title) { 'Sample NFS mount' }
    let(:params) { {
      :ensure => 'present',
      :source => 'host.example.com',
      :dest   => '/a/path/to/more/data',
      :type   => 'nfs',
      :opts   => 'ro,defaults,noatime,nofail',
      } }
      
    it do

      should have_fstab_resource_count(1)
      
    end
  end

  context 'test removal of an entry' do
    let(:title) { 'Sample NFS mount' }
    let(:params) { {
      :ensure => 'absent',
      :source => 'host.example.com',
      :dest   => '/a/path/to/more/data',
      :type   => 'nfs',
      :opts   => 'ro,defaults,noatime,nofail',
      } }
      
    it do

      # module will create a fstab entry even if the filesystem is unmounted.
      should have_fstab_resource_count(1)
      
    end
  end

end