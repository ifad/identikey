RSpec.describe Identikey::Authentication do

  describe '.validate!' do
    let(:domain) { ENV.fetch('IK_DOMAIN') }

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
end
