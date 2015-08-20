require 'yaml'
require_relative '../../lib/sof/check'
require_relative 'mocks/check_mock'

module Sof
  describe Check do

    let(:record1) { { 'type' => 'check_mock', 'name' => 'thename1', 'command' => 'thecommand1', 'category' => ['base'] } }
    let(:record2) { { 'type' => 'check_mock', 'name' => 'thename1', 'command' => 'thecommand2', 'category' => ['cat1', 'cat2'] } }
    let(:record3) { { 'type' => 'check_mock', 'name' => 'thename2', 'command' => 'thecommand3', 'category' => ['cat2'] } }
    let(:record4) { { 'type' => 'check_mock', 'name' => 'thename3', 'command' => 'thecommand3', 'category' => ['cat3'] } }
    let(:records) { [record1, record2, record3, record4] }
    let(:base_object) { described_class.new(record1) }

    describe '.new' do
      it 'should have type, name, and command accessors' do
        expect(base_object.type).to eq(record1['type'])
        expect(base_object.name).to eq(record1['name'])
        expect(base_object.command).to eq(record1['command'])
      end
    end

    describe '.load' do
      before(:each) do
        described_class::CHECK_PATHS.each do |path|
          expect(Dir).to receive(:glob).with("#{path}/*.yml").and_yield('path').and_yield('path').and_yield('path').and_yield('path')
          records.each do |record|
            expect(YAML).to receive(:load_file).with("path").and_return(record).once
          end
        end
      end

      it 'should return base category when no catagories are given' do
        expect(Sof::Checks).to receive(:class_from_type).with('check_mock').and_return(Sof::Checks::CheckMock).once
        check_mocks = described_class.load([], {})
        expect_record_in_array_of_check_mocks(record1, check_mocks)
      end

      it 'should return only catagory cat1 without base if name overrides' do
        expect(Sof::Checks).to receive(:class_from_type).with('check_mock').and_return(Sof::Checks::CheckMock).once
        check_mocks = described_class.load(['cat1'], {})
        expect_record_in_array_of_check_mocks(record2, check_mocks)
      end

      it 'should return only catagory cat2' do
        expect(Sof::Checks).to receive(:class_from_type).with('check_mock').and_return(Sof::Checks::CheckMock).twice
        check_mocks = described_class.load(['cat2'], {})
        expect_record_in_array_of_check_mocks(record2, check_mocks)
        expect_record_in_array_of_check_mocks(record3, check_mocks)
      end

      it 'should return catogories cat1 and cat3' do
        expect(Sof::Checks).to receive(:class_from_type).with('check_mock').and_return(Sof::Checks::CheckMock).twice
        check_mocks = described_class.load(['cat1', 'cat3'], {})
        expect_record_in_array_of_check_mocks(record2, check_mocks)
        expect_record_in_array_of_check_mocks(record4, check_mocks)
      end
    end

    def expect_record_in_array_of_check_mocks(record, check_mocks)
      found = false
      check_mocks.each do |check_mock|
        if record['command'] == check_mock.command
          found = true
          expect(check_mock.class).to eq(Sof::Checks::CheckMock)
          break
        end
      end
      expect(found).to eq(true)
    end
  end
end
