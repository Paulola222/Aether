# 🩺 Aether: ER Triage Assessment System

**Aether** is a smart Emergency Room triage solution built on the Salesforce platform. It helps clinicians assess patients quickly and accurately using the Emergency Severity Index (ESI), while automating treatment area assignments, red flag detection, and clinical decision support.

---

## 🚀 Key Features

- ✅ ESI Level calculation with clinical rationale
- 📝 Dynamic symptom-based assessment (max 8 questions)
- 🧭 Automatic assignment to treatment areas (e.g., Intermediate Care, Main ER)
- 📋 Critical alerts to monitor high-risk symptoms
- 🔄 Seamless integration with Salesforce Case records
- 🔒 Restricted picklist validation for `AssignedArea__c`
- 🧪 Prompt-driven triage question generation

---

## 🧰 Tech Stack

- **Salesforce Platform** — built natively with metadata customization
- **Lightning Web Components (LWC)** — interactive UI for triage flow
- **Apex (async)** — backend logic for ESI scoring and data persistence
- **Custom Metadata & Picklists** — flexible area assignments
- **Salesforce `sf` CLI** — for deployment and local development

---

## 📦 Project Structure

---

## 🧑‍💻 Setup Instructions (using `sf` CLI)

### Prerequisites

- Salesforce CLI (`sf`)
- Dev Hub & scratch org access
- Git
- Node.js (for local LWC dev)