# frozen_string_literal: true

module EE
  module API
    module Projects
      extend ActiveSupport::Concern

      prepended do
        resource :projects do
          desc 'Restore a project' do
            success ::API::Entities::Project
          end
          post ':id/restore', feature_category: :system_access do
            authorize!(:remove_project, user_project)
            break not_found! unless user_project.feature_available?(:adjourned_deletion_for_projects_and_groups)

            result = ::Projects::RestoreService.new(user_project, current_user).execute
            if result[:status] == :success
              present user_project, with: ::API::Entities::Project, current_user: current_user
            else
              render_api_error!(result[:message], 400)
            end
          end
          segment ':id/audit_events', feature_category: :audit_events do
            before do
              authorize! :read_project_audit_events, user_project
              check_audit_events_available!(user_project)
              increment_unique_values('a_compliance_audit_events_api', current_user.id)

              ::Gitlab::Tracking.event(
                'EE::API::Projects',
                'project_audit_event_request',
                user: current_user,
                project: user_project,
                namespace: user_project.namespace,
                context: [
                  ::Gitlab::Tracking::ServicePingContext
                    .new(data_source: :redis_hll, event: 'a_compliance_audit_events_api')
                    .to_context
                ]
              )
            end

            desc 'Get a list of audit events in this project.' do
              success EE::API::Entities::AuditEvent
              is_array true
            end
            params do
              optional :created_after,
                type: DateTime,
                desc: 'Return audit events created after the specified time',
                documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
              optional :created_before,
                type: DateTime,
                desc: 'Return audit events created before the specified time',
                documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }

              use :pagination
            end
            get '/', feature_category: :audit_events, urgency: :low do
              level = ::Gitlab::Audit::Levels::Project.new(project: user_project)
              audit_events = AuditEventFinder.new(
                level: level,
                params: audit_event_finder_params
              ).execute

              present paginate_with_strategies(audit_events), with: EE::API::Entities::AuditEvent
            end

            desc 'Get a specific audit event in this project.' do
              success EE::API::Entities::AuditEvent
            end
            params do
              requires :audit_event_id, type: Integer, desc: 'The ID of the audit event'
            end
            get '/:audit_event_id', feature_category: :audit_events, urgency: :low do
              level = ::Gitlab::Audit::Levels::Project.new(project: user_project)
              # rubocop: disable CodeReuse/ActiveRecord, Rails/FindById
              # This is not `find_by!` from ActiveRecord
              audit_event = AuditEventFinder.new(level: level, params: audit_event_finder_params)
                .find_by!(id: params[:audit_event_id])
              # rubocop: enable CodeReuse/ActiveRecord, Rails/FindById

              present audit_event, with: EE::API::Entities::AuditEvent
            end
          end
        end

        helpers do
          extend ::Gitlab::Utils::Override

          override :verify_update_project_attrs!
          def verify_update_project_attrs!(project, attrs)
            super

            verify_mirror_attrs!(project, attrs)
            validate_git_import_url!(attrs[:import_url])
            verify_issuable_default_templates_attrs!(project, attrs)
            verify_merge_pipelines_attrs!(project, attrs)
          end

          def verify_mirror_attrs!(project, attrs)
            unless can?(current_user, :admin_mirror, project)
              ::Projects::UpdateService::PULL_MIRROR_ATTRIBUTES.each do |attr_name|
                attrs.delete(attr_name)
              end
            end
          end

          def verify_issuable_default_templates_attrs!(project, attrs)
            unless project.feature_available?(:issuable_default_templates)
              attrs.delete(:issues_template)
              attrs.delete(:merge_requests_template)
            end
          end

          def verify_merge_pipelines_attrs!(project, attrs)
            return if can?(current_user, :admin_project, project)

            attrs.delete(:merge_pipelines_enabled) unless project.feature_available?(:merge_pipelines)
            attrs.delete(:merge_trains_enabled) unless project.feature_available?(:merge_trains)
            attrs.delete(:merge_trains_skip_train_allowed) unless project.feature_available?(:merge_trains)
          end

          def check_audit_events_available!(project)
            forbidden! unless project.feature_available?(:audit_events)
          end

          def audit_event_finder_params
            params
              .slice(:created_after, :created_before)
              .then { |params| filter_by_author(params) }
          end

          def filter_by_author(params)
            can?(current_user, :admin_project, user_project) ? params : params.merge(author_id: current_user.id)
          end

          def immediately_delete_project_error(project)
            if !project.marked_for_deletion_at?
              'Project must be marked for deletion first.'
            elsif project.full_path != params[:full_path]
              '`full_path` is incorrect. You must enter the complete path for the project.'
            end
          end

          override :delete_project
          def delete_project(user_project)
            return super unless License.feature_available?(:adjourned_deletion_for_projects_and_groups)
            return super unless user_project.adjourned_deletion_configured?

            if ::Gitlab::Utils.to_boolean(params[:permanently_remove])
              error = immediately_delete_project_error(user_project)
              return super if error.nil?

              render_api_error!(error, 400)
            end

            result = destroy_conditionally!(user_project) do
              ::Projects::MarkForDeletionService.new(user_project, current_user, {}).execute
            end

            if result[:status] == :success
              accepted!
            else
              render_api_error!(result[:message], 400)
            end
          end
        end
      end
    end
  end
end
