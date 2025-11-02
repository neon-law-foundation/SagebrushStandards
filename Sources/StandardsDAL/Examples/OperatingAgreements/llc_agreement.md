---
title: LLC Operating Agreement
respondent_type: org
code: llc_operating_agreement
flow:
  BEGIN:
    _: org__company
  org__company:
    _: formation_date__for_company
  formation_date__for_company:
    _: address__for_company
  address__for_company:
    _: registered_agent__for_company
  registered_agent__for_company:
    _: END
alignment:
  BEGIN:
    _: END
description: >
  This operating agreement is for a limited liability company (LLC) in the State of Nevada.
---

## Operating Agreement for {{company.name}}

## Article I: Company Formation

### 1.1 Name of the Company

The name of the Limited Liability Company ("Company") is **{{company.name}}**.

### 1.2 Formation

The Company was formed on **{{company.formation_date}}** pursuant to the laws of the State of Nevada by filing the
Articles of Organization with the Nevada Secretary of State.

### 1.3 Principal Place of Business

The principal office of the Company is located at **{{company.address}}**.

### 1.4 Registered Agent

The Company's registered agent in Nevada is **{{registered_agent.name}}**, located at
**{{registered_agent.address}}**.

### 1.5 Purpose

The purpose of the Company is to engage in any lawful business permitted under the laws of the State of Nevada.

## Article II: Members

### 2.1 Initial Members

The following persons or entities are the initial members of the Company:

| Member Name          | Contribution Type | Contribution Value | Membership Percentage |
|----------------------|-------------------|--------------------|-----------------------|
| {{ member_1_name }} | {{ contribution_1 }} | {{ value_1 }}      | {{ percentage_1 }}    |

### 2.2 Additional Members

Additional members may be admitted with the unanimous consent of all existing members.

### 2.3 Membership Interests

Each member's interest in the Company, including the allocation of profits and losses, shall be based on their
Membership Percentage.

---

## Article III: Management

### 3.1 Manager-Managed Company

The Company shall be managed by **{{ manager_name }}**, who shall serve as the Manager.

### 3.2 Powers of the Manager

The Manager is authorized to:

- Oversee the day-to-day operations of the Company.

- Enter into contracts and agreements on behalf of the Company.

- Hire, terminate, and supervise employees.

### 3.3 Limitations on the Manager

The Manager shall not take the following actions without the unanimous consent of the members:

- Amend the Operating Agreement.

- Admit new members.

- Merge or dissolve the Company.

---

## Article IV: Finances

### 4.1 Capital Contributions

Members are required to contribute the amounts specified in Section 2.1. No additional contributions are required unless
unanimously agreed upon.

### 4.2 Allocation of Profits and Losses

Profits and losses shall be allocated to members based on their Membership Percentages.

### 4.3 Distributions

Distributions shall be made to members at such times and in such amounts as determined by the Manager, subject to
applicable law and the Company's financial condition.

---

## Article V: Meetings

### 5.1 Annual Meetings

An annual meeting of the members shall be held at the principal office of the Company or another agreed-upon location.

### 5.2 Quorum and Voting

A quorum for meetings requires the presence of members holding a majority of the Membership Percentages. Decisions
require a majority vote unless otherwise specified in this Agreement.

---

## Article VI: Indemnification and Liability

### 6.1 Indemnification

The Company shall indemnify and hold harmless the Manager and members from any claims or liabilities arising from their
actions in good faith on behalf of the Company.

### 6.2 Liability

No member shall be personally liable for the debts or obligations of the Company beyond their capital contribution.

---

## Article VII: Dissolution

### 7.1 Events of Dissolution

The Company shall dissolve upon the occurrence of any of the following events:

- A unanimous vote of the members.

- The sale or disposition of all Company assets.

- The entry of a decree of judicial dissolution.

### 7.2 Winding Up

Upon dissolution, the Manager shall wind up the affairs of the Company, liquidate its assets, and distribute the
proceeds as follows:

1. To creditors, including members who are creditors.
2. To members in proportion to their positive capital account balances.

---

## Article VIII: Miscellaneous

### 8.1 Governing Law

This Operating Agreement shall be governed by and construed in accordance with the laws of the State of Nevada.

### 8.2 Amendments

This Agreement may be amended only by a written agreement signed by all members.

### 8.3 Entire Agreement

This Agreement constitutes the entire agreement of the members and supersedes all prior agreements.

---

**IN WITNESS WHEREOF**, the members have executed this Operating Agreement as of the **{{ agreement_date }}**.

| Member Name          | Signature          |
|----------------------|--------------------|
| {{ member_1_name }} | _________________  |
| {{ member_2_name }} | _________________  |
