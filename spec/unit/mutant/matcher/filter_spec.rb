RSpec.describe Mutant::Matcher::Filter do
  let(:object)    { described_class.new(matcher, predicate) }
  let(:matcher)   { [subject_a, subject_b]                  }
  let(:subject_a) { double('Subject A')                     }
  let(:subject_b) { double('Subject B')                     }

  describe '#each' do
    let(:yields) { [] }
    subject { object.each { |entry| yields << entry } }

    let(:predicate) { ->(node) { node.eql?(subject_a) } }

    # it_should_behave_like 'an #each method'
    context 'with no block' do
      subject { object.each }

      it { should be_instance_of(to_enum.class) }

      it 'yields the expected values' do
        expect(subject.to_a).to eql(object.to_a)
      end
    end

    it 'should yield subjects' do
      expect { subject }.to change { yields }.from([]).to([subject_a])
    end
  end

  describe '.build' do
    subject { described_class.build(matcher, &predicate) }

    let(:predicate) { ->(_subject) { false } }

    its(:to_a) { should eql([]) }
  end
end
