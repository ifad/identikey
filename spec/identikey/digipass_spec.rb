RSpec.describe Identikey::Administration::Digipass do
  username = ENV.fetch('IK_USER')
  password = ENV.fetch('IK_PASS')
  domain   = ENV.fetch('IK_DOMAIN', 'master')
  session  = Identikey::Administration::Session.new username: username, password: password, domain: domain

  before(:all) { session.logon }
  after(:all) { session.logoff }

  describe '.find' do
    subject { described_class.find(session: session, serial_no: serial) }

    context 'given an existing token' do
      let(:serial) { ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER') }

      it { expect(subject).to be_a(described_class) }
      it { expect(subject.serial).to eq(serial) }
    end

    context 'given a non-existing token' do
      let(:serial) { '1234567890' }

      it { expect { subject }.to raise_error(Identikey::NotFound).with_message(/STAT_NOT_FOUND/) }
    end
  end

  describe '.search' do
    let(:options) { {} }
    subject { described_class.search(session: session, query: query, options: options) }

    context 'for an assigned digipass, searching by user' do
      let(:query) { {username: ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(1) }
      it { expect(subject.first).to be_a(described_class) }
      it { expect(subject.first.serial).to eq(ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER')) }
    end

    context 'for an assigned digipass, searching by token' do
      let(:query) { {serial: ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(1) }
      it { expect(subject.first).to be_a(described_class) }
      it { expect(subject.first.serial).to eq(ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER')) }
    end

    context 'for an assigned digipass, and a wrong query' do
      let(:query) { {username: ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON'), serial: ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(0) }
      it { expect(subject.first).to be(nil) }
    end

    context 'searching by status' do
      let(:query) { {status: 'Assigned', serial: ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(1) }
      it { expect(subject.first).to be_a(described_class) }
      it { expect(subject.first.serial).to eq(ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER')) }
    end

    context 'with silly parameters' do
      let(:query) { {status: 'Antani'} }

      it { expect { subject }.to raise_error(Identikey::Error).with_message(/STAT_INVDATA/) }
    end
  end

  describe '.assigned?' do
    subject { digipass.assigned? }

    let(:digipass) { described_class.find(session: session, serial_no: serial) }

    context 'given an assigned digipass' do
      let(:serial) { ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER') }

      it { expect(subject).to be(true) }
    end

    context 'given an unassigned digipass' do
      let(:serial) { ENV.fetch('IK_UNASSIGNED_TOKEN_1_NUMBER') }

      it { expect(subject).to be(false) }
    end
  end

  describe 'assign!' do
    subject { digipass.assign!(user, domain) }

    let(:digipass) { described_class.find(session: session, serial_no: serial) }
    let(:user) { ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON') }

    context 'given an already assigned digipass' do
      let(:serial) { ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER') }

      it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_DIGIPASS_NOT_AVAILABLE/) }

      it { expect { subject rescue nil }.to_not change {
        described_class.find(session: session, serial_no: serial).userid } }
    end

    context 'given a free digipass' do
      let(:serial) { ENV.fetch('IK_UNASSIGNED_TOKEN_1_NUMBER') }

      after { digipass.unassign! }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(described_class) }
      it { expect(subject.userid).to eq(user) }
      it { expect(subject.status).to eq('Assigned') }

      it { expect { subject }.to change {
        described_class.find(session: session, serial_no: serial).userid }.from(nil).to(user) }
    end
  end

  describe 'unassign!' do
    subject { digipass.unassign! }

    let(:digipass) { described_class.find(session: session, serial_no: serial) }

    let(:serial) { ENV.fetch('IK_UNASSIGNED_TOKEN_1_NUMBER') }
    let(:user) { ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON') }

    context 'given a free digipass' do
      it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_ERROR.*DIGIPASS with serial number .* is not assigned/) }

      it { expect { subject rescue nil }.to_not change {
        described_class.find(session: session, serial_no: serial).userid } }
    end

    context 'given an assigned digipass' do
      let(:user) { ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON') }

      before { digipass.assign!(user, domain) }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(described_class) }
      # it { expect(subject.userid).to be(nil) } and here identikey chokes and returns the former assignee
      it { expect(subject.status).to eq('Unassigned') }

      it { expect { subject }.to change {
        described_class.find(session: session, serial_no: serial).userid }.from(user).to(nil) }
    end
  end

end