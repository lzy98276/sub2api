<template>
  <div v-if="homeContent" class="min-h-screen">
    <iframe
      v-if="isHomeContentUrl"
      :src="homeContent.trim()"
      class="h-screen w-full border-0"
      allowfullscreen
    ></iframe>
    <div v-else v-html="homeContent"></div>
  </div>

  <div v-else class="relative min-h-screen overflow-hidden bg-white text-gray-900 dark:bg-dark-950 dark:text-white">
    <div class="pointer-events-none absolute inset-0 tech-grid opacity-70 dark:opacity-30"></div>

    <header class="relative z-10 border-b border-sky-100 bg-white/90 px-4 backdrop-blur-sm dark:border-dark-800 dark:bg-dark-950/90 sm:px-6">
      <nav class="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4">
        <router-link to="/" class="flex min-w-0 items-center gap-2.5">
          <img :src="siteLogo || '/logo.png'" :alt="siteName" class="h-8 w-8 shrink-0 rounded-md object-contain" />
          <span class="truncate text-sm font-semibold text-gray-900 dark:text-white">{{ siteName }}</span>
        </router-link>

        <div class="flex shrink-0 items-center gap-1">
          <a
            v-if="docUrl"
            :href="docUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="rounded-md p-2 text-gray-500 transition-colors hover:bg-sky-50 hover:text-sky-700 dark:text-dark-400 dark:hover:bg-dark-800 dark:hover:text-sky-300"
            :title="t('home.viewDocs')"
          >
            <Icon name="book" size="sm" />
          </a>
          <LocaleSwitcher />
          <button
            type="button"
            class="rounded-md p-2 text-gray-500 transition-colors hover:bg-sky-50 hover:text-sky-700 dark:text-dark-400 dark:hover:bg-dark-800 dark:hover:text-sky-300"
            :title="isDark ? t('home.switchToLight') : t('home.switchToDark')"
            @click="toggleTheme"
          >
            <Icon v-if="isDark" name="sun" size="sm" />
            <Icon v-else name="moon" size="sm" />
          </button>
          <router-link
            v-if="isAuthenticated"
            :to="dashboardPath"
            class="ml-2 inline-flex h-8 items-center gap-1.5 rounded-md bg-sky-600 px-2.5 text-xs font-medium text-white transition-colors hover:bg-sky-700"
          >
            <span class="flex h-4 w-4 items-center justify-center rounded-sm bg-white/20 text-[9px]">{{ userInitial }}</span>
            <span class="hidden sm:inline">{{ t('home.dashboard') }}</span>
          </router-link>
          <router-link
            v-else
            to="/login"
            class="ml-2 inline-flex h-8 items-center rounded-md bg-sky-600 px-3 text-xs font-medium text-white transition-colors hover:bg-sky-700"
          >
            {{ t('home.login') }}
          </router-link>
        </div>
      </nav>
    </header>

    <main class="relative z-10">
      <section class="mx-auto max-w-6xl px-6 pb-14 pt-16 sm:pt-20">
        <div class="mx-auto max-w-3xl text-center">
          <img :src="siteLogo || '/logo.png'" :alt="siteName" class="mx-auto mb-6 h-12 w-12 rounded-lg object-contain" />
          <h1 class="text-4xl font-semibold leading-tight text-gray-900 dark:text-white sm:text-5xl">{{ siteName }}</h1>
          <p class="mx-auto mt-4 max-w-2xl text-base leading-7 text-gray-600 dark:text-dark-300 sm:text-lg">{{ siteSubtitle }}</p>
          <router-link
            :to="isAuthenticated ? dashboardPath : '/login'"
            class="btn btn-primary home-cta mt-7 px-5 py-2.5 text-sm"
          >
            {{ isAuthenticated ? t('home.goToDashboard') : t('home.getStarted') }}
            <Icon name="arrowRight" size="sm" class="ml-2" />
          </router-link>
        </div>
      </section>

      <section class="border-y border-sky-100 bg-sky-50/50 dark:border-dark-800 dark:bg-dark-900/30">
        <div class="mx-auto grid max-w-6xl grid-cols-1 divide-y divide-sky-100 px-6 dark:divide-dark-800 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
          <p v-for="tag in homeTags" :key="tag" class="px-4 py-4 text-center text-sm font-medium text-sky-900 dark:text-sky-200">{{ tag }}</p>
        </div>
      </section>

      <section class="mx-auto grid max-w-6xl grid-cols-1 gap-x-12 gap-y-8 px-6 py-14 md:grid-cols-3">
        <div v-for="feature in features" :key="feature.title" class="border-l-2 border-sky-200 pl-4 dark:border-sky-800">
          <h2 class="text-sm font-semibold text-gray-900 dark:text-white">{{ feature.title }}</h2>
          <p class="mt-2 text-sm leading-6 text-gray-600 dark:text-dark-400">{{ feature.description }}</p>
        </div>
      </section>
    </main>

    <footer class="relative z-10 border-t border-sky-100 px-6 py-5 text-center text-xs text-gray-500 dark:border-dark-800 dark:text-dark-500">
      <a :href="githubUrl" target="_blank" rel="noopener noreferrer" class="transition-colors hover:text-sky-700 dark:hover:text-sky-300">{{ t('home.viewOnGithub') }}</a>
      <span class="mx-2">|</span>
      <span>&copy; {{ currentYear }} {{ siteName }}</span>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore, useAppStore } from '@/stores'
import LocaleSwitcher from '@/components/common/LocaleSwitcher.vue'
import Icon from '@/components/icons/Icon.vue'
import { sanitizeUrl } from '@/utils/url'

const { t } = useI18n()
const authStore = useAuthStore()
const appStore = useAppStore()

const siteName = computed(() => appStore.cachedPublicSettings?.site_name || appStore.siteName || 'Sub2API')
const siteLogo = computed(() => sanitizeUrl(appStore.cachedPublicSettings?.site_logo || appStore.siteLogo || '', { allowRelative: true, allowDataUrl: true }))
const siteSubtitle = computed(() => appStore.cachedPublicSettings?.site_subtitle || 'AI API Gateway Platform')
const docUrl = computed(() => appStore.cachedPublicSettings?.doc_url || appStore.docUrl || '')
const homeContent = computed(() => appStore.cachedPublicSettings?.home_content || '')
const isHomeContentUrl = computed(() => {
  const content = homeContent.value.trim()
  return content.startsWith('http://') || content.startsWith('https://')
})

const isDark = ref(document.documentElement.classList.contains('dark'))
const githubUrl = 'https://github.com/Wei-Shaw/sub2api'
const isAuthenticated = computed(() => authStore.isAuthenticated)
const isAdmin = computed(() => authStore.isAdmin)
const dashboardPath = computed(() => isAdmin.value ? '/admin/dashboard' : '/dashboard')
const userInitial = computed(() => authStore.user?.email?.charAt(0).toUpperCase() || '')
const currentYear = computed(() => new Date().getFullYear())
const homeTags = computed(() => [
  t('home.tags.subscriptionToApi'),
  t('home.tags.stickySession'),
  t('home.tags.realtimeBilling'),
])
const features = computed(() => [
  { title: t('home.features.unifiedGateway'), description: t('home.features.unifiedGatewayDesc') },
  { title: t('home.features.multiAccount'), description: t('home.features.multiAccountDesc') },
  { title: t('home.features.balanceQuota'), description: t('home.features.balanceQuotaDesc') },
])

function toggleTheme() {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
  localStorage.setItem('theme', isDark.value ? 'dark' : 'light')
}

function initTheme() {
  const savedTheme = localStorage.getItem('theme')
  if (savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    isDark.value = true
    document.documentElement.classList.add('dark')
  }
}

onMounted(() => {
  initTheme()
  authStore.checkAuth()
  if (!appStore.publicSettingsLoaded) {
    appStore.fetchPublicSettings()
  }
})
</script>

<style scoped>
.tech-grid {
  background-image:
    linear-gradient(to right, rgba(125, 211, 252, 0.15) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(125, 211, 252, 0.15) 1px, transparent 1px);
  background-size: 44px 44px;
  mask-image: linear-gradient(to bottom, black 0%, transparent 58%);
}

.home-cta {
  background: rgb(2 132 199) !important;
}

.home-cta:hover {
  background: rgb(3 105 161) !important;
}
</style>
