#
# behaviour testing for the mounts puppet module
# 
require 'spec_helper'

describe mounts do
  let(:node) { 'testhost.example.org' }
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  
  context 'simple mount of local filesystem' do
    let(:title) { 'Test NFS Mount' }
    let(:params) { {
      :source => '/dev/sdb2',
      :dest   => '/a/path/to/data',
      :type   => 'ext4',
    } }

    should contain_mounts('Test NFS Mount' )

    should have_fstab_resource_count(1)

  end
end