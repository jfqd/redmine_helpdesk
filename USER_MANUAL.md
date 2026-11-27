# Redmine Enterprise Helpdesk — Complete Step-by-Step User Manual

Welcome! This guide walks you through everything from **first-time setup** to **daily agent workflows** in plain, easy-to-follow steps.

---

## Part 1: First-Time Setup (For Administrators)

### Step 1: Open Global Helpdesk Settings
1. Log in to Redmine as an **Administrator**.
2. Click **Administration** (top menu) → **Plugins**.
3. Find **Redmine Enterprise Helpdesk** and click **Configure**.
4. Here you can:
   - Set **Default First Response SLA (hours)** (e.g. `4`).
   - Set **Default Resolution SLA (hours)** (e.g. `24`).
   - Set an optional **Inbound Webhook Secret** to secure incoming email webhooks.
   - See your **Instant Inbound Webhook URL** (e.g. `https://your-redmine-domain/helpdesk/inbound_email`).
   - View the **Project Helpdesk Queues** table listing every active project.

### Step 2: Enable Helpdesk on a Project
1. In the **Project Helpdesk Queues** table, click **Configure** next to the project you want to turn into a support queue (or visit `/projects/<project_id>/helpdesk/settings`).
2. **Tab 1 — Mailbox & Routing:**
   - Check **Enable Helpdesk for this Project**.
   - **Dedicated Support Email:** Enter the email address customers write to (e.g. `support@clientA.com`). You can also use `##user-name## <support@clientA.com>` to show the agent's name in the customer's inbox.
   - **Reply-To Email:** Enter the same support email.
   - **Outgoing SMTP Settings:** Enter your **SMTP Host**, **Port** (`587`), **Username**, **Password**, and check **Enable STARTTLS / TLS**. Click **Save**, then click **Test SMTP Connection** to verify it works.
   - **Incoming IMAP Settings (if not using Webhook):** Enter **IMAP Host**, **Port** (`993`), **Username**, and **Password**.
   - **Modern Auth (Microsoft 365):** If using Exchange Online, switch **Authentication Mode** to **Modern Auth (Microsoft 365 / OAuth2 XOAUTH2)** and enter your **Tenant ID**, **Client ID**, and **Client Secret**.
3. **Tab 2 — SLA & Canned Responses:**
   - Set **First Response SLA (hours)** and **Resolution SLA (hours)** for this project.
   - Add **Canned Responses** (one per line, `Title | Body`):
     ```text
     Greeting | Thank you for contacting support. We are looking into your request.
     Resolved | Your issue has been resolved. Please reply if you need anything else.
     ```
   - Check **Send Auto-Reply Confirmation** if you want customers to receive an instant confirmation email + first note on new tickets.
   - **Auto-Priority Keywords:** Comma-separated words (e.g. `urgent, down, outage`) that automatically bump a new ticket's priority to Urgent/High.
   - **Spam / Blacklist Domains:** Comma-separated domains to block (e.g. `spam.com, blocked.org`).
   - **Blocked Attachment Extensions:** Comma-separated extensions to block (e.g. `.exe, .bat, .sh, .js`).
   - **Embeddable Support Widget:** Copy the `<script src="...">` snippet and paste it into any website to add a floating **Support** button.
4. Click **Save**.

---

## Part 2: Daily Agent Workflows

### 1. Using the Helpdesk Dashboard
- Click the **Helpdesk** tab in your project's top menu (or visit `/projects/<project_id>/helpdesk/dashboard`).
- You will see 4 live boxes: **Open Tickets**, **Unassigned Queue**, **SLA Breached**, and **My Assigned Tickets**.
- Use the checkboxes at the top right to hide/show any box (your preference is saved automatically).

### 2. Replying to Customers & Using Canned Responses
- Open any ticket in a Helpdesk-enabled project.
- At the top of the ticket, you will see:
  - **Helpdesk SLA:** Shows elapsed hours vs. target (`On Track` or `BREACHED`).
  - **Also viewing:** Warns you if another agent opened the same ticket in the last 2 minutes.
  - **CSAT:** Shows the customer's rating if they clicked a CSAT link.
- Click **Edit** and use the **Insert Canned Response...** dropdown to paste a saved reply into **Notes** with one click.

### 3. Escalating to a Developer Project
- If a support ticket needs engineering work in another project, send `POST /helpdesk/escalate/<ticket_id>` with `target_project_id` and `assigned_to_id`.
- A **private** developer task is created in the engineering project and linked to the customer ticket—internal developer notes are never exposed to the customer.

### 4. Merging Duplicate Tickets
- If a customer opens two tickets for the same issue, send `POST /helpdesk/merge/<duplicate_id>` with `target_issue_id=<master_id>`.
- All replies are moved to the master ticket and the duplicate is closed.

### 5. GDPR / Privacy Anonymization
- To erase a customer's email address from a ticket, send `POST /helpdesk/gdpr_anonymize/<ticket_id>`.

---

## Part 3: Customer Self-Service Portals (No Login Required)
- **Submit a Ticket:** Share `/helpdesk/public/<project_id>` with customers.
- **Check Status & Reply:** Share `/helpdesk/status` so customers can enter their Ticket ID, view status, and post a reply.
