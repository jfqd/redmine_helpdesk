# Redmine Enterprise Helpdesk

[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](https://github.com/Arean82/redmine_helpdesk)
[![Redmine](https://img.shields.io/badge/redmine->=7.0.0-blue?logo=redmine&logoColor=%23B32024&labelColor=f0f0f0)](https://www.redmine.org)
[![Ruby](https://img.shields.io/badge/ruby->=3.2-red?logo=ruby&logoColor=white)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

*Maintained and developed by **Arean Narrayan** (<arean@synorastudio.in>)*

---

## Overview

**Redmine Enterprise Helpdesk (`v1.0.0`)** transforms Redmine 7.0+ into a multi-domain, real-time customer support and ticketing platform. Each Redmine project can operate as an independent support queue with its own dedicated email address/domain, SLA policies, canned responses, public customer submission portal, instant inbound email webhook, cross-project developer escalation, ticket merging, and a user-configurable Helpdesk Dashboard.

---

## Key Features

### 1. Multi-Domain Email Routing & Instant Inbound Webhook
- **Per-Project Dedicated Support Email:** Configure a unique support email and domain per project (e.g., `support@clientA.com`, `help@clientB.io`).
- **Instant Inbound Email Webhook (`POST /helpdesk/inbound_email`):** Accepts real-time push payloads from Mailgun, SendGrid, Postmark, AWS SES, or local Postfix/IMAP pipes and routes them immediately to the matching project via `MailHandler.receive` without waiting for cron.
- **Thread-Safe Customer Reply Chain:** Preserves `Message-ID`, `In-Reply-To`, and `References` headers so customer replies append directly to the existing ticket.

### 2. Public / Anonymous Customer Ticket Portal
- **Zero-Login Submission (`GET /helpdesk/public/:project_id`):** Clean, standalone web form allowing external customers to submit tickets with their email, subject, and description.

### 3. SLA Tracking & Canned Responses
- **Configurable SLA Targets:** Set **First Response SLA (hours)** and **Resolution SLA (hours)** per project.
- **Live SLA Timer Badge:** Every open helpdesk ticket displays its elapsed time vs. target SLA (`On Track` in green or `BREACHED` in red).
- **Canned Responses:** Define reusable `Title | Body` reply templates per project and insert them into issue notes with one click.

### 4. Cross-Project Developer Escalation & Ticket Merging
- **Developer Escalation (`POST /helpdesk/escalate/:id`):** Escalate a customer ticket into a **private** developer task in another engineering project, automatically linked via `IssueRelation`, keeping internal engineering discussions hidden from the customer.
- **Ticket Merging (`POST /helpdesk/merge/:id`):** Merge duplicate customer tickets into a single master ticket, transferring all journals and closing the duplicate with an audit trail.

### 5. User-Configurable Helpdesk Dashboard
- **Live Queue Dashboard (`GET /projects/:project_id/helpdesk/dashboard`):** Displays KPI cards and ticket lists for **Open Tickets**, **Unassigned Queue**, **SLA Breached**, and **My Assigned Tickets**.
- **Per-User Widget Toggles:** Agents can show/hide individual dashboard widgets (persisted in `localStorage`).

---

## Installation

1. Place `redmine_helpdesk` in `/path/to/redmine/plugins/redmine_helpdesk`.
2. Run plugin database migrations:
   ```bash
   cd /path/to/redmine
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```
3. Restart Redmine.
4. Enable **Issue Tracking** and assign `manage_helpdesk_settings` / `treat_user_as_supportclient` permissions under **Administration → Roles and permissions**.

---

## Endpoints & API Reference

| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/helpdesk/inbound_email` | Webhook / API | Instant inbound email ingestion & multi-domain project routing (`recipient`, `raw_email` / `body_mime`) |
| `GET` | `/helpdesk/public/:project_id` | Public | Anonymous customer ticket submission form |
| `POST` | `/helpdesk/public/:project_id` | Public | Submit a new anonymous customer ticket |
| `GET` | `/projects/:project_id/helpdesk/settings` | Member | Tabbed Helpdesk & Multi-Domain settings page |
| `POST` | `/projects/:project_id/helpdesk/settings` | Member | Save per-project mailbox, SLA, and canned responses |
| `GET` | `/projects/:project_id/helpdesk/dashboard` | Member | User-configurable Helpdesk Queue Dashboard |
| `POST` | `/helpdesk/escalate/:id` | API / Member | Escalate ticket to a private task in `target_project_id` |
| `POST` | `/helpdesk/merge/:id` | Member | Merge ticket into `target_issue_id` |

---

## Documentation
- See [USER_MANUAL.md](USER_MANUAL.md) for step-by-step configuration, webhook setup, and agent workflows.

---

## License
Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
