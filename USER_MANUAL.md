# Redmine Enterprise Helpdesk — User Manual

## 1. Project Setup (Multi-Domain)
1. Go to `/projects/:project_id/helpdesk/settings`.
2. Under **Mailbox & Routing**, enable Helpdesk for the project and set its **Dedicated Support Email** and **Reply-To Email**.
3. Under **SLA & Canned Responses**, set **First Response SLA (hours)**, **Resolution SLA (hours)**, and **Canned Responses** (`Title | Body`, one per line).

## 2. Instant Inbound Email Webhook
Point Mailgun, SendGrid, Postmark, or your mail server pipe to:
```
POST https://your-redmine-domain/helpdesk/inbound_email
```
Parameters: `recipient` (e.g. `support@clientA.com`) and `raw_email` (or raw MIME body).

## 3. Agent Workflows
- **Helpdesk Dashboard:** `/projects/:project_id/helpdesk/dashboard` — toggle widgets (*Open*, *Unassigned*, *SLA Breached*, *My Tickets*).
- **Canned Responses:** Use the **Insert Canned Response...** dropdown on any open ticket.
- **Escalate to Developer Project:** `POST /helpdesk/escalate/:id` with `target_project_id` and `assigned_to_id`.
- **Merge Duplicate Tickets:** `POST /helpdesk/merge/:id` with `target_issue_id`.
- **Public Customer Form:** `/helpdesk/public/:project_id`.
