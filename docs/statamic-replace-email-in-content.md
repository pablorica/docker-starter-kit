# Replacing text site-wide in Statamic (flat-file content)

**Project:** Studio Fabbri (Statamic, Docker)
**Date:** 2026-11-09
**Case:** Change `contact@studiofabbri.co.uk` → `enquiries@studiofabbri.co.uk` across the whole site.

---

## Why search-and-replace works

Statamic has no database by default. Everything editable in the control panel (entries, pages, globals, navigation, form config) is stored as YAML/Markdown files under `statamic/content/`. These files *are* the database, so a text search-and-replace there is the standard way to change a value everywhere.

---

## 1. Back up and find every occurrence

From the `statamic/` folder on the server, or inside the container:

```bash
tar czf ~/content-backup-$(date +%F).tgz content
grep -rniF "contact@studiofabbri.co.uk" content resources config .env 2>/dev/null
```

- `-i` also catches capitalised variants (`Contact@…`).
- Check the list of matches first to know which files will change. Typical places: the **Contact details** and **Footer message** globals, the Contact page, and `mailto:` links inside text fields.
- The repo itself (`resources`, `config`) had no matches. `.env` isn't in git, so check it (e.g. `MAIL_FROM_ADDRESS`).

## 2. Replace in the content

**Linux (server / container):**

```bash
## Important: login as root
sudo -i 
cd /data/webs/studio-fabri/statamic/
grep -rliF "contact@studiofabbri.co.uk" content | xargs sed -i 's/contact@studiofabbri\.co\.uk/enquiries@studiofabbri.co.uk/gI'
```

**macOS (BSD `sed`):**

```bash
grep -rlF "contact@studiofabbri.co.uk" content | xargs sed -i '' -E 's/contact@studiofabbri\.co\.uk/enquiries@studiofabbri.co.uk/g'
```

The macOS version only matches lowercase. If step 1 found capitalised matches, change those by hand.

If `.env` contains the old address, change it by hand, then:

```bash
php artisan config:clear
```

## 3. Verify and clear caches

```bash
grep -rniF "studiofabbri.co.uk" content    # should return the new email 
php please stache:clear
php please static:clear
```

Statamic serves content from its **stache** cache, so without `stache:clear` the site keeps showing the old value. After that, check the footer, the menu overlay and the Contact page in the browser.

---

## Gotchas

- **Docker:** `content/` may live on a mounted volume. Run the commands where the live files are, inside the container (`docker compose exec app sh`) or on the mounted host folder.
- **Staging vs production:** if content is copied from staging to production, do the replace on staging and copy it across. If production has its own content, run it there too.
- **Form submissions:** `storage/forms` holds past submissions. Don't include it in the replace; it's a record of past enquiries.
- **Contact form recipient:** `resources/forms/contact.yaml` had placeholder addresses (`info@site.com`). Set `to:` to `enquiries@studiofabbri.co.uk` and `from:` to an address the mailer is allowed to send from, then send a test enquiry.

---

## Reusable template

For any future site-wide text change, swap in your own values:

```bash
OLD='old@example.com'; NEW='new@example.com'
tar czf ~/content-backup-$(date +%F).tgz content
grep -rniF "$OLD" content
grep -rliF "$OLD" content | xargs sed -i "s/$(printf '%s' "$OLD" | sed 's/[.[\*^$/]/\\&/g')/$NEW/gI"
grep -rniF "$OLD" content    # should be empty
php please stache:clear && php please static:clear
```
