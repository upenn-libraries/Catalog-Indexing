# frozen_string_literal: true

describe Steps::AlmaExport::Sftp::FileList do
  let(:result) { described_class.new(type: type).call(alma_export: alma_export, sftp_session: sftp_client) }
  let(:alma_export) { create(:alma_export) }
  let(:type) { described_class::RECORD_TYPE }

  context 'with an invalid list type' do
    let(:type) { 'invalid' }

    it 'raises an ArgumentError' do
      expect { result }.to raise_error(ArgumentError, /unsupported type/i)
    end
  end

  context 'when listing only certain files' do
    include_context 'with sftp files available'

    let(:sftp_files) { sftp_filenames.map { |name| Sftp::File.new(name) } }

    context 'with "record" list type' do
      let(:sftp_filenames) do
        ['.', '..', # returned by dir.entries command, ignore
         'prefix_12345678_2023010100_new_1.zip', # wrong extension
         'prefix_55555555_2023010100_new_1.xml.tar.gz', # wrong job id
         'prefix_12345678_2023010100_delete.tar.gz', # delete file
         'prefix_12345678_2023010100_new_1.tar.gz',
         'prefix_12345678_2023010100_new_23.tar.gz',
         'prefix_12345678_2023010100_new_900.tar.gz']
      end

      it 'returns only record type files and the alma_export' do
        expect(result.success[:file_list].map(&:name)).to match_array(sftp_filenames[5..7])
        expect(result.success[:alma_export]).to eq alma_export
      end
    end

    context 'with "delete" list type' do
      let(:type) { described_class::DELETE_TYPE }
      let(:sftp_filenames) do
        ['.', '..', # returned by dir.entries command, ignore
         'prefix_55555555_2023010100_delete.tar.gz', # wrong job id
         'prefix_12345678_2023010100_new_1.tar.gz', # record file
         'prefix_12345678_2023010100_new_1.zip', # wrong extension
         'prefix_55555555_2023010100_new_1.xml.tar.gz', # wrong job id
         'prefix_12345678_2023010100_delete.tar.gz']
      end

      it 'returns only delete type files and the alma_export' do
        expect(result.success[:file_list].map(&:name)).to match_array(['prefix_12345678_2023010100_delete.tar.gz'])
        expect(result.success[:alma_export]).to eq alma_export
      end
    end
  end

  context 'with an unexpected SFTP error' do
    let(:error_message) { 'Unexpected error (Sftp::Client::Error) during SFTP list: Kaboom' }

    include_context 'with sftp files available'

    before { allow(sftp_client).to receive(:files).and_raise(Sftp::Client::Error, 'Kaboom') }

    it 'returns a failure monad with appropriate message' do
      expect(result.failure[:message]).to include error_message
      expect(alma_export.reload.error_messages).to include error_message
    end
  end

  context 'with no files matching on SFTP server' do
    let(:sftp_client) { instance_double Sftp::Client }
    let(:sftp_files) { [] }

    before { allow(sftp_client).to receive(:files).and_return(sftp_files) }

    it 'returns a failure monad with appropriate message' do
      expect(result.failure[:message]).to include "No SFTP #{type} file(s) available"
      expect(alma_export.reload.error_messages).to include result.failure[:message]
    end
  end
end
