# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update Instance Google Cloud logging configuration', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be_with_reload(:config) { create(:instance_google_cloud_logging_configuration) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:updated_google_project_id_name) { 'updated-project' }
  let_it_be(:updated_client_email) { 'updated-email@example.com' }
  let_it_be(:updated_private_key) { OpenSSL::PKey::RSA.new(4096).to_pem }
  let_it_be(:updated_log_id_name) { 'updated_log_id_name' }
  let_it_be(:updated_destination_name) { 'updated_destination_name' }
  let_it_be(:config_gid) { global_id_of(config) }

  let(:current_user) { admin }
  let(:mutation) { graphql_mutation(:instance_google_cloud_logging_configuration_update, input) }
  let(:mutation_response) { graphql_mutation_response(:instance_google_cloud_logging_configuration_update) }

  let(:input) do
    {
      id: config_gid,
      googleProjectIdName: updated_google_project_id_name,
      clientEmail: updated_client_email,
      privateKey: updated_private_key,
      logIdName: updated_log_id_name,
      name: updated_destination_name
    }
  end

  subject(:mutate) { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a mutation that does not update the configuration' do
    it 'does not update the configuration' do
      expect { mutate }.not_to change { config.reload.attributes }
    end

    it 'does not create audit event' do
      expect { mutate }.not_to change { AuditEvent.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is instance admin' do
      before do
        allow(Gitlab::Audit::Auditor).to receive(:audit)
      end

      it 'updates the configuration' do
        mutate

        config.reload

        expect(config.google_project_id_name).to eq(updated_google_project_id_name)
        expect(config.client_email).to eq(updated_client_email)
        expect(config.private_key).to eq(updated_private_key)
        expect(config.log_id_name).to eq(updated_log_id_name)
        expect(config.name).to eq(updated_destination_name)
      end

      it 'audits the update' do
        Mutations::AuditEvents::Instance::GoogleCloudLoggingConfigurations::Update::AUDIT_EVENT_COLUMNS.each do |column|
          message = if column == :private_key
                      "Changed #{column}"
                    else
                      "Changed #{column} from #{config[column]} to #{input[column.to_s.camelize(:lower).to_sym]}"
                    end

          expected_hash = {
            name: Mutations::AuditEvents::Instance::GoogleCloudLoggingConfigurations::Update::UPDATE_EVENT_NAME,
            author: current_user,
            scope: an_instance_of(Gitlab::Audit::InstanceScope),
            target: config,
            message: message,
            target_details: updated_destination_name
          }

          expect(Gitlab::Audit::Auditor).to receive(:audit).once.ordered.with(hash_including(expected_hash))
        end

        subject
      end

      context 'when the fields are updated with existing values' do
        let(:input) do
          {
            id: config_gid,
            googleProjectIdName: config.google_project_id_name,
            name: config.name
          }
        end

        it 'does not audit the event' do
          expect(Gitlab::Audit::Auditor).not_to receive(:audit)

          subject
        end
      end

      context 'when no fields are provided for update' do
        let(:input) do
          {
            id: config_gid
          }
        end

        it_behaves_like 'a mutation that does not update the configuration'
      end

      context 'when there is error while updating' do
        before do
          allow_next_instance_of(
            Mutations::AuditEvents::Instance::GoogleCloudLoggingConfigurations::Update) do |mutation|
            allow(mutation).to receive(:authorized_find!).with(config_gid).and_return(config)
          end

          allow(config).to receive(:update).and_return(false)

          errors = ActiveModel::Errors.new(config).tap { |e| e.add(:base, 'error message') }
          allow(config).to receive(:errors).and_return(errors)
        end

        it 'does not update the configuration and returns the error' do
          mutate

          expect(mutation_response).to include(
            'instanceGoogleCloudLoggingConfiguration' => nil,
            'errors' => ['error message']
          )
        end
      end
    end

    context 'when current user is not instance admin' do
      let_it_be(:current_user) { create(:user) }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      it_behaves_like 'a mutation that does not update the configuration'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    it_behaves_like 'a mutation that does not update the configuration'
  end
end
