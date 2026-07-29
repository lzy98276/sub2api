<template>
  <div class="relative flex min-h-screen items-center justify-center overflow-hidden bg-white p-4 dark:bg-dark-950">
    <div class="pointer-events-none absolute inset-0 auth-grid opacity-70 dark:opacity-30"></div>

    <div class="relative z-10 w-full max-w-md">
      <div class="mb-7 text-center">
        <template v-if="settingsLoaded">
          <img :src="siteLogo || '/logo.png'" :alt="siteName" class="mx-auto mb-4 h-12 w-12 rounded-lg object-contain" />
          <h1 class="text-xl font-semibold text-gray-900 dark:text-white">{{ siteName }}</h1>
          <p class="mt-2 text-sm text-gray-500 dark:text-dark-400">{{ siteSubtitle }}</p>
        </template>
      </div>

      <div class="rounded-lg border border-sky-100 bg-white p-6 shadow-sm dark:border-dark-700 dark:bg-dark-900 sm:p-8">
        <slot />
      </div>

      <div class="mt-5 text-center text-sm">
        <slot name="footer" />
      </div>

      <div class="mt-7 text-center text-xs text-gray-400 dark:text-dark-500">
        &copy; {{ currentYear }} {{ siteName }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useAppStore } from '@/stores'
import { sanitizeUrl } from '@/utils/url'

const appStore = useAppStore()
const siteName = computed(() => appStore.siteName || 'Sub2API')
const siteLogo = computed(() => sanitizeUrl(appStore.siteLogo || '', { allowRelative: true, allowDataUrl: true }))
const siteSubtitle = computed(() => appStore.cachedPublicSettings?.site_subtitle || 'Subscription to API Conversion Platform')
const settingsLoaded = computed(() => appStore.publicSettingsLoaded)
const currentYear = computed(() => new Date().getFullYear())

onMounted(() => {
  appStore.fetchPublicSettings()
})
</script>

<style scoped>
.auth-grid {
  background-image:
    linear-gradient(to right, rgba(125, 211, 252, 0.14) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(125, 211, 252, 0.14) 1px, transparent 1px);
  background-size: 40px 40px;
}

:deep(.btn-primary) {
  background: rgb(2 132 199) !important;
}

:deep(.btn-primary:hover) {
  background: rgb(3 105 161) !important;
}
</style>
