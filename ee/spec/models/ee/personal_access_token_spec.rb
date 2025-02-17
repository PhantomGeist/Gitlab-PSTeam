# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessToken, feature_category: :system_access do
  describe 'associations' do
    subject { create(:personal_access_token) }

    it do
      is_expected
        .to have_one(:workspace)
              .class_name('RemoteDevelopment::Workspace')
              .inverse_of(:personal_access_token)
              .with_foreign_key(:personal_access_token_id)
    end

    it 'has a bidirectional relationship with a workspace' do
      workspace = create(:workspace, personal_access_token: subject)

      expect(workspace.personal_access_token).to eq(subject)
    end
  end

  describe 'scopes' do
    let_it_be(:expiration_date) { 30.days.from_now }
    let_it_be(:pat) { create(:personal_access_token, expires_at: expiration_date) }
    let_it_be(:expired_token) { create(:personal_access_token, expires_at: 1.day.ago) }
    let_it_be(:valid_token) { create(:personal_access_token, expires_at: 1.day.from_now) }
    let_it_be(:long_expiry_token) do
      create(
        :personal_access_token,
        expires_at: Date.current + described_class::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS
      )
    end

    describe 'with_expires_at_after' do
      subject { described_class.with_expires_at_after(2.days.from_now) }

      let(:expiration_date) { 3.days.from_now }

      it 'includes the tokens with higher than the lifetime expires_at value' do
        expect(subject).to contain_exactly(pat, long_expiry_token)
      end

      it "doesn't contain expired tokens" do
        expect(subject).not_to include(expired_token)
      end

      it "doesn't contain tokens within the expiration time" do
        expect(subject).not_to include(valid_token)
      end
    end

    describe 'expires_in' do
      subject { described_class.expires_in(1.day.from_now) }

      it 'only includes one token' do
        expect(subject).to contain_exactly(valid_token)
      end
    end
  end

  describe 'validations' do
    let(:user) { build(:user) }
    let(:personal_access_token) { build(:personal_access_token, user: user) }

    context 'with expiration policy' do
      let(:instance_level_pat_expiration_policy) { 30 }
      let(:instance_level_max_expiration_date) { Date.current + instance_level_pat_expiration_policy }

      before do
        stub_ee_application_setting(max_personal_access_token_lifetime: instance_level_pat_expiration_policy)
      end

      shared_examples_for 'PAT expiry rules are enforced' do
        it 'requires to be less or equal than the max_personal_access_token_lifetime', :freeze_time do
          personal_access_token.expires_at = max_expiration_date + 1

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors.full_messages.to_sentence).to eq(
            "Expiration date must be before #{max_expiration_date}"
          )
        end

        it "is invalid" do
          personal_access_token.expires_at = nil

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors[:expires_at].first).to eq("can't be blank")
        end
      end

      context 'when the feature is licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: true)
        end

        context 'when the user does not belong to a managed group' do
          it_behaves_like 'PAT expiry rules are enforced' do
            let(:max_expiration_date) { instance_level_max_expiration_date }
          end
        end

        context 'when the user belongs to a managed group' do
          let(:group_level_pat_expiration_policy) { nil }
          let(:group) do
            build(:group_with_managed_accounts, max_personal_access_token_lifetime: group_level_pat_expiration_policy)
          end

          let(:user) { build(:user, managing_group: group) }

          context 'when the group has enforced a PAT expiry rule' do
            let(:group_level_pat_expiration_policy) { 20 }
            let(:group_level_max_expiration_date) { Date.current + group_level_pat_expiration_policy }

            it_behaves_like 'PAT expiry rules are enforced' do
              let(:max_expiration_date) { group_level_max_expiration_date }
            end
          end

          context 'when the group has not enforced a PAT expiry setting' do
            context 'when the instance has enforced a PAT expiry setting' do
              it_behaves_like 'PAT expiry rules are enforced' do
                let(:max_expiration_date) { instance_level_max_expiration_date }
              end
            end
          end
        end
      end
    end
  end

  describe '.pluck_names' do
    it 'returns the names of the tokens' do
      pat1 = create(:personal_access_token)
      pat2 = create(:personal_access_token)

      expect(described_class.pluck_names).to contain_exactly(pat1.name, pat2.name)
    end
  end

  describe '.with_invalid_expires_at' do
    subject { described_class.with_invalid_expires_at(2.days.from_now) }

    it 'includes the tokens with invalid expires_at' do
      pat_with_longer_expires_at = create(:personal_access_token, expires_at: 3.days.from_now)

      expect(subject).to contain_exactly(pat_with_longer_expires_at)
    end

    it "doesn't include valid tokens" do
      valid_token = create(:personal_access_token, expires_at: 1.day.from_now)

      expect(subject).not_to include(valid_token)
    end

    it "doesn't include revoked tokens" do
      revoked_token = create(:personal_access_token, revoked: true)

      expect(subject).not_to include(revoked_token)
    end

    it "doesn't include expired tokens" do
      expired_token = create(:personal_access_token, expires_at: 1.day.ago)

      expect(subject).not_to include(expired_token)
    end
  end

  describe '.find_by_token' do
    let!(:token) { create(:personal_access_token) }

    it 'finds the token' do
      expect(described_class.find_by_token(token.token)).to eq(token)
    end

    context 'when disable_personal_access_tokens feature is available' do
      before do
        stub_licensed_features(disable_personal_access_tokens: true)
      end

      context 'when personal access tokens are disabled' do
        before do
          stub_application_setting(disable_personal_access_tokens: true)
        end

        it 'does not find the token' do
          expect(described_class.find_by_token(token.token)).to be_nil
        end
      end

      context 'when personal access tokens are not disabled' do
        it 'finds the token' do
          expect(described_class.find_by_token(token.token)).to eq(token)
        end
      end
    end
  end

  shared_context 'write to cache' do
    let_it_be(:pat) { create(:personal_access_token) }
    let_it_be(:cache_keys) { %w[token_expired_rotation token_expiring_rotation] }

    before do
      cache_keys.each do |key|
        Rails.cache.write(['users', pat.user.id, key], double)
      end
    end
  end

  describe '#revoke', :use_clean_rails_memory_store_caching do
    include_context 'write to cache'

    it 'clears cache on revoke access' do
      pat.revoke!

      cache_keys.each do |key|
        expect(Rails.cache.read(['users', pat.user.id, key])).to be_nil
      end
    end
  end

  describe 'after create callback', :use_clean_rails_memory_store_caching do
    include_context 'write to cache'

    it 'clears cache for the user' do
      create(:personal_access_token, user_id: pat.user_id)

      cache_keys.each do |key|
        expect(Rails.cache.read(['users', pat.user.id, key])).to be_nil
      end
    end
  end
end
