RSpec.describe Identikey::Administration::SessionQuery do
  username = ENV['TEST_USERNAME'] || 'ruby'
  password = ENV['TEST_PASSWORD'] || 'fake'
  domain   = ENV['TEST_DOMAIN']   || 'master'

  session  = Identikey::Administration::Session.new \
    username: username, password: password, domain: domain

  before(:all) do
    @s1 = session.dup.logon
    @s2 = session.dup.logon
  end

  after(:all) do
    @s1.logoff if @s1.logged_on?
    @s2.logoff
  end

  describe '.all' do
    it { expect{ @s1.all }.to_not raise_error }

    it { expect(@s1.all.size).to be >= 2 }
    it { expect(@s2.all.size).to eq(@s1.all.size) }

    it { expect(@s1.all.select {|s| s.username == username }.size).to eq(2) }
  end

  context 'on a stale session' do
    let!(:sid) { @s1.sid }
    before { @s1.logoff }
    subject { described_class.all session_id: sid }
    it { expect { subject }.to raise_error(Identikey::Error, /query failed: STAT_ADMIN_SESSION_STOPPED/) }
  end
end
