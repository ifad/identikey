RSpec.describe Identikey::Authentication do
  let(:domain) { ENV.fetch('IK_DOMAIN') }

  describe '.validate!' do
    subject { Identikey::Authentication.validate!(user, domain, otp) }

    context 'given an user with no tokens assigned'  do
      let(:user) { ENV.fetch('IK_UNASSIGNED_TOKEN_PERSON') }
      let(:otp) { '123456' }

      it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_LOCAL_PASSWORD_MISMATCH/) }
    end

    context 'given an user with a token assigned' do
      let(:user) { ENV.fetch('IK_ASSIGNED_TOKEN_1_PERSON') }

      let(:dpx_filename)  { ENV.fetch('IK_ASSIGNED_TOKEN_1_DPX') }
      let(:transport_key) { ENV.fetch('IK_ASSIGNED_TOKEN_1_TRANSPORT_KEY') }
      let(:serial)        { ENV.fetch('IK_ASSIGNED_TOKEN_1_NUMBER') }
      let(:vacman_token)  { VacmanController::Token.import(dpx_filename, transport_key).find {|t| t.serial == serial } }

      context 'and a bad OTP' do
        let(:otp) { '313370' }

        it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_OTP_INCORRECT/) }
      end

      context 'and a bad PIN' do
        let(:otp) { '0000' + vacman_token.generate }

        it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/STAT_OTP_INCORRECT/) }
      end

      context 'and a good PIN + OTP combination' do
        let(:otp) { ENV.fetch('IK_ASSIGNED_TOKEN_1_PIN') + vacman_token.generate }

        it { expect(subject).to be(true) }
      end
    end
  end

  describe 'valid_otp?' do
    subject { Identikey::Authentication.valid_otp?(user, domain, otp) }

    context 'given an user with a token assigned' do
      let(:user) { ENV.fetch('IK_ASSIGNED_TOKEN_2_PERSON') }

      let(:dpx_filename)  { ENV.fetch('IK_ASSIGNED_TOKEN_2_DPX') }
      let(:transport_key) { ENV.fetch('IK_ASSIGNED_TOKEN_2_TRANSPORT_KEY') }
      let(:serial)        { ENV.fetch('IK_ASSIGNED_TOKEN_2_NUMBER') }
      let(:vacman_token)  { VacmanController::Token.import(dpx_filename, transport_key).find {|t| t.serial == serial } }

      context 'and a bad OTP' do
        let(:otp) { '313370' }

        it { expect(subject).to be(false) }
      end

      context 'and a bad PIN' do
        let(:otp) { '0000' + vacman_token.generate }

        it { expect(subject).to be(false) }
      end

      context 'and a good PIN + OTP combination' do
        let(:otp) { ENV.fetch('IK_ASSIGNED_TOKEN_2_PIN') + vacman_token.generate }

        it { expect(subject).to be(true) }
      end
    end
  end

  context do
    subject { Identikey::Authentication.validate!(user, domain, pass, client) }

    context 'given an otp-only policy' do
      let(:client) { ENV.fetch('IK_DIGIPASS_ONLY_CLIENT') }

      context 'and an user authenticating with password' do
        let(:user) { ENV.fetch('IK_STATIC_PASSWORD_USER') }
        let(:pass) { ENV.fetch('IK_STATIC_PASSWORD_PASS') }

        it { expect { subject }.to raise_error(Identikey::OperationFailed).with_message(/GRACE_PERIOD_EXPIRED/) }
      end

      context 'and an user authenticating with OTP' do
        let(:dpx_filename)  { ENV.fetch('IK_ASSIGNED_TOKEN_3_DPX') }
        let(:transport_key) { ENV.fetch('IK_ASSIGNED_TOKEN_3_TRANSPORT_KEY') }
        let(:serial)        { ENV.fetch('IK_ASSIGNED_TOKEN_3_NUMBER') }
        let(:vacman_token)  { VacmanController::Token.import(dpx_filename, transport_key).find {|t| t.serial == serial } }

        let(:user) { ENV.fetch('IK_ASSIGNED_TOKEN_3_PERSON') }
        let(:pass) { ENV.fetch('IK_ASSIGNED_TOKEN_3_PIN') + vacman_token.generate }

        it { expect { subject }.to_not raise_error }
      end
    end

    context 'given a password-permitted policy' do
      let(:client) { ENV.fetch('IK_STATIC_PASSWORD_CLIENT') }

      context 'and an user authenticating with password' do
        let(:user) { ENV.fetch('IK_STATIC_PASSWORD_USER') }
        let(:pass) { ENV.fetch('IK_STATIC_PASSWORD_PASS') }

        it { expect { subject }.to_not raise_error }
      end

      context 'and an user authenticating with OTP' do
        let(:dpx_filename)  { ENV.fetch('IK_ASSIGNED_TOKEN_4_DPX') }
        let(:transport_key) { ENV.fetch('IK_ASSIGNED_TOKEN_4_TRANSPORT_KEY') }
        let(:serial)        { ENV.fetch('IK_ASSIGNED_TOKEN_4_NUMBER') }
        let(:vacman_token)  { VacmanController::Token.import(dpx_filename, transport_key).find {|t| t.serial == serial } }

        let(:user) { ENV.fetch('IK_ASSIGNED_TOKEN_4_PERSON') }
        let(:pass) { ENV.fetch('IK_ASSIGNED_TOKEN_4_PIN') + vacman_token.generate }

        it { expect { subject }.to_not raise_error }
      end
    end
  end
end
