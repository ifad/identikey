RSpec.describe Identikey::Base do

  describe '.configure' do
    let(:model) { Class.new(described_class) }
    before { model.client(wsdl: 'fake.wsdl') }

    context 'endpoint' do
      subject { model.configure { endpoint 'foo' } }

      it { expect { subject }.to_not raise_error }
      it { expect { subject }.to change { model.client.globals[:endpoint] }.from('https://localhost:8888/').to('foo') }
    end

    context 'wsdl' do
      subject { model.configure { wsdl 'foobar.wsdl' } }

      it { expect { subject }.to_not raise_error }
      it { expect { subject }.to change { model.client.globals[:wsdl] }.from('fake.wsdl').to('foobar.wsdl') }
      it { expect { subject }.to change { model.client.wsdl.document }.from('fake.wsdl').to('foobar.wsdl') }
    end
  end

end
