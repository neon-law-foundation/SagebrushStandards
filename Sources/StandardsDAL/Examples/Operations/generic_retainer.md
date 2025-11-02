---
title: Legal Services Retainer Agreement
respondent_type: org
code: org_retainer_template
flow:
  BEGIN:
    _: client_information
  client_information:
    company_name: text
    contact_person: text
    email: email
    phone: text
    address: text
    _: client_representative
  client_representative:
    _: END
alignment:
  BEGIN:
    _: neon_person__neon_representative
  neon_person__neon_representative:
    _: verify_eligible_lawyer__for__client_representative
  verify_eligible_lawyer__for__client_representative:
    _: staff_review
  staff_review:
    _: signature__for__client_representative
  signature__for__client_representative:
    yes: signature__for__neon_representative
    _: staff_review
  signature__for__neon_representative:
    yes: END
    _: staff_review
description: >
  Legal services engagement agreement between Neon Law and {{client_information.company_name}},
  effective {{effective_date}}.
---

Date: {{effective_date}}

## LEGAL SERVICES RETAINER AGREEMENT

Between: **Neon Law** ("Attorney" or "Firm")
And: **{{client_information.company_name}}** ("Client")

## Scope and Purpose

The Client seeks legal representation from Neon Law for specific legal matters as may be agreed upon from
time to time. Neon Law's mission is to provide accurate, affordable, and accessible legal services. This
professional relationship is optimized through thorough advance preparation and clear written communication.

## Term and Termination

This Retainer Agreement ("Agreement") becomes effective on {{effective_date}}. **The Client maintains the
absolute right to terminate this Agreement at any time, for any reason, with or without cause.** Upon
termination by either party, the Client is responsible only for payment of fees and costs incurred prior to
the effective date of termination.

Neon Law reserves the right to terminate representation in accordance with applicable rules of professional
conduct. Upon termination, Neon Law will make reasonable efforts to assist the Client in securing alternative
counsel and will promptly return any client files and unused retainer funds.

## Use of Artificial Intelligence

**Neon Law may utilize artificial intelligence tools and technologies in the provision of legal services,
including but not limited to document review, legal research, and administrative tasks.** All AI-assisted
work is subject to attorney review and supervision. The Client consents to the use of such technologies while
acknowledging that attorney oversight remains constant throughout all AI-assisted processes.

## Trust Accounting and Payment Terms

**Neon Law maintains IOLTA (Interest on Lawyers Trust Account) trust accounts in compliance with applicable
bar regulations.** All client funds are held in trust until earned through the performance of legal services.
**Neon Law will only withdraw funds from the trust account for services already rendered and costs already
incurred.**

The Client may be required to deposit an initial retainer, the amount of which will be determined based on
the scope of anticipated services. Detailed invoices will be provided monthly, clearly delineating services
performed and costs incurred. **The Client retains the right to request an accounting of trust funds at any
time.**

All invoices are due within thirty (30) days of issuance. Failure to remit timely payment may result in
suspension of legal services, subject to applicable rules of professional conduct.

## Communication Protocol

To maximize efficiency and maintain cost-effectiveness, Neon Law operates primarily through digital channels.
The Client agrees to utilize the approved communication methods detailed on our
[Support](https://www.neonlaw.com/support) page. While telephone consultation may be available by appointment,
written communication is preferred for all substantive legal matters.

## Appointment Scheduling

Clients requiring attorney consultation must schedule appointments through our designated
[Client calendar](https://cal.com/team/neon-law/consultation) system. Attorney consultations require advance
scheduling and may require pre-payment.

## Attorney Assignment

Neon Law maintains sole discretion in assigning and reassigning attorneys to Client matters. Neon Law ensures
all assigned attorneys maintain appropriate licensure, continuing education compliance, and ethical clearance
for representation in the relevant jurisdiction(s).

## Client's Right to Cancel

**The Client expressly retains the unrestricted right to cancel this Agreement and terminate legal services
at any time, for any reason, with immediate effect upon written notice.** Such termination shall not affect
the Client's obligation to pay for services already rendered and costs already incurred prior to the
effective date of termination.

## Constitutional and Regulatory Compliance

This Agreement is subordinate to and shall not supersede Neon Law's obligations under the United States
Constitution, applicable state constitutions, rules of professional conduct, and all applicable laws and
regulations governing the practice of law.

## Data Usage and De-identification

Neon Law maintains a commitment to expanding access to justice through legal technology and open-source
initiatives. The Client hereby grants permission for Neon Law to de-identify and incorporate provided
documents into its legal research and development initiatives, following the complete removal of all
personally identifiable information and attorney-client privileged materials.

## Confidentiality and Attorney-Client Privilege

All communications between Client and Neon Law are protected by attorney-client privilege and the duty of
confidentiality. This protection extends to all AI-assisted work product and technological tools utilized in
the representation.

## Dispute Resolution

Any disputes arising from or relating to this Agreement, including matters of attorney-client privilege and
fee disputes, shall be resolved through binding arbitration administered by the American Arbitration
Association under its Commercial Arbitration Rules. The prevailing party shall be entitled to reasonable
attorneys' fees and costs.

## Third-Party Service Limitation

Neon Law assumes no liability for any third-party services, software, or platforms utilized by the Client in
conjunction with our services, including but not limited to data breaches, service interruptions, or loss of
data resulting from such third-party service usage.

## Governing Law and Jurisdiction

This Agreement shall be governed by and construed in accordance with the laws of the State of Nevada and
applicable rules of professional conduct, without regard to conflict of laws principles. The parties consent
to the jurisdiction of state and federal courts located in Washoe County, Nevada, for any legal proceedings
arising from this Agreement.

## Entire Agreement

This Agreement constitutes the entire agreement between the parties and supersedes all prior negotiations,
representations, or agreements relating to the subject matter herein. This Agreement may only be modified in
writing, signed by both parties.

---

## CLIENT SIGNATURE

{{client_representative.signature}}
Name: {{client_information.contact_person}}
Title: _______________________
Company: {{client_information.company_name}}
Date: _______________________

## ATTORNEY SIGNATURE

{{neon_representative.signature}}
Name: _______________________
Title: _______________________
Neon Law
Date: _______________________
