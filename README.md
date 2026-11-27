# Redmine Enterprise Helpdesk (`v1.0.0`)

A modern, multi-domain Enterprise Helpdesk & Ticketing plugin for **Redmine 7.0+**.

*Maintained and developed by **Arean Narrayan** (<arean@synorastudio.in>)*

---

## Key Features

- **Multi-Domain Email Routing:** Assign a dedicated support email & domain per project (`support@clientA.com`, `help@clientB.io`).
- **Instant Inbound Email Webhook (`POST /helpdesk/inbound_email`):** Accepts real-time push payloads (Mailgun, SendGrid, Postmark, or raw MIME) and routes directly to the matching project.
- **Public / Anonymous Ticket Portal (`GET /helpdesk/public/:project_id`):** Customers can submit tickets without logging in.
- **SLA Tracking & Live Badges:** Configurable First Response and Resolution SLA hours per project, with live `On Track` / `BREACHED` badges on tickets.
- **Canned Responses:** Quick-insert reply templates directly on the issue view.
- **Cross-Project Developer Escalation (`POST /helpdesk/escalate/:id`):** Escalate customer tickets into private developer tasks in another project without leaking internal notes.
- **Ticket Merging (`POST /helpdesk/merge/:id`):** Merge duplicate customer tickets into a single master ticket.
- **User-Configurable Helpdesk Dashboard (`GET /projects/:project_id/helpdesk/dashboard`):** Live KPI cards and toggleable widgets (*Open*, *Unassigned*, *SLA Breached*, *My Assigned*).

---

## Configuration & Usage
- See [USER_MANUAL.md](USER_MANUAL.md) for setup, webhook integration, and agent workflows.

---

## License
MIT License. See [LICENSE](LICENSE).
