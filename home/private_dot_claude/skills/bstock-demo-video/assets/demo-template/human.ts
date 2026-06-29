import type { Page, Locator } from '@playwright/test'

// Generic "make it look like a real person" interaction kit for demo recordings:
// a visible cursor that eases toward targets, smooth scrolling, typed input, and
// a reusable "tour" that pans any scrollable region (the window OR an element).
// The modal helpers (scrollModal/closeModal/confirmOrClose) are conveniences for
// the common confirm-modal case — NOT a required shape. Compose these freely.

const lastPos = new WeakMap<Page, { x: number; y: number }>()
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms))
const easeInOutCubic = (t: number) =>
  t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

const center = (page: Page) => {
  const vp = page.viewportSize() ?? { width: 1440, height: 1024 }
  return { x: Math.round(vp.width / 2), y: Math.round(vp.height / 2) }
}

/**
 * fe-core Modal portal. NB: the live-chat widget ALSO uses role="dialog", so a
 * bare [role="dialog"] is ambiguous — always scope to this portal. Override for
 * apps that mount modals elsewhere.
 */
export let MODAL = '#modal-portal-wrapper [role="dialog"]'
export const setModalSelector = (sel: string) => {
  MODAL = sel
}

/** Inject a visible cursor that tracks real mouse events (re-runs on every nav). */
export async function installCursor(page: Page) {
  await page.addInitScript(() => {
    const ID = '__demo_cursor__'
    const ensure = () => {
      if (document.getElementById(ID)) return
      const c = document.createElement('div')
      c.id = ID
      Object.assign(c.style, {
        position: 'fixed',
        top: '0',
        left: '0',
        width: '22px',
        height: '22px',
        marginLeft: '-11px',
        marginTop: '-11px',
        borderRadius: '50%',
        border: '2px solid rgba(0,0,0,0.55)',
        background: 'rgba(0,0,0,0.18)',
        boxShadow: '0 0 0 1px rgba(255,255,255,0.7)',
        zIndex: '2147483647',
        pointerEvents: 'none',
        transition: 'transform 0.06s ease-out',
        transform: 'translate(50vw,50vh) scale(1)',
        willChange: 'transform',
      } as CSSStyleDeclaration)
      document.body.appendChild(c)
      let cx = window.innerWidth / 2
      let cy = window.innerHeight / 2
      let pressed = false
      const render = () =>
        (c.style.transform = `translate(${cx}px,${cy}px) scale(${pressed ? 0.6 : 1})`)
      render()
      document.addEventListener(
        'mousemove',
        (e) => {
          cx = e.clientX
          cy = e.clientY
          render()
        },
        true
      )
      document.addEventListener('mousedown', () => {
        pressed = true
        render()
      }, true)
      document.addEventListener('mouseup', () => {
        pressed = false
        render()
      }, true)
    }
    if (document.body) ensure()
    else document.addEventListener('DOMContentLoaded', ensure)
  })
}

/** Park the cursor in the center (call after each navigation). */
export async function recenterCursor(page: Page) {
  const c = center(page)
  await page.mouse.move(c.x, c.y)
  lastPos.set(page, c)
}

/** Move the cursor to (x,y) along an eased path so it visibly travels. */
export async function moveTo(page: Page, x: number, y: number) {
  const from = lastPos.get(page) ?? center(page)
  const dist = Math.hypot(x - from.x, y - from.y)
  const steps = Math.max(18, Math.min(48, Math.round(dist / 18)))
  for (let i = 1; i <= steps; i++) {
    const t = easeInOutCubic(i / steps)
    await page.mouse.move(from.x + (x - from.x) * t, from.y + (y - from.y) * t)
    await wait(10 + Math.random() * 6)
  }
  lastPos.set(page, { x, y })
}

/** Smoothly scroll a target to the center of its scroll container. */
export async function smoothScrollIntoView(page: Page, locator: Locator) {
  await locator
    .evaluate((el) =>
      el.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' })
    )
    .catch(() => {})
  await page.waitForTimeout(750)
}

/** Scroll into view, ease the cursor to the element, then click at that point. */
export async function hoverClick(page: Page, locator: Locator) {
  await smoothScrollIntoView(page, locator)
  const box = await locator.boundingBox()
  if (!box) {
    await locator.click()
    return
  }
  const jitter = (n: number) => (Math.random() - 0.5) * n
  const x = box.x + box.width / 2 + jitter(Math.min(box.width * 0.3, 14))
  const y = box.y + box.height / 2 + jitter(Math.min(box.height * 0.3, 8))
  await moveTo(page, x, y)
  await wait(140) // a beat to "aim"
  await page.mouse.down()
  await wait(70)
  await page.mouse.up()
  await wait(180)
}

/** Click a field, then type the text character-by-character. */
export async function humanType(page: Page, locator: Locator, text: string) {
  await hoverClick(page, locator)
  await page.keyboard.type(text, { delay: 90 })
}

/**
 * Animate a scroll region to 'top' or 'bottom' via rAF, in-page.
 * `where`: undefined → the window (document.scrollingElement); 'modal' → the
 * biggest-overflow descendant inside MODAL; any other string → a CSS selector
 * (its biggest-overflow descendant if nested wrappers exist).
 */
async function scrollTo(
  page: Page,
  to: 'top' | 'bottom',
  durationMs: number,
  where: string | undefined,
  modalSel: string
) {
  await page.evaluate(
    async ({ to, durationMs, where, modalSel }) => {
      const pickScroller = (root: Element | null): HTMLElement | null => {
        if (!root) return null
        let best: HTMLElement | null = null
        let bestDelta = 0
        for (const el of [root, ...Array.from(root.querySelectorAll('*'))]) {
          const h = el as HTMLElement
          const delta = h.scrollHeight - h.clientHeight
          const oy = getComputedStyle(h).overflowY
          if (delta > bestDelta && (oy === 'auto' || oy === 'scroll')) {
            best = h
            bestDelta = delta
          }
        }
        return bestDelta > 24 ? best : null
      }
      let scroller: HTMLElement | null
      if (where === undefined) {
        scroller = (document.scrollingElement as HTMLElement) ?? document.body
      } else if (where === 'modal') {
        scroller = pickScroller(document.querySelector(modalSel))
      } else {
        const root = document.querySelector(where)
        scroller = pickScroller(root) ?? (root as HTMLElement | null)
      }
      if (!scroller) return
      const target =
        to === 'bottom' ? scroller.scrollHeight - scroller.clientHeight : 0
      const ease = (t: number) =>
        t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
      await new Promise<void>((res) => {
        const from = scroller!.scrollTop
        const start = performance.now()
        const step = (now: number) => {
          const p = Math.min(1, (now - start) / durationMs)
          scroller!.scrollTop = from + (target - from) * ease(p)
          if (p < 1) requestAnimationFrame(step)
          else res()
        }
        requestAnimationFrame(step)
      })
    },
    { to, durationMs, where, modalSel: modalSel }
  )
}

/**
 * Tour a scrollable region so the recording shows its full contents:
 * top (pause) → bottom (pause). Pass `{ region: 'modal' }` for the confirm modal,
 * `{ region: '<css>' }` for a specific scroll container, or omit for the window.
 */
export async function tour(
  page: Page,
  opts: { region?: string; downMs?: number; upMs?: number; holdMs?: number } = {}
) {
  const { region, downMs = 2400, holdMs = 2200 } = opts
  await scrollTo(page, 'top', 600, region, MODAL)
  await page.waitForTimeout(holdMs)
  await scrollTo(page, 'bottom', downMs, region, MODAL)
  await page.waitForTimeout(holdMs)
}

/** Convenience: scroll the open modal's content to 'top' | 'bottom'. */
export async function scrollModal(
  page: Page,
  to: 'top' | 'bottom',
  durationMs = 2000
) {
  await scrollTo(page, to, durationMs, 'modal', MODAL)
}

/** Close the modal with a visible click (Cancel → X fallback), then wait gone. */
export async function closeModal(page: Page) {
  const dialog = page.locator(MODAL).first()
  const cancel = dialog.getByRole('button', { name: /^cancel$/i })
  const x = dialog.locator('button[data-testid="close-modal-button"]')
  if (await cancel.count()) await hoverClick(page, cancel.first())
  else if (await x.count()) await hoverClick(page, x.first())
  await dialog.waitFor({ state: 'hidden', timeout: 10_000 }).catch(() => {})
  await wait(600)
}

/**
 * Guardrail-aware finish: when `submit` is true, click the real confirm button
 * (only do this on seeded/disposable records!); otherwise close via Cancel/X.
 */
export async function confirmOrClose(
  page: Page,
  opts: { submit?: boolean; confirmName?: RegExp } = {}
) {
  const { submit = false, confirmName = /confirm|place|submit|buy/i } = opts
  if (submit) {
    const btn = page.locator(MODAL).getByRole('button', { name: confirmName })
    await hoverClick(page, btn.first())
    await page.waitForTimeout(2500)
  } else {
    await closeModal(page)
  }
}
