# LynxHub: Campus Tech Marketplace

A free-to-run, installable web app where students buy and sell phones, laptops, accessories and engineering tools. Buyers chat with sellers on WhatsApp, meet on campus and pay by Mobile Money in person. There is no cart and no upfront payment.

Launch campus: University of Energy and Natural Resources (UENR), Sunyani, Ghana.

**Built by Joel Lynx.**

---

## 1. What you get

| Feature | Details |
|---|---|
| Buyer experience | Search, brand chips, category chips, filter drawer, sorting, saved items, infinite scroll, skeleton loading |
| Micro-Hub tab | Quiet second tab for hostels, fashion, services and food |
| WhatsApp routing | One tap opens a prefilled chat. In live mode the seller's number is only returned when tapped, and every tap is counted |
| Seller dashboard | Post listings with a photo or image link, mark sold or relist, remove |
| PRO dashboard | Recruiting link, seller and chat stats, post for a seller, remove bad listings |
| CEO dashboard | Live listings, total chats, estimated sold value, PRO leaderboard, top listings, add PROs, moderation |
| **Site editor (CEO)** | Change the site name, tagline, headline, banner, categories, default theme and your developer contact, with no code |
| **Themes** | Aurora, Ember, Forest, Royal, Daylight (light), plus accent colour picker and card size. Each visitor can choose their own |
| PWA | Installable, offline badge, cached shell and last catalog |
| Image hosting | Five free options (section 5) |

## 2. Files

| File | Purpose |
|---|---|
| `index.html` | The whole app |
| `sw.js` | Service worker (offline) |
| `manifest.webmanifest` | PWA manifest |
| `icon.svg`, `icon-192.png`, `icon-512.png` | Logo and app icons |
| `schema.sql` | Database, security rules, photo bucket |
| `README.md` | This guide |

Keep every file in one folder.

## 3. Try it locally (demo mode, 2 minutes)

```bash
cd lynxhub-folder
python3 -m http.server 8080      # or: npx serve .
```

Open `http://localhost:8080`. With no keys it runs on fake data. Tap **Sell**, then switch between Seller, PRO and CEO to preview the dashboards. Tap **Theme** to try the looks. Add `?stress=100000` to the URL to test speed with 100,000 items. Demo data resets on refresh, but theme and site-editor changes persist in your browser.

## 4. Launch for real, all free

### Step A. Supabase (database and login)
1. Create a free project at supabase.com.
2. **SQL Editor**: paste all of `schema.sql` and run it. This creates the tables, security rules and the public `listings` photo bucket.
3. **Authentication, Providers, Google**: enable it.
   1. In Google Cloud Console create an OAuth consent screen and an OAuth client ID of type *Web application*.
   2. Add Supabase's callback URL as an authorised redirect URI. Supabase shows it on the Google provider page and it looks like `https://YOUR-REF.supabase.co/auth/v1/callback`.
   3. Paste the Client ID and Secret into Supabase.
4. **Project Settings, API**: copy the *Project URL* and *anon public key*.

### Step B. Configure the app
Open `index.html` and edit the `CFG` block near the top of the script:

```js
const CFG={
  SUPABASE_URL:'https://YOUR-REF.supabase.co', SUPABASE_KEY:'YOUR-ANON-KEY',
  IMG:{provider:'supabase', ...},
  DEV:{name:'Joel Lynx', role:'Developer', whatsapp:'233XXXXXXXXX', phone:'+233 XX XXX XXXX', email:'you@example.com'}
};
```

`DEV` is your contact in the footer. The anon key is designed to be public, because the row-level security rules protect the data.

### Step C. Deploy (Cloudflare Pages)
1. Cloudflare dashboard, Workers & Pages, Create, Pages, **Upload assets**.
2. Upload the whole folder. You get `https://yourname.pages.dev`.
3. In Supabase, **Authentication, URL Configuration**: set Site URL and add the same address to Redirect URLs.

Netlify, GitHub Pages and Vercel also work. The site must be served over HTTPS for the PWA install to work.

### Step D. Become CEO
1. Open your live site, tap **Sell**, sign in with Google.
2. In Supabase SQL Editor run:
   ```sql
   update profiles set role='admin' where email='you@gmail.com';
   ```
3. Reload. The button now says **CEO**.

### Step E. Edit everything from the app
CEO, then **Edit site**. You can change the name, tagline, headline, banner text, default theme, both category lists, the Micro-Hub tab name and your footer contact. Changes save to the database and show for everyone.

### Step F. Add your PROs
CEO, **Add a PRO**, enter their Google email (they must have signed in once). Each PRO gets a link like `https://yoursite/?ref=ABC123`. Sellers who sign up from that link are tied to them.

### Step G. Keep Supabase awake
Free projects pause after a period of inactivity. Add a free uptime monitor (for example UptimeRobot) that requests your Supabase project URL every few days.

## 5. Where seller photos are stored (free options)

Photos are resized to 900px and converted to WebP in the browser before upload, so they are small. Pick one provider in `CFG.IMG.provider`. Free-tier limits change, so check each provider's pricing page.

| Option | Setup | Best for |
|---|---|---|
| **1. Supabase Storage** (default) | Already created by `schema.sql`. Set `provider:'supabase'` | Simplest. One account for everything. Free storage is limited, so it fills up first |
| **2. Cloudinary** | Create a free account. Settings, Upload, add an **unsigned** upload preset. Set `provider:'cloudinary', cloudinaryCloud:'YOUR_CLOUD', cloudinaryPreset:'YOUR_PRESET'` | Generous free tier and automatic optimisation. Good first alternative |
| **3. ImgBB** | Get a free API key at api.imgbb.com. Set `provider:'imgbb', imgbbKey:'YOUR_KEY'` | Fastest setup. The key is visible in the page, so treat it as low-trust |
| **4. Paste an image link** | Nothing to set up. Sellers use the "paste an https:// image link" field | Zero storage cost. Links can break if the host deletes the image |
| **5. Cloudflare R2** | Create a bucket and a small Worker that accepts uploads, then change `api.photo` to post to it | Largest free storage and no egress fees. Needs a Worker, so it is for later scale |

Tips for staying free: keep one photo per listing, remove photos of sold items, and move to a second provider before the first fills up. Switching `provider` only affects new uploads. Old image links keep working.

## 6. Launch plan for UENR

1. **Week 0.** Finish setup, put your contact in the footer, test with 5 friends.
2. **Week 1.** Recruit 3 to 5 PROs (hostel reps, class reps, tech-club members). Give each their link.
3. **Week 2.** Each PRO brings 5 sellers with at least 5 listings each, for roughly 100 listings.
4. **Launch.** Post the install link on class WhatsApp groups and campus social pages.
5. **Then.** Watch the CEO dashboard weekly. Remove bad listings fast, because trust is the product.

Ideas to earn later: featured listings paid by MoMo, small seller subscriptions, sponsored banners using the announcement field.

## 7. Safety and trust rules (show these to users)

- Meet in public campus spots in daylight.
- Inspect the item (power on, check IMEI, test the screen) before paying.
- Pay by MoMo only after the handover.
- Never send money in advance.
- Report suspicious listings to a PRO. They can remove them.

## 8. Legal and privacy

You collect names, emails and phone numbers. In Ghana, personal data falls under the Data Protection Act, 2012 (Act 843). Check with the Data Protection Commission whether you need to register, and publish a short privacy note. This README is not legal advice.

## 9. Troubleshooting

| Problem | Fix |
|---|---|
| Google sign-in loops or fails | Site URL and Redirect URLs in Supabase must match your live address exactly |
| "new row violates row-level security" | You are not signed in, or `schema.sql` did not finish. Re-run it on a fresh project |
| Listing posts but no photo | Check the `listings` bucket exists and is public, or your Cloudinary preset is *unsigned* |
| Site editor not saving | Your account must have `role='admin'` (Step D) |
| No Install button | You need HTTPS, `sw.js` and the manifest in the same folder, and a supported browser |
| Old version showing | Hard refresh. After deploying changes, bump `lynxhub-v2` in `sw.js` |

## 10. Scaling later

The app loads up to 5,000 recent listings. Beyond that, page from the server with `.range()` and filter on columns that are already indexed (`hub, status, cat, ts`, `brand`, `price`, and a trigram index on `title`). For other campuses, add a `campus` column and filter by it.

## 11. Contact the developer

**Joel Lynx**. Developer of LynxHub.
WhatsApp: add yours in `CFG.DEV` or the CEO site editor.
Email: add yours in `CFG.DEV` or the CEO site editor.
