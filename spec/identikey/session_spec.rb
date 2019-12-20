RSpec.describe Identikey::Administration::Session do
  let(:username) { ENV.fetch('IK_USER') }
  let(:password) { ENV.fetch('IK_PASS') }
  let(:domain)   { ENV.fetch('IK_DOMAIN', 'master') }

  let(:session) { described_class.new username: username, password: password, domain: domain }

  describe '#initialize' do
    subject { session }

    context 'given correct credentials' do
      it { expect { subject }.to_not raise_error }
      it { expect(subject.sid).to be(nil) }
    end

    context 'given invalid credentials' do
      let(:username) { 'bogus' }

      it { expect { subject }.to_not raise_error }
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

    context 'given correct credentials' do
      it { expect { subject }.to_not raise_error }
      it { expect(subject.sid).to_not be(nil) }

      after { session.logoff }
    end

    context 'given invalid credentials' do
      let(:username) { 'bogus' }

      it { expect { subject }.to raise_error(Identikey::Error, /logon failed/) }
    end
  end

  describe '#logoff' do
    before { session.logon }
    subject { session.logoff }

    context 'on an active session' do
      it { expect(subject).to be(true) }
    end

    context 'on a stale session' do
      let(:hijacker) { session.dup }
      before { hijacker.logoff }

      it { expect(subject).to be(false) }
    end
  end

  describe '#logged_on?' do
    subject { session.logged_on? }

    context 'on a new session' do
      it { expect(subject).to be(false) }
    end

    context 'on a logged on session' do
      before { session.logon }
      it { expect(subject).to be(true) }
      after { session.logoff }
    end

    context 'on a logged off session' do
      before { session.logon; session.logoff }
      it { expect(subject).to be(false) }
    end

    context 'on a failed logon session' do
      let(:username) { 'bogus' }
      before { session.logon rescue nil }
      it { expect(subject).to be(false) }
    end
  end

  describe '#alive?' do
    subject { session.alive? }

    context 'on a new session' do
      it { expect(subject).to be(false) }
    end

    context 'on a logged on session' do
      before { session.logon }
      it { expect(subject).to be(true) }
      after { session.logoff }
    end

    context 'on a stale session' do
      before { session.logon }
      let(:hijacker) { session.dup }
      before { hijacker.logoff }

      it { expect(subject).to be(false) }
    end
  end

  describe '#privileges' do
    subject { session.privileges }

    context 'on a new session' do
      it { expect(subject).to be(nil) }
    end

    context 'on a logged on session' do
      before { session.logon }
      it { expect(subject).to be_a(Hash) }
      after { session.logoff }
    end
  end

end
