<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import isEmpty from 'lodash/isEmpty';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      services: [],
      suggestionsList: [],
      loading: false,
    };
  },
  methods: {
    async fetchSuggestions(searchTerm) {
      if (this.services.length === 0 && this.active) {
        await this.fetchServices();
      }
      this.suggestionsList = isEmpty(searchTerm)
        ? this.services
        : this.services.filter(({ name }) => name.toLowerCase().includes(searchTerm.toLowerCase()));
    },
    async fetchServices() {
      this.loading = true;
      try {
        this.services = await this.config.fetchServices();
      } catch (e) {
        createAlert({
          message: s__('Tracing|Something went wrong while fetching the services'),
        });
        this.services = [];
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <base-token
    v-bind="$attrs"
    :active="active"
    :config="config"
    :value="value"
    :suggestions-loading="loading"
    :suggestions="suggestionsList"
    v-on="$listeners"
    @fetch-suggestions="fetchSuggestions"
  >
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="service in suggestions"
        :key="service.name"
        :value="service.name"
      >
        {{ service.name }}
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
