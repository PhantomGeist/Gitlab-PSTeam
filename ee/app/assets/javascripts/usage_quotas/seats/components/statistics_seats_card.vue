<script>
import { GlLink, GlIcon, GlButton, GlModalDirective, GlSkeletonLoader } from '@gitlab/ui';
import { getSubscriptionPermissionsData } from 'ee/fulfillment/shared_queries/subscription_actions_reason.customer.query.graphql';
import {
  addSeatsText,
  seatsOwedHelpText,
  seatsOwedLink,
  seatsOwedText,
  seatsUsedHelpText,
  seatsUsedLink,
  seatsUsedText,
} from 'ee/usage_quotas/seats/constants';
import Tracking from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import { LIMITED_ACCESS_KEYS } from 'ee/usage_quotas/components/constants';
import LimitedAccessModal from '../../components/limited_access_modal.vue';

export default {
  name: 'StatisticsSeatsCard',
  components: { GlLink, GlIcon, GlButton, LimitedAccessModal, GlSkeletonLoader },
  directives: {
    GlModalDirective,
  },
  helpLinks: {
    seatsUsedLink,
    seatsOwedLink,
  },
  i18n: {
    seatsUsedText,
    seatsUsedHelpText,
    seatsOwedText,
    seatsOwedHelpText,
    addSeatsText,
  },
  mixins: [Tracking.mixin()],
  props: {
    /**
     * Number of seats used
     */
    seatsUsed: {
      type: Number,
      required: false,
      default: null,
    },
    /**
     * Number of seats owed
     */
    seatsOwed: {
      type: Number,
      required: false,
      default: null,
    },
    /**
     * Link for purchase seats button
     */
    purchaseButtonLink: {
      type: String,
      required: false,
      default: null,
    },
    /**
     * Text for the purchase seats button
     */
    purchaseButtonText: {
      type: String,
      required: false,
      default: null,
    },
    /**
     * Id of the attached namespace
     */
    namespaceId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      subscriptionPermissions: null,
      showLimitedAccessModal: false,
    };
  },
  apollo: {
    subscriptionPermissions: {
      query: getSubscriptionPermissionsData,
      client: 'customersDotClient',
      variables() {
        return {
          namespaceId: parseInt(this.namespaceId, 10),
        };
      },
      update: (data) => ({
        ...data.subscription,
        reason: data.userActionAccess?.limitedAccessReason,
      }),
    },
  },
  computed: {
    shouldRenderSeatsUsedBlock() {
      return this.seatsUsed !== null;
    },
    shouldRenderSeatsOwedBlock() {
      return this.seatsOwed !== null;
    },
    canAddSeats() {
      return this.subscriptionPermissions?.canAddSeats ?? true;
    },
    shouldShowModal() {
      return (
        !this.canAddSeats &&
        gon.features?.limitedAccessModal &&
        LIMITED_ACCESS_KEYS.includes(this.subscriptionPermissions.reason)
      );
    },
    shouldShowAddSeatsButton() {
      return (
        !this.subscriptionPermissions?.communityPlan && this.purchaseButtonLink && !this.isLoading
      );
    },
    isLoading() {
      return this.$apollo.loading;
    },
  },
  methods: {
    trackClick() {
      this.track('click_button', { label: 'add_seats_saas', property: 'usage_quotas_page' });
    },
    handleAddSeats() {
      if (this.shouldShowModal) {
        this.showLimitedAccessModal = true;
        return;
      }

      this.trackClick();
      visitUrl(this.purchaseButtonLink);
    },
  },
};
</script>

<template>
  <div
    class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-5 gl-rounded-base gl-display-flex"
  >
    <gl-skeleton-loader v-if="isLoading" :height="64">
      <rect width="140" height="30" x="5" y="0" rx="4" />
      <rect width="240" height="10" x="5" y="40" rx="4" />
      <rect width="340" height="10" x="5" y="54" rx="4" />
    </gl-skeleton-loader>
    <div v-else class="gl-flex-grow-1">
      <p
        v-if="shouldRenderSeatsUsedBlock"
        class="gl-font-size-h-display gl-font-weight-bold gl-mb-3"
        data-testid="seats-used"
      >
        <span class="gl-relative gl-top-1">
          {{ seatsUsed }}
        </span>
        <span class="gl-font-lg">
          {{ $options.i18n.seatsUsedText }}
        </span>
        <gl-link
          :href="$options.helpLinks.seatsUsedLink"
          :aria-label="$options.i18n.seatsUsedHelpText"
          class="gl-ml-2 gl-relative"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </p>
      <p
        v-if="shouldRenderSeatsOwedBlock"
        class="gl-font-size-h-display gl-font-weight-bold gl-mb-0"
        data-testid="seats-owed"
      >
        <span class="gl-relative gl-top-1">
          {{ seatsOwed }}
        </span>
        <span class="gl-font-lg">
          {{ $options.i18n.seatsOwedText }}
        </span>
        <gl-link
          :href="$options.helpLinks.seatsOwedLink"
          :aria-label="$options.i18n.seatsOwedHelpText"
          class="gl-ml-2 gl-relative"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </p>
    </div>
    <gl-button
      v-if="shouldShowAddSeatsButton"
      v-gl-modal-directive="'limited-access-modal-id'"
      category="primary"
      target="_blank"
      variant="confirm"
      class="gl-ml-3 gl-align-self-start"
      data-testid="purchase-button"
      @click="handleAddSeats"
    >
      {{ $options.i18n.addSeatsText }}
    </gl-button>
    <limited-access-modal
      v-if="shouldShowModal"
      v-model="showLimitedAccessModal"
      :limited-access-reason="subscriptionPermissions.reason"
    />
  </div>
</template>
