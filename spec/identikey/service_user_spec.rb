RSpec.describe Identikey::Administration::Session do
  let(:username) { ENV.fetch('IK_SERVICE_ACCOUNT') }
  let(:apikey)   { ENV.fetch('IK_SERVICE_APIKEY') }

  let(:session) { described_class.new username: username, apikey: apikey }

  describe '#initialize' do
    subject { session }

    context 'given correct API key' do
      it { expect { subject }.to_not raise_error }

      it { expect(subject.sid).to_not be(nil) }
      it { expect(subject.service_user?).to be(true) }
      it { expect(subject.logged_on?).to be(true) }
    end

    context 'given invalid credentials' do
      let(:username) { 'bogus' }

      it { expect { subject }.to_not raise_error }
      it { expect(subject.service_user?).to be(true) }
      it { expect(subject.logged_on?).to be(true) }
    end

    context 'given invalid invocation' do
      let(:session) { described_class.new username: username }
      it { expect { subject }.to raise_error(Identikey::UsageError, /password or an api key is required/i) }
    end
  end

  describe '#endpoint' do
    subject { session.endpoint }

    it { expect(subject).to eq(ENV['IK_HOST']) }
  end

  describe '#wsdl' do
    subject { session.wsdl }

    it { expect(subject).to eq(ENV['IK_WSDL_ADMIN'] || './sdk/wsdl/administration.wsdl') }
  end

  describe '#logon' do
    subject { session.logon }

    it { expect { subject }.to raise_error(Identikey::UsageError, /command is not supported/) }
  end

  describe '#logoff' do
    subject { session.logoff }

    it { expect { subject }.to raise_error(Identikey::UsageError, /command is not supported/) }
  end

  describe '#privileges' do
    subject { session.privileges }

    it { expect(subject).to be(nil) }
  end

  describe '#inspect' do
    subject { session.inspect }

    it { expect(subject).to match(/SERVICE USER/) }
  end

  describe '#execute' do
    subject { session.execute :admin_session_query }

    it { expect { subject }.to_not raise_error }
    it { expect(subject.first).to eq('STAT_SUCCESS') }
  end

end
