const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto('http://localhost:5173/login');
  await page.fill('input[type="email"]', 'super@test.local');
  await page.fill('input[type="password"]', 'password');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(2000);
  await page.goto('http://localhost:5173/agents');
  await page.waitForTimeout(3000);
  await page.screenshot({ path: '../agents_tab_dispatch_availability.png' });
  await browser.close();
})();
