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
    // Playwright's BUNDLED Chromium cannot reach the VPN-routed dev network at
    // all on this workstation — even a top-level navigation to the raw IP times
    // out, while Node/curl on the same machine gets through. The corporate
    // network agent only admits signed/approved binaries, and the downloaded
    // Chromium is not one. Real Chrome is, so pin the channel. See pitfalls.md.
    channel: 'chrome',
    storageState: '.auth/buyer.json',
    viewport: SIZE,
    actionTimeout: 30_000,
    navigationTimeout: 90_000,
    video: { mode: 'on', size: SIZE },
    trace: 'on',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium', channel: 'chrome', viewport: SIZE },
    },
  ],
})
