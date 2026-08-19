import type { BrowserContext } from '@playwright/test'

/**
 * Keep developer-tool overlays and cookie banners out of the recording.
 * Runs before app boot (addInitScript): sets the disable flags some widgets read
 * from localStorage, and injects CSS to hide the rest (incl. the Next.js dev
 * indicator, which lives in a `nextjs-portal` shadow-DOM host — hide the host).
 */
export async function hideChrome(context: BrowserContext) {
  await context.addInitScript(() => {
    try {
      localStorage.setItem('BSTOCK_DEV_TOOLS_ENABLED', 'false')
      localStorage.setItem('BSTOCK_CONSENT_DEBUG_ENABLED', 'false')
      localStorage.setItem('TanstackQueryDevtoolsPanel_open', 'false')
    } catch {
      /* localStorage may be unavailable pre-navigation; CSS below still covers it */
    }
    const css = `
      #onetrust-consent-sdk,#onetrust-banner-sdk,.onetrust-pc-dark-filter,
      #ot-sdk-btn-floating,.ot-sdk-row,.save-preference-btn-handler,
      [data-testid="bstock-dev-tools"],.tsqd-open-btn-container,.tsqd-open-btn,
      [data-nextjs-toast],#__next-build-watcher,nextjs-portal{display:none !important;}`
    const apply = () => {
      const s = document.createElement('style')
      s.textContent = css
      document.documentElement.appendChild(s)
    }
    if (document.documentElement) apply()
    else document.addEventListener('DOMContentLoaded', apply)
  })
}
