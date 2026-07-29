<template>
  <AppLayout>
    <main class="mx-auto w-full max-w-[1440px] px-4 pb-8 pt-6 sm:px-6 lg:px-8">
      <div class="mb-5 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 class="text-xl font-semibold text-gray-900 dark:text-white">{{ t('modelMarketplace.title') }}</h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('modelMarketplace.description') }}</p>
        </div>
        <button
          type="button"
          class="btn btn-secondary shrink-0 gap-2 self-start sm:self-auto"
          :disabled="loading"
          @click="loadMarketplace"
        >
          <Icon name="refresh" size="sm" :class="loading ? 'animate-spin' : ''" />
          {{ t('modelMarketplace.refresh') }}
        </button>
      </div>

      <div class="mb-6 flex flex-col gap-3 sm:flex-row">
        <label class="relative block min-w-0 flex-1">
          <span class="sr-only">{{ t('modelMarketplace.searchPlaceholder') }}</span>
          <Icon name="search" size="sm" class="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            v-model="searchQuery"
            type="search"
            :placeholder="t('modelMarketplace.searchPlaceholder')"
            class="input w-full pl-9"
          />
        </label>
        <select v-model="selectedProvider" class="input w-full sm:w-52" :aria-label="t('modelMarketplace.providerFilter')">
          <option value="">{{ t('modelMarketplace.allProviders') }}</option>
          <option v-for="provider in providers" :key="provider" :value="provider">
            {{ provider }}
          </option>
        </select>
      </div>

      <div v-if="loading" class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
        <div v-for="index in 8" :key="index" class="h-64 animate-pulse rounded-lg border border-gray-200 bg-white dark:border-dark-700 dark:bg-dark-800" />
      </div>

      <div v-else-if="loadFailed" class="py-16 text-center text-sm text-gray-500 dark:text-gray-400">
        <p>{{ t('modelMarketplace.loadFailed') }}</p>
        <button type="button" class="btn btn-secondary mt-4" @click="loadMarketplace">
          {{ t('modelMarketplace.retry') }}
        </button>
      </div>

      <div v-else-if="filteredModels.length === 0" class="py-16 text-center text-sm text-gray-500 dark:text-gray-400">
        {{ t('modelMarketplace.empty') }}
      </div>

      <div v-else class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
        <article
          v-for="model in filteredModels"
          :key="`${model.platform}-${model.name}`"
          class="flex min-h-60 flex-col rounded-lg border border-gray-200 bg-white p-4 shadow-sm transition-shadow hover:shadow-md dark:border-dark-700 dark:bg-dark-800"
        >
          <header class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <h2 class="break-words text-sm font-semibold text-gray-900 dark:text-white">{{ model.name }}</h2>
              <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">{{ model.platform }}</p>
            </div>
            <span class="shrink-0 rounded-md bg-sky-50 px-2 py-1 text-[11px] font-medium text-sky-700 dark:bg-sky-950/40 dark:text-sky-300">
              {{ model.provider }}
            </span>
          </header>

          <section class="mt-4">
            <p class="mb-2 text-[11px] font-medium text-gray-500 dark:text-gray-400">{{ t('modelMarketplace.availableGroups') }}</p>
            <div class="flex flex-wrap gap-1.5">
              <span
                v-for="group in model.groups"
                :key="group.id"
                class="rounded-md border border-gray-200 px-2 py-1 text-[11px] text-gray-700 dark:border-dark-600 dark:text-gray-200"
              >
                {{ group.name }} - x{{ formatMultiplier(group.rate_multiplier) }}
              </span>
            </div>
          </section>

          <section class="mt-auto border-t border-gray-100 pt-3 dark:border-dark-700">
            <div class="mb-2 flex items-center justify-between gap-3">
              <p class="text-[11px] font-medium text-gray-500 dark:text-gray-400">{{ billingModeLabel(model.pricing?.billing_mode) }}</p>
              <span class="text-[11px] text-gray-400 dark:text-gray-500">USD</span>
            </div>

            <div v-if="model.pricing && hasFlatPricing(model.pricing)" class="grid grid-cols-2 gap-x-3 gap-y-2">
              <PriceCell
                v-if="isTokenPricing(model.pricing) && model.pricing.input_price !== null"
                :label="t('modelMarketplace.input')"
                :value="perMillion(model.pricing.input_price)"
              />
              <PriceCell
                v-if="isTokenPricing(model.pricing) && model.pricing.output_price !== null"
                :label="t('modelMarketplace.output')"
                :value="perMillion(model.pricing.output_price)"
              />
              <PriceCell
                v-if="isTokenPricing(model.pricing) && model.pricing.cache_write_price !== null"
                :label="t('modelMarketplace.cacheWrite')"
                :value="perMillion(model.pricing.cache_write_price)"
              />
              <PriceCell
                v-if="isTokenPricing(model.pricing) && model.pricing.cache_read_price !== null"
                :label="t('modelMarketplace.cacheRead')"
                :value="perMillion(model.pricing.cache_read_price)"
              />
              <PriceCell
                v-if="!isTokenPricing(model.pricing) && model.pricing.per_request_price !== null"
                :label="model.pricing.billing_mode === 'image' ? t('modelMarketplace.perImage') : t('modelMarketplace.perRequest')"
                :value="formatUSD(model.pricing.per_request_price)"
              />
              <PriceCell
                v-if="model.pricing.image_output_price !== null"
                :label="t('modelMarketplace.imageOutput')"
                :value="perMillion(model.pricing.image_output_price)"
              />
            </div>
            <p v-else-if="!model.pricing?.intervals.length" class="text-xs text-gray-500 dark:text-gray-400">{{ t('modelMarketplace.noPricing') }}</p>

            <div v-if="model.pricing?.intervals.length" class="mt-3 space-y-1.5 border-t border-gray-100 pt-2 dark:border-dark-700">
              <div
                v-for="(interval, index) in model.pricing.intervals"
                :key="`${interval.tier_label}-${index}`"
                class="flex items-center justify-between gap-3 text-[11px]"
              >
                <span class="min-w-0 truncate text-gray-500 dark:text-gray-400">{{ intervalLabel(interval, model.pricing.billing_mode) }}</span>
                <span class="shrink-0 font-medium text-gray-700 dark:text-gray-200">{{ intervalPrice(interval, model.pricing.billing_mode) }}</span>
              </div>
            </div>
          </section>
        </article>
      </div>
    </main>
  </AppLayout>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AppLayout from '@/components/layout/AppLayout.vue'
import Icon from '@/components/icons/Icon.vue'
import { getModelMarketplace, type ModelMarketplaceModel } from '@/api/modelMarketplace'
import type { UserPricingInterval, UserSupportedModelPricing } from '@/api/channels'
import type { BillingMode } from '@/constants/channel'
import { useAppStore } from '@/stores/app'
import { extractApiErrorMessage } from '@/utils/apiError'

const { t } = useI18n()
const appStore = useAppStore()

const models = ref<ModelMarketplaceModel[]>([])
const loading = ref(false)
const loadFailed = ref(false)
const searchQuery = ref('')
const selectedProvider = ref('')

const PriceCell = defineComponent({
  props: {
    label: { type: String, required: true },
    value: { type: String, required: true },
  },
  setup(props) {
    return () => h('div', [
      h('p', { class: 'text-[11px] text-gray-500 dark:text-gray-400' }, props.label),
      h('p', { class: 'mt-0.5 text-xs font-medium text-gray-800 dark:text-gray-100' }, props.value),
    ])
  },
})

const providers = computed(() => [...new Set(models.value.map((model) => model.provider))].sort())

const filteredModels = computed(() => {
  const keyword = searchQuery.value.trim().toLowerCase()
  return models.value.filter((model) => {
    if (selectedProvider.value && model.provider !== selectedProvider.value) return false
    if (!keyword) return true
    return model.name.toLowerCase().includes(keyword)
      || model.platform.toLowerCase().includes(keyword)
      || model.provider.toLowerCase().includes(keyword)
      || model.groups.some((group) => group.name.toLowerCase().includes(keyword))
  })
})

function formatUSD(value: number | null | undefined): string {
  if (value === null || value === undefined) return '-'
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: value < 0.01 ? 6 : 4,
  }).format(value)
}

function formatMultiplier(value: number): string {
  return Number.isInteger(value) ? value.toFixed(0) : value.toFixed(2).replace(/0+$/, '').replace(/\.$/, '')
}

function perMillion(value: number | null | undefined): string {
  if (value === null || value === undefined) return '-'
  return `${formatUSD(value * 1_000_000)} / 1M`
}

function isTokenPricing(pricing: { billing_mode: BillingMode }): boolean {
  return pricing.billing_mode === 'token' || !pricing.billing_mode
}

function hasFlatPricing(pricing: UserSupportedModelPricing): boolean {
  return pricing.input_price !== null
    || pricing.output_price !== null
    || pricing.cache_write_price !== null
    || pricing.cache_read_price !== null
    || pricing.image_output_price !== null
    || pricing.per_request_price !== null
}

function billingModeLabel(mode: BillingMode | undefined): string {
  if (mode === 'image') return t('modelMarketplace.imagePricing')
  if (mode === 'per_request') return t('modelMarketplace.requestPricing')
  return t('modelMarketplace.tokenPricing')
}

function intervalLabel(interval: UserPricingInterval, mode: BillingMode): string {
  if (interval.tier_label) return interval.tier_label
  if (mode !== 'token') return t('modelMarketplace.priceTier')
  if (interval.max_tokens === null) return `${interval.min_tokens.toLocaleString()}+ tokens`
  return `${interval.min_tokens.toLocaleString()} - ${interval.max_tokens.toLocaleString()} tokens`
}

function intervalPrice(interval: UserPricingInterval, mode: BillingMode): string {
  if (mode === 'token') {
    const prices = [
      interval.input_price === null ? null : `${t('modelMarketplace.input')} ${perMillion(interval.input_price)}`,
      interval.output_price === null ? null : `${t('modelMarketplace.output')} ${perMillion(interval.output_price)}`,
      interval.per_request_price === null ? null : formatUSD(interval.per_request_price),
    ].filter((value): value is string => value !== null)
    return prices.join(' / ') || '-'
  }
  return formatUSD(interval.per_request_price)
}

async function loadMarketplace() {
  loading.value = true
  loadFailed.value = false
  try {
    const response = await getModelMarketplace()
    models.value = response.models
  } catch (error: unknown) {
    loadFailed.value = true
    appStore.showError(extractApiErrorMessage(error, t('common.error')))
  } finally {
    loading.value = false
  }
}

onMounted(loadMarketplace)
</script>
