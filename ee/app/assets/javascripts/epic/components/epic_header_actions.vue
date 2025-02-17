<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { TYPE_EPIC } from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import issuesEventHub from '~/issues/show/event_hub';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import toast from '~/vue_shared/plugins/global_toast';

export default {
  TYPE_EPIC,
  deleteModalId: 'delete-modal-id',
  i18n: {
    copyReferenceText: __('Copy reference'),
    deleteButtonText: __('Delete epic'),
    dropdownText: __('Epic actions'),
    edit: __('Edit'),
    editTitleAndDescription: __('Edit title and description'),
    newEpicText: __('New epic'),
    reportAbuse: __('Report abuse to administrator'),
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    DeleteIssueModal,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    SidebarSubscriptionsWidget,
    AbuseCategorySelector,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath', 'iid'],
  data() {
    return {
      isReportAbuseDrawerOpen: false,
    };
  },
  computed: {
    ...mapState([
      'author',
      'canCreate',
      'canUpdate',
      'canDestroy',
      'newEpicWebUrl',
      'webUrl',
      'reference',
    ]),
    ...mapGetters(['isEpicOpen', 'isEpicAuthor']),
    actionButtonText() {
      return this.isEpicOpen ? __('Close epic') : __('Reopen epic');
    },
    isMrSidebarMoved() {
      return this.glFeatures.movedMrSidebar;
    },
    showDesktopDropdown() {
      return this.canCreate || this.canDestroy || this.isMrSidebarMoved;
    },
    showMobileDropdown() {
      return this.showDesktopDropdown || this.canUpdate;
    },
    showNotificationToggle() {
      return this.isMrSidebarMoved && isLoggedIn();
    },
    newEpicDropdownItem() {
      return {
        text: this.$options.i18n.newEpicText,
        href: this.newEpicWebUrl,
      };
    },
    copyReferenceDropdownItem() {
      return {
        text: this.$options.i18n.copyReferenceText,
        action: this.closeDropdownAfterAction.bind(this, this.copyReference),
        extraAttrs: {
          'data-clipboard-text': this.reference,
          class: 'js-copy-reference',
        },
      };
    },
    toggleEpicStatusDropdownItem() {
      return {
        text: this.actionButtonText,
        action: this.closeDropdownAfterAction.bind(
          this,
          this.toggleEpicStatus.bind(this, this.isEpicOpen),
        ),
        extraAttrs: {
          'data-testid': 'toggle-status-button',
        },
      };
    },
    actionsDropdownGroupMobile() {
      const items = [];

      if (this.canUpdate) {
        items.push({
          text: this.$options.i18n.edit,
          action: this.closeDropdownAfterAction.bind(this, this.editEpic),
        });
      }

      if (this.canCreate) {
        items.push(this.newEpicDropdownItem);
      }

      if (this.canUpdate) {
        items.push(this.toggleEpicStatusDropdownItem);
      }

      if (this.isMrSidebarMoved) {
        items.push(this.copyReferenceDropdownItem);
      }

      return { items };
    },
    actionsDropdownGroupDesktop() {
      const items = [];

      if (this.canUpdate) {
        items.push(this.toggleEpicStatusDropdownItem);
      }

      if (this.canCreate) {
        items.push(this.newEpicDropdownItem);
      }

      if (this.isMrSidebarMoved) {
        items.push(this.copyReferenceDropdownItem);
      }

      return { items };
    },
    canReportAbuseToAdmin() {
      return !this.isEpicAuthor;
    },
    authorId() {
      return this.author?.id;
    },
  },
  methods: {
    ...mapActions(['toggleEpicStatus']),
    closeDropdownAfterAction(action) {
      action();
      this.closeActionsDropdown();
    },
    copyReference() {
      toast(__('Reference copied'));
    },
    editEpic() {
      issuesEventHub.$emit('open.form');
    },
    closeActionsDropdown() {
      this.$refs.epicActionsDropdownMobile?.close();
      this.$refs.epicActionsDropdownDesktop?.close();
    },
    toggleReportAbuseDrawer(isOpen) {
      this.isReportAbuseDrawerOpen = isOpen;
    },
  },
};
</script>

<template>
  <div class="gl-display-contents">
    <gl-disclosure-dropdown
      v-if="showMobileDropdown"
      ref="epicActionsDropdownMobile"
      class="gl-display-block gl-sm-display-none! gl-w-full gl-mt-3"
      category="secondary"
      :auto-close="false"
      toggle-class="gl-w-full"
      :toggle-text="$options.i18n.dropdownText"
    >
      <gl-disclosure-dropdown-group
        v-if="showNotificationToggle && !glFeatures.notificationsTodosButtons"
      >
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_EPIC"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        data-testid="actions-dropdown-mobile"
        :group="actionsDropdownGroupMobile"
        :bordered="showNotificationToggle && !glFeatures.notificationsTodosButtons"
      />

      <gl-disclosure-dropdown-group v-if="canReportAbuseToAdmin" bordered>
        <gl-disclosure-dropdown-item @action="toggleReportAbuseDrawer(true)">
          <template #list-item>
            {{ $options.i18n.reportAbuse }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group v-if="canDestroy">
        <gl-disclosure-dropdown-item v-gl-modal="$options.deleteModalId">
          <template #list-item>
            <span class="gl-text-red-500">
              {{ $options.i18n.deleteButtonText }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <gl-button
      v-if="canUpdate"
      :title="$options.i18n.editTitleAndDescription"
      :aria-label="$options.i18n.editTitleAndDescription"
      category="secondary"
      class="js-issuable-edit gl-display-none gl-sm-display-block"
      @click="editEpic"
    >
      {{ $options.i18n.edit }}
    </gl-button>

    <gl-disclosure-dropdown
      v-if="showDesktopDropdown"
      ref="epicActionsDropdownDesktop"
      class="gl-display-none gl-sm-display-block"
      placement="right"
      :auto-close="false"
      data-testid="desktop-dropdown"
      :toggle-text="$options.i18n.dropdownText"
      text-sr-only
      icon="ellipsis_v"
      category="tertiary"
      no-caret
    >
      <gl-disclosure-dropdown-group
        v-if="showNotificationToggle && !glFeatures.notificationsTodosButtons"
      >
        <sidebar-subscriptions-widget
          :iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="$options.TYPE_EPIC"
        />
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group
        data-testid="actions-dropdown-desktop"
        :group="actionsDropdownGroupDesktop"
        :bordered="showNotificationToggle && !glFeatures.notificationsTodosButtons"
      />

      <gl-disclosure-dropdown-group v-if="canReportAbuseToAdmin" bordered>
        <gl-disclosure-dropdown-item @action="toggleReportAbuseDrawer(true)">
          <template #list-item>
            {{ $options.i18n.reportAbuse }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>

      <gl-disclosure-dropdown-group v-if="canDestroy">
        <gl-disclosure-dropdown-item v-gl-modal="$options.deleteModalId">
          <template #list-item>
            <span class="gl-text-red-500">
              {{ $options.i18n.deleteButtonText }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>

    <delete-issue-modal
      :issue-type="$options.TYPE_EPIC"
      :modal-id="$options.deleteModalId"
      :title="$options.i18n.deleteButtonText"
    />

    <abuse-category-selector
      v-if="isReportAbuseDrawerOpen"
      :reported-user-id="authorId"
      :reported-from-url="webUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
