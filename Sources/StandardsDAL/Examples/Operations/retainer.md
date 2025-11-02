---
title: Retainer
respondent_type: org
code: retainer
flow:
  BEGIN:
    _: person__client
  person__client:
    _: neon_person__neon_representative
  neon_person__neon_representative:
    _: END
alignment:
  BEGIN:
    _: staff_review
  staff_review:
    _: notarization__for_client
  notarization__for_client:
    yes: verify_eligible_lawyer__for_neon_representative
    _: staff_review
  verify_eligible_lawyer__for_neon_representative:
    yes: signature__for_neon_representative
    _: staff_review
  signature__for_neon_representative:
    yes: END
    _: staff_review
description: >
  Legal representation commences only upon execution of this retainer agreement by both an authorized representative of
  the organization and a licensed attorney of Neon Law.
---

Date: {{neon_representative.signature.inserted_at|date}}

## Scope and Purpose

The Client seeks legal representation from Neon Law ("the Firm") for specific legal matters. The Firm's mission is to
provide accurate, affordable, and accessible legal services. This mutual relationship is optimized through thorough
advance preparation and written communication.

## Term and Termination

This Retainer Agreement ("Agreement") becomes effective on {{neon_representative.signature.inserted_at|date}}. The
Client maintains the right to terminate this Agreement at any time, subject to payment of fees incurred prior to
termination.

The Firm reserves the right to terminate representation at its discretion. Upon termination, the Firm will make
reasonable efforts to assist the Client in securing alternative counsel.

Unless otherwise agreed to in writing, the attorney-client privilege will end in ten years from the date of the
notarization of this Agreement.

## Communication Protocol

To maximize efficiency and maintain cost-effectiveness, the Firm operates exclusively through digital channels. The
Client agrees to utilize only the approved communication methods detailed on our [Support](/support) page. Telephone
support is not provided.

## Appointment Scheduling

Active clients requiring attorney consultation must schedule appointments through the designated [Client calendar][1]
system.

## Attorney Assignment

The Firm maintains sole discretion in assigning and reassigning attorneys to Client matters. The Firm ensures all
assigned attorneys maintain appropriate licensure and ethical clearance for representation.

## Constitutional and Regulatory Compliance

This Agreement is subordinate to and shall not supersede the Firm's obligations under the United States Constitution,
the state constitutions of Nevada, California, and Washington, and all applicable laws and regulations.

## Data Usage and De-identification

The Firm maintains a commitment to expanding access to justice. The Client hereby grants permission for the Firm to
de-identify and incorporate provided documents into its open-source legal repository, following the removal of all
personally identifiable information.

## Billing and Payment Terms

The Firm shall invoice the Client within thirty (30) days of service completion. The Firm does not maintain trust
accounts and bills solely for services rendered. All invoices are due within thirty (30) days of issuance.

Failure to remit timely payment constitutes a breach of this Agreement and may result in:

1. Suspension of legal services
2. Pursuit of outstanding fees through debt collection
3. Termination of representation

## Dispute Resolution

Any disputes arising from or relating to this Agreement, including matters of attorney-client privilege, shall be
resolved through binding arbitration administered by the American Arbitration Association under its Commercial
Arbitration Rules. Any arbitration award may be entered as judgment in any court of competent jurisdiction.

## Third-Party Service Limitation

The Firm assumes no liability for any third-party services utilized by the Client in conjunction with our services,
including but not limited to data breaches or loss of data resulting from such third-party service usage.

## Governing Law and Jurisdiction

This Agreement shall be governed by and construed in accordance with the laws of the State of Nevada, without regard to
its conflict of laws principles. The parties consent to the exclusive jurisdiction of state and federal courts located
in Washoe County, Nevada, for any legal proceedings arising from this Agreement.

{{client.notarization.signature}}

{{client.notarization.inserted_at|date}}

{{client.name}}

{{client.notarization.stamp}}

[1]: https://cal.com/team/neon-law/consultation
