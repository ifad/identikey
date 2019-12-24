RSpec.describe Identikey::Administration::Session do

  username = ENV.fetch('IK_USER')
  password = ENV.fetch('IK_PASS')
  domain   = ENV.fetch('IK_DOMAIN', 'master')
  session  = Identikey::Administration::Session.new username: username, password: password, domain: domain

  before(:all) { session.logon }
  after(:all) { session.logoff }

  context 'helpers' do
    describe '.find_digipass' do
      subject { session.find_digipass(serial) }

      let(:tokens) { [
        'IK_ASSIGNED_TOKEN_1_NUMBER', 'IK_ASSIGNED_TOKEN_2_NUMBER', 'IK_UNASSIGNED_TOKEN_1_NUMBER',
        'IK_UNASSIGNED_TOKEN_2_NUMBER', 'IK_UNASSIGNED_TOKEN_3_NUMBER', 'IK_UNASSIGNED_TOKEN_4_NUMBER'
      ] }

      let(:serial) { ENV.fetch(tokens.sample) }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(Identikey::Administration::Digipass) }
      it { expect(subject.serial).to eq(serial) }
    end

    describe '.search_digipasses' do
      subject { session.search_digipasses(status: 'Assigned', options: { limit: 3 }) }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(Array) }
      it { expect(subject.first).to be_a(Identikey::Administration::Digipass) }
      it { expect(subject.size).to be >= 2 }
    end

    describe '.find_user' do
      subject { session.find_user(username) }

      let(:users) { [
        'IK_ASSIGNED_TOKEN_1_PERSON', 'IK_ASSIGNED_TOKEN_2_PERSON', 'IK_UNASSIGNED_TOKEN_PERSON'
      ] }

      let(:username) { ENV.fetch(users.sample) }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(Identikey::Administration::User) }
      it { expect(subject.username).to eq(username) }
    end

    describe '.search_users' do
      subject { session.search_users(has_digipass: true, options: { limit: 3 }) }

      it { expect { subject }.to_not raise_error }
      it { expect(subject).to be_a(Array) }
      it { expect(subject.first).to be_a(Identikey::Administration::User) }
      it { expect(subject.size).to be >= 2 }
    end
  end

end
