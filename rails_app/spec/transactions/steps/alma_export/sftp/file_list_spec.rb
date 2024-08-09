# frozen_string_literal: true

describe Steps::AlmaExport::Sftp::FileList do
  include_context 'with sftp files available'

  let(:result) { described_class.new(type: type).call(alma_export: alma_export, sftp_session: sftp_client) }
  let(:alma_export) { create(:alma_export) }

  context 'with an invalid list type' do
    let(:type) { 'invalid' }

    it 'raises an ArgumentError' do
      expect { result }.to raise_error(ArgumentError, /unsupported type/i)
    end
  end

  context 'with "record" list type' do
    let(:type) { described_class::RECORD_TYPE }
    let(:sftp_files) { sftp_filenames.map { |name| Sftp::File.new(name) } }
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

    context 'with an unnumbered _new file' do
      let(:sftp_filenames) do
        ['.', '..', # returned by dir.entries command, ignore
         'prefix_12345678_2023010100_new.tar.gz', # good file
         'prefix_55555555_2023010100_new.zip', # wrong ID
         'prefix_12345678_2023010100_delete.zip'] # delete file
      end

      it 'only selects the singular new file' do
        expect(result.success[:file_list].map(&:name)).to match_array(sftp_filenames[2])
      end
    end
  end

  context 'with "delete" list type' do
    let(:type) { described_class::DELETE_TYPE }
    let(:sftp_files) { sftp_filenames.map { |name| Sftp::File.new(name) } }
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

    context 'with multiple delete files' do
      let(:sftp_filenames) do
        ['.', '..', # returned by dir.entries command, ignore
         'prefix_55555555_2023010100_delete.tar.gz', # wrong job id
         'prefix_55555555_2023010100_delete_1.tar.gz', # wrong job id
         'prefix_12345678_2023010100_delete_1.tar.gz', # first delete file
         'prefix_12345678_2023010100_delete_2.tar.gz', # second delete file
         'prefix_12345678_2023010100_delete_1.zip'] # wrong extension
      end

      it 'selects multiple _delete files' do
        expect(result.success[:file_list].map(&:name)).to match_array(sftp_filenames[4..5])
      end
    end
  end

  context 'with an unexpected SFTP error' do
    let(:type) { described_class::RECORD_TYPE }
    let(:error_message) { 'Unexpected error (Sftp::Client::Error) during SFTP list: Kaboom' }

    before { allow(sftp_client).to receive(:files).and_raise(Sftp::Client::Error, 'Kaboom') }

    it 'returns a failure monad with appropriate message' do
      expect(result.failure[:message]).to include error_message
      expect(alma_export.reload.error_messages).to include error_message
    end
  end

  context 'with no files matching on SFTP server' do
    let(:type) { described_class::RECORD_TYPE }
    let(:sftp_client) { instance_double Sftp::Client }
    let(:sftp_files) { [] }

    before { allow(sftp_client).to receive(:files).and_return(sftp_files) }

    it 'returns a success monad and an empty array' do
      expect(result).to be_success
      expect(result.success[:file_list]).to eq []
    end
  end
end
