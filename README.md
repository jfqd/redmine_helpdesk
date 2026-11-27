# Redmine Enterprise Helpdesk

[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/Arean82/redmine_helpdesk)
[![Redmine](https://img.shields.io/badge/redmine->=6.0.0-blue?logo=redmine&logoColor=%23B32024&labelColor=f0f0f0)](https://www.redmine.org)
[![Ruby](https://img.shields.io/badge/ruby->=3.2-red?logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*Maintained and developed by **Arean Narrayan** (<arean@synorastudio.in>)*

---

## Overview

**Redmine Enterprise Helpdesk (`v1.0.0`)** turns Redmine 6.0+ & 7.0+ into a multi-domain, real-time customer support and ticketing platform. Each Redmine project can act as an independent helpdesk queue with its own dedicated email/domain, per-project SMTP & IMAP settings (including Microsoft 365 Modern Auth / OAuth2 XOAUTH2), SLA policies, canned responses, public customer portals, embeddable support widget, instant inbound email webhook, cross-project developer escalation, ticket merging, CSAT, GDPR anonymization, and a user-configurable Helpdesk Dashboard.

---

## Key Features

- **Multi-Domain Email & Per-Project SMTP/IMAP:** Configure a dedicated support email, Reply-To, SMTP host/port/TLS, and IMAP host/port per project, plus **Test SMTP Connection** and **Microsoft 365 Modern Auth (OAuth2 XOAUTH2)**.
- **Instant Inbound Email Webhook (`POST /helpdesk/inbound_email`):** Real-time email ingestion (Mailgun, SendGrid, Postmark, SES, or Postfix) with optional `webhook_secret` verification and `##user-name##` sender placeholder support.
- **Public Customer Portals & Embeddable Widget:** Anonymous ticket submission (`GET/POST /helpdesk/public/:project_id`), ticket status lookup & customer reply (`GET/POST /helpdesk/status`), and a copy-paste `<script>` Support Widget (`GET /helpdesk/widget/:project_id.js`).
- **SLA Tracking, Canned Responses & Collision Detection:** Live SLA timer badges (`On Track` / `BREACHED`), one-click canned response insertion, and active-viewer collision badges (`Also viewing: <Agent>`).
- **Automation, Security & GDPR:** Configurable auto-priority keywords, spam/domain blacklist, attachment extension blacklist, and one-click GDPR PII anonymization (`POST /helpdesk/gdpr_anonymize/:id`).
- **Cross-Project Escalation, Merging & CSAT:** Escalate tickets to private developer tasks (`POST /helpdesk/escalate/:id`), merge duplicate tickets (`POST /helpdesk/merge/:id`), and collect CSAT ratings (`GET /helpdesk/csat/:id`).
- **Dashboards, Reports & Global Settings:** User-configurable Helpdesk Dashboard, Reports, Contacts Directory, Project Menu tab, and Global Plugin Settings overview.

---

## Installation

1. Place `redmine_helpdesk` in `/path/to/redmine/plugins/redmine_helpdesk`.
2. Run plugin database migrations:
   ```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```
3. Restart Redmine.
4. Configure global defaults and view all project queues under **Administration → Plugins → Redmine Enterprise Helpdesk → Configure**.

---

## Endpoints & API Reference

| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/helpdesk/inbound_email` | Webhook / API | Instant inbound email ingestion & multi-domain routing |
| `GET` | `/helpdesk/public/:project_id` | Public | Anonymous customer ticket submission form |
| `POST` | `/helpdesk/public/:project_id` | Public | Submit a new anonymous customer ticket |
| `GET` | `/helpdesk/status` | Public | Public ticket status lookup & customer reply portal |
| `POST` | `/helpdesk/status/reply` | Public | Submit a customer reply from the public portal |
| `GET` | `/helpdesk/widget/:project_id.js` | Public | Embeddable floating Support widget script |
| `GET` | `/helpdesk/csat/:id` | Public | Record CSAT rating (`happy`, `neutral`, `unhappy`) |
| `GET` | `/projects/:project_id/helpdesk/settings` | Member / Admin | Tabbed Helpdesk & Multi-Domain settings page |
| `POST` | `/projects/:project_id/helpdesk/settings` | Member / Admin | Save per-project mailbox, SMTP/IMAP, SLA, and rules |
| `POST` | `/projects/:project_id/helpdesk/test_smtp` | Member / Admin | Test per-project SMTP connection |
| `GET` | `/projects/:project_id/helpdesk/dashboard` | Member / Admin | User-configurable Helpdesk Queue Dashboard |
| `GET` | `/projects/:project_id/helpdesk/reports` | Member / Admin | Helpdesk summary reports |
| `GET` | `/projects/:project_id/helpdesk/contacts` | Member / Admin | External customer contacts directory |
| `POST` | `/helpdesk/escalate/:id` | API / Member | Escalate ticket to a private task in `target_project_id` |
| `POST` | `/helpdesk/merge/:id` | Member | Merge ticket into `target_issue_id` |
| `POST` | `/helpdesk/gdpr_anonymize/:id` | Member | Redact customer PII/emails & record GDPR audit log |

---

## Documentation & License
- See [USER_MANUAL.md](USER_MANUAL.md) for a complete, beginner-friendly step-by-step guide.
- Distributed under the **MIT License**. See [LICENSE](LICENSE).
