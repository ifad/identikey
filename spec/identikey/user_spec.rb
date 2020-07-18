RSpec.describe Identikey::Administration::User do
  username = ENV.fetch('IK_USER')
  password = ENV.fetch('IK_PASS')
  domain   = ENV.fetch('IK_DOMAIN', 'master')
  client   = ENV.fetch('IK_CLIENT')
  session  = Identikey::Administration::Session.new username: username, password: password, domain: domain

  before(:all) { session.logon }
  after(:all) { session.logoff }

  describe '.find' do
    subject { described_class.find(session: session, username: user, domain: domain) }

    context 'given an existing user' do
      let(:user) { ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON') }

      it { expect(subject).to be_a(described_class) }
      it { expect(subject.username).to eq(user) }
    end

    context 'given a non-existing user' do
      let(:user) { 'frupper.marcantonio' }

      it { expect { subject }.to raise_error(Identikey::NotFound).with_message(/STAT_NOT_FOUND/) }
    end
  end

  describe '.search' do
    let(:options) { {} }
    subject { described_class.search(session: session, query: query, options: options) }

    context 'for users with digipass assigned' do
      let(:query) { {has_digipass: true, username: ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(1) }
      it { expect(subject.first).to be_a(described_class) }
      it { expect(subject.first.username).to eq(ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON')) }
    end

    context 'for users with digipass assigned and a wrong query' do
      let(:query) { {has_digipass: true, username: ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(0) }
      it { expect(subject.first).to be(nil) }
    end

    context 'for users without a digipass' do
      let(:query) { {has_digipass: false, username: ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON')} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to eq(1) }
      it { expect(subject.first).to be_a(described_class) }
      it { expect(subject.first.username).to eq(ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON')) }
    end

    context 'for locked users' do
      let(:query) { {locked: true} }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to be >= 0 }
    end

    context 'for wrong parameters' do
      let(:query) { {locked: 'frupper'} }

      it { expect { subject }.to raise_error(Identikey::Error).with_message(/STAT_INVDATA/) }
    end

    context 'for users with no description' do
      let(:query) { {description: nil} }
      let(:options) { {limit: 1} }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to be >= 0 }
    end
  end

  describe '.save' do
    subject { user.save! }

    context 'when creating a new user' do
      context 'and providing all parameters' do
        let(:user) { described_class.new(
          session,
          'USERFLD_USERID'       => 'ik.test',
          'USERFLD_EMAIL'        => 'ik.test@example.com',
          'USERFLD_DOMAIN'       => domain,
          'USERFLD_LOCAL_AUTH'   => 'Default',
          'USERFLD_BACKEND_AUTH' => 'Default',
          'USERFLD_DISABLED'     => false,
          'USERFLD_LOCKED'       => false,
        ) }

        it { expect { subject }.to_not raise_error }
        it { expect(subject).to be_a(described_class) }
        it { expect(subject.email).to eq('ik.test@example.com') }

        after { user.destroy! }
      end

      context 'without all needed parameters' do
        let(:user) { described_class.new(
          session,
          'USERFLD_USERID'       => 'ik.test',
          'USERFLD_EMAIL'        => 'ik.test@example.com',
        ) }

        it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_MISSINGFLD/) }
      end
    end

    context 'when updating an existing user' do
      let(:user) { described_class.find(session: session, username: ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON'), domain: domain) }

      context 'and setting correct parameters' do
        let(:previous_email) { user.email }
        let(:current_email) { 'ik.test@example.com' }

        before { expect(previous_email).to_not eq('ik.test@example.com') }

        it { expect { user.email = current_email; subject }.to change { user.email }.from(previous_email).to(current_email) }

        after { user.email = previous_email; user.save! }
      end

      context 'and setting invalid parameters' do
        it { expect { user.locked = 'foobar'; subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_INVDATA/) }
      end
    end
  end

  describe 'destroy!' do
    subject { user.destroy! }

    let!(:user) { described_class.new(
      session,
      'USERFLD_USERID'       => 'ik.test',
      'USERFLD_EMAIL'        => 'ik.test@example.com',
      'USERFLD_DOMAIN'       => domain,
      'USERFLD_LOCAL_AUTH'   => 'Default',
      'USERFLD_BACKEND_AUTH' => 'Default',
      'USERFLD_DISABLED'     => false,
      'USERFLD_LOCKED'       => false,
    ).save! }

    before { expect(described_class.find(session: session, username: 'ik.test', domain: domain)).to be_an_instance_of(described_class) }

    it { expect { subject }.to_not raise_error }
  end

  describe 'clear_password!' do
    subject { user.clear_password! }

    let!(:user) { described_class.new(
      session,
      'USERFLD_USERID'       => 'ik.test',
      'USERFLD_EMAIL'        => 'ik.test@example.com',
      'USERFLD_DOMAIN'       => domain,
      'USERFLD_LOCAL_AUTH'   => 'Default',
      'USERFLD_BACKEND_AUTH' => 'Default',
      'USERFLD_DISABLED'     => false,
      'USERFLD_LOCKED'       => false,
    ).save! }

    before { user.set_password!('NothingToSeeHere.1') }

    it { expect { subject }.to change { user.reload.has_password }.from(true).to(false) }

    context do
      before { user.set_password! 'Frupper.1' }
      before { Identikey::Authentication.validate!('ik.test', domain, 'Frupper.1', client) }
      before { subject }

      it { expect { Identikey::Authentication.validate!('ik.test', domain, 'Frupper.1', client) }.to \
           raise_error(Identikey::OperationFailed).with_message(/STAT_LOCAL_PASSWORD_MISMATCH/) }
    end

    after { user.destroy! }
  end

  describe 'set_password!' do
    subject { user.set_password! 'Frupper.1' }

    let!(:user) { described_class.new(
      session,
      'USERFLD_USERID'       => 'ik.test',
      'USERFLD_EMAIL'        => 'ik.test@example.com',
      'USERFLD_DOMAIN'       => domain,
      'USERFLD_LOCAL_AUTH'   => 'Default',
      'USERFLD_BACKEND_AUTH' => 'Default',
      'USERFLD_DISABLED'     => false,
      'USERFLD_LOCKED'       => false,
    ).save! }

    it { expect { subject }.to change { user.reload.has_password }.from(false).to(true) }

    context do
      before { subject }
      it { expect(Identikey::Authentication.validate!('ik.test', domain, 'Frupper.1', client)).to be(true) }
    end

    after { user.destroy! }
  end

  describe 'unlock!' do
    subject { user.unlock! }

    let!(:user) { described_class.new(
      session,
      'USERFLD_USERID'       => 'ik.test',
      'USERFLD_EMAIL'        => 'ik.test@example.com',
      'USERFLD_DOMAIN'       => domain,
      'USERFLD_LOCAL_AUTH'   => 'Default',
      'USERFLD_BACKEND_AUTH' => 'Default',
      'USERFLD_DISABLED'     => false,
      'USERFLD_LOCKED'       => true,
    ).save! }

    # Lock it
    before { 3.times { Identikey::Authentication.valid_otp?(user.username, user.domain, 'foobar', client) } }

    # Unlock it
    it { expect { subject }.to change { user.reload.locked }.from(true).to(false) }

    after { user.destroy! }

  end

end
