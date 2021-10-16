require 'sof'

describe 'sof check-server', type: :system do
  subject do
      {
        stdout: `bundle exec sof check-server --no-include-base --manifest #{manifest_file}`,
        exit_status: $?.exitstatus
      }
  end

  context 'localhost' do
    let(:manifest_file) { 'spec/system/assets/local_manifest.yml'}

    it 'should output "Running checks:"' do
      expect(subject[:stdout]).to match(/Running checks:/)
    end

    it 'should succeed' do
      expect(subject[:exit_status]).to eq(0)
    end
  end

  context 'localhost failure' do
    let(:manifest_file) { 'spec/system/assets/local_failure_manifest.yml'}

    it 'should output "Running checks:"' do
      expect(subject[:stdout]).to match(/Running checks:/)
    end

    it 'should fail' do
      expect(subject[:exit_status]).to eq(Sof::FAILURE_EXIT_CODE)
    end
  end
end
