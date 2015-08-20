require 'yaml'
require_relative '../../lib/sof/manifest'

module Sof
  describe Manifest do
    before(:each) do
      @manifest = {
        'port' => 22,
        'username' => 'ubuntu',
        'servers' => [
          {
            'name' => 'server1.example.com',
            'categories' => %w(db web fs)
          },
          { 'name' => 'server2.example.com',
            'categories' => %w(web)
          }
        ]
      }
    end

    describe '.get' do
      context 'when yaml file there' do
        before(:each) do
          expect(File).to receive(:file?).with('some_path').and_return(true)
        end
        context 'should return a manifest when' do
          it 'has all of the possible configuration' do
            expect(YAML).to receive(:load_file).with('some_path').and_return(@manifest)
            expect(described_class.get('some_path')).to eq(@manifest)
          end

          it 'does not have username'  do
            @manifest.delete('username')
            expect(YAML).to receive(:load_file).with('some_path').and_return(@manifest)
            expect(described_class.get('some_path')).to eq(@manifest)
          end

          it 'server does not have a category' do
            @manifest['servers'][0].delete('categories')
            expect(YAML).to receive(:load_file).with('some_path').and_return(@manifest)
            expect(described_class.get('some_path')).to eq(@manifest)
          end
        end

        context 'should raise a failure when' do
          it 'missing port' do
            @manifest.delete('port')
            expect(YAML).to receive(:load_file).with('some_path').and_return(@manifest)
            expect do
              described_class.get('some_path')
            end.to raise_error(StandardError, 'Either no port found or bad format in manifest')
          end

          it 'missing servers' do
            @manifest.delete('servers')
            expect(YAML).to receive(:load_file).with('some_path').and_return(@manifest)
            expect do
              described_class.get('some_path')
            end.to raise_error(StandardError, 'Either no servers found or bad format in manifest')
          end

          it 'server missing a name' do
            @manifest['servers'][0].delete('name')
            expect(YAML).to receive(:load_file).with('some_path').and_return(@manifest)
            expect do
              described_class.get('some_path')
            end.to raise_error(StandardError, 'Either no name found or bad format in servers in manifest')
          end
        end
      end
    end
  end
end
