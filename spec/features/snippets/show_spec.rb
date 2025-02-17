# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snippet', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:snippet) { create(:personal_snippet, :public, :repository, author: user) }

  it_behaves_like 'show and render proper snippet blob' do
    let(:anchor) { nil }

    subject do
      visit snippet_path(snippet, anchor: anchor)

      wait_for_requests
    end
  end

  # it_behaves_like 'showing user status' do
  # This will be handled in https://gitlab.com/gitlab-org/gitlab/-/issues/262394

  it_behaves_like 'does not show New Snippet button' do
    let(:file_path) { 'files/ruby/popen.rb' }

    subject { visit snippet_path(snippet) }
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_snippets_path, :snippets

  context 'when unauthenticated' do
    it 'shows the "Explore" sidebar' do
      visit snippet_path(snippet)

      expect(page).to have_css('#super-sidebar-context-header', text: 'Explore')
    end
  end

  context 'when authenticated as a different user' do
    let_it_be(:different_user) { create(:user, :no_super_sidebar) }

    before do
      sign_in(different_user)
    end

    it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_snippets_path, :snippets
  end
end
