# frozen_string_literal: true

##
# DEPRECATED
#
# These helpers are deprecated in favor of detailed CI/CD statuses.
#
# See 'detailed_status?` method and `Gitlab::Ci::Status` module.
#
module Ci
  module StatusHelper
    def ci_status_for_statuseable(subject)
      status = subject.try(:status) || 'not found'
      status.humanize
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def ci_icon_for_status(status, size: 16)
      icon_name =
        if detailed_status?(status)
          status.icon
        else
          case status
          when 'success'
            'status_success'
          when 'success-with-warnings'
            'status_warning'
          when 'failed'
            'status_failed'
          when 'pending'
            'status_pending'
          when 'waiting-for-resource'
            'status_pending'
          when 'preparing'
            'status_preparing'
          when 'running'
            'status_running'
          when 'play'
            'play'
          when 'created'
            'status_created'
          when 'skipped'
            'status_skipped'
          when 'manual'
            'status_manual'
          when 'scheduled'
            'status_scheduled'
          else
            'status_canceled'
          end
        end

      sprite_icon(icon_name, size: size, css_class: 'gl-icon')
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def ci_icon_class_for_status(status)
      group = detailed_status?(status) ? status.group : status.dasherize

      "ci-status-icon-#{group}"
    end

    def pipeline_status_cache_key(pipeline_status)
      "pipeline-status/#{pipeline_status.sha}-#{pipeline_status.status}"
    end

    def render_commit_status(commit, status, ref: nil, tooltip_placement: 'left')
      project = commit.project
      path = pipelines_project_commit_path(project, commit, ref: ref)

      render_ci_icon(
        status,
        path,
        tooltip_placement: tooltip_placement,
        option_css_classes: 'gl-ml-3'
      )
    end

    def render_ci_icon(
      status,
      path = nil,
      tooltip_placement: 'left',
      option_css_classes: '',
      container: 'body',
      show_status_text: false
    )
      variant = badge_variant(status)
      klass = "js-ci-status-badge-legacy ci-status-icon #{ci_icon_class_for_status(status)} gl-rounded-full gl-justify-content-center gl-line-height-0"
      title = "#{_('Pipeline')}: #{ci_label_for_status(status)}"
      data = { toggle: 'tooltip', placement: tooltip_placement, container: container, testid: 'ci-icon' }
      badge_classes = "ci-icon gl-p-2 #{option_css_classes}"

      gl_badge_tag(variant: variant, size: :md, href: path, class: badge_classes, title: title, data: data) do
        if show_status_text
          content_tag(:span, ci_icon_for_status(status), { class: klass }) + content_tag(:span, status.label, { class: 'gl-mx-2 gl-white-space-nowrap' })
        else
          content_tag(:span, ci_icon_for_status(status), { class: klass })
        end
      end
    end

    private

    def detailed_status?(status)
      status.respond_to?(:text) &&
        status.respond_to?(:group) &&
        status.respond_to?(:label) &&
        status.respond_to?(:icon)
    end

    def ci_label_for_status(status)
      if detailed_status?(status)
        return status.label
      end

      label = case status
              when 'success'
                'passed'
              when 'success-with-warnings'
                'passed with warnings'
              when 'manual'
                'waiting for manual action'
              when 'scheduled'
                'waiting for delayed job'
              else
                status
              end
      translation = "CiStatusLabel|#{label}"
      s_(translation)
    end

    def badge_variant(status)
      variant = detailed_status?(status) ? status.group : status.dasherize

      case variant
      when 'success'
        :success
      when 'success-with-warnings', 'pending'
        :warning
      when 'failed'
        :danger
      when 'running'
        :info
      when 'canceled', 'manual'
        :neutral
      else
        :muted
      end
    end
  end
end
