import { defineConfig } from '@playwright/test'

import demo from './demo.config'

// viewport MUST equal video.size, or Playwright pads the page into the canvas
// with a gray border. Single source of truth from demo.config.
const SIZE = demo.size

export default defineConfig({
  testDir: '.',
  testMatch: /.*\.spec\.ts/,
  timeout: 200_000, // dev backend over VPN is slow
  expect: { timeout: 30_000 },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list']],
  globalSetup: './global-setup.ts',
  use: {
    baseURL: demo.baseUrl,
    // Chromium's Local Network Access checks block XHR from http://localhost to
    // VPN-routed *.bstock-dev.com (private address space); client-side fetches
    // then fail and error boundaries leak into captures. See pitfalls.md #13.
    launchOptions: {
      args: ['--disable-features=LocalNetworkAccessChecks'],
    },
    storageState: '.auth/buyer.json',
    viewport: SIZE,
    actionTimeout: 30_000,
    navigationTimeout: 90_000,
    video: { mode: 'on', size: SIZE },
    trace: 'on',
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium', viewport: SIZE } }],
})
