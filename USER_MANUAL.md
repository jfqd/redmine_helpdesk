# Redmine Enterprise Helpdesk — User Manual

## 1. Configuring a Project as a Dedicated Helpdesk Queue
Each Redmine project can act as an independent helpdesk queue with its own domain/email:

1. Navigate to `/projects/<project_identifier>/helpdesk/settings`.
2. **Tab 1 — Mailbox & Routing:**
   - Check **Enable Helpdesk for this Project**.
   - Enter **Dedicated Support Email** (e.g., `support@clientA.com`).
   - Enter **Reply-To Email** (e.g., `support@clientA.com`).
3. **Tab 2 — SLA & Canned Responses:**
   - Set **First Response SLA (hours)** (default: `4`).
   - Set **Resolution SLA (hours)** (default: `24`).
   - Add **Canned Responses**, one per line in `Title | Body` format:
     ```text
     Greeting | Thank you for contacting support. We are reviewing your request.
     Resolved | Your issue has been resolved. Please reply if you need further assistance.
     ```
4. Click **Save**.

---

## 2. Setting Up Instant Inbound Email (Zero-Delay)
Instead of waiting for cron jobs, configure your mail provider (Mailgun, SendGrid, Postmark, AWS SES) or local Postfix pipe to POST incoming emails to:

```text
POST https://your-redmine-host/helpdesk/inbound_email
```

**Payload Parameters:**
- `recipient`: Target support email address (e.g., `support@clientA.com`). Used to route the email to the matching project.
- `raw_email` (or `body_mime` / raw HTTP body): The full MIME email content.

**Example `curl` test:**
```bash
curl -X POST https://your-redmine-host/helpdesk/inbound_email \
  -d "recipient=support@clientA.com" \
  --data-urlencode "raw_email@sample.eml"
```

---

## 3. Agent Workflows

### A. Helpdesk Dashboard (`/projects/<project_identifier>/helpdesk/dashboard`)
- View live counts and ticket lists for **Open Tickets**, **Unassigned Queue**, **SLA Breached**, and **My Assigned Tickets**.
- Use the checkboxes at the top-right to show or hide any widget; your layout is saved automatically per browser.

### B. SLA Badge & Canned Responses on Tickets
- Open any ticket in a Helpdesk-enabled project.
- Above the issue details, you will see:
  - **Helpdesk SLA:** `elapsed_hours / target_hours` (`On Track` or `BREACHED`).
  - **Insert Canned Response...** dropdown: selecting a template appends its body directly into the **Notes** box.

### C. Cross-Project Developer Escalation
To escalate a customer ticket to an engineering/developer project without exposing internal notes:
- Send `POST /helpdesk/escalate/<ticket_id>` with:
  - `target_project_id`: ID of the engineering project
  - `assigned_to_id`: Developer user ID
- A **private** (`is_private: true`) task is created in the target project and linked to the customer ticket.

### D. Merging Duplicate Tickets
To merge a duplicate ticket into a master ticket:
- Send `POST /helpdesk/merge/<source_ticket_id>` with `target_issue_id=<master_ticket_id>`.
- All journals are moved to the master ticket, an audit note is recorded, and the duplicate ticket is closed.

---

## 4. Public Customer Portal
Share `/helpdesk/public/<project_identifier>` with external customers so they can submit tickets directly without needing a Redmine account.
