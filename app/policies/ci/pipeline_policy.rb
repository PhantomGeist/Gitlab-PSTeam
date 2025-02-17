# frozen_string_literal: true

module Ci
  class PipelinePolicy < BasePolicy
    delegate { @subject.project }

    condition(:protected_ref) { ref_protected?(@user, @subject.project, @subject.tag?, @subject.ref) }

    condition(:branch_allows_collaboration) do
      @subject.project.branch_allows_collaboration?(@user, @subject.ref)
    end

    condition(:external_pipeline, scope: :subject, score: 0) do
      @subject.external?
    end

    condition(:triggerer_of_pipeline) do
      @subject.triggered_by?(@user)
    end

    condition(:project_allows_read_dependency) do
      can?(:read_dependency, @subject.project)
    end

    # Disallow users without permissions from accessing internal pipelines
    rule { ~can?(:read_build) & ~external_pipeline }.policy do
      prevent :read_pipeline
    end

    rule { protected_ref }.prevent :update_pipeline

    rule { can?(:public_access) & branch_allows_collaboration }.policy do
      enable :update_pipeline
    end

    rule { can?(:owner_access) }.policy do
      enable :destroy_pipeline
    end

    rule { can?(:admin_pipeline) }.policy do
      enable :read_pipeline_variable
    end

    rule { can?(:update_pipeline) & triggerer_of_pipeline }.policy do
      enable :read_pipeline_variable
    end

    # TODO: splitting out cancel from update in Issue #20207
    rule { can?(:update_pipeline) }.policy do
      enable :cancel_pipeline
    end

    rule { ~can?(:update_pipeline) }.policy do
      prevent :cancel_pipeline
    end

    rule { project_allows_read_dependency }.policy do
      enable :read_dependency
    end

    def ref_protected?(user, project, tag, ref)
      access = ::Gitlab::UserAccess.new(user, container: project)

      if tag
        !access.can_create_tag?(ref)
      else
        !access.can_update_branch?(ref)
      end
    end
  end
end
