---
title: Section 83(b) Election
respondent_type: org_and_person
code: section_83_election
flow:
  BEGIN:
    _: issuance
  issuance:
    'holding_type:individual': person__taxpayer__signatory
    'holding_type:entity': org__taxpayer
    _: ERROR
  person__taxpayer__signatory:
    _: END
  org__taxpayer:
    _: org_representative__for_taxpayer__signatory
  org_representative__for_taxpayer__signatory:
    _: END
alignment:
  BEGIN:
    _: staff_review
  staff_review:
    yes: signature__for_signatory
    _: ERROR
  signature__for_signatory:
    yes: certified_mail
    _: staff_review
  certified_mail:
    yes: END
    _: staff_review
description: >
  An election under Section 83(b) of the Internal Revenue Code and an accompanying IRS cover letter. Please fill in your
  social security number and sign the election and cover letter, then proceed as follows:

  * Make three copies of the completed election form and one copy of the IRS cover letter.
  * Send the signed election form and cover letter, the copy of the cover letter, and a self-addressed stamped return
    envelope to the Internal Revenue Service Center where you would otherwise file your tax return. Even if an address
    for an Internal Revenue Service Center is already included in the forms below, it is your obligation to verify
    such address. This can be done by searching for the term “where to file” on www.irs.gov or by calling 1 (800)
    829-1040. If you are signing the election form by hand, be sure to send the original signed form to the IRS.
    Sending the election via certified mail, requesting a return receipt, with the certified mail number written on the
    cover letter is also recommended.
  * Deliver one copy of the completed election form to the Company.
  * Applicable state law may require that you attach a copy of the completed election form to your state personal income
    tax return(s) when you file it for the year (assuming you file a state personal income tax return). Please consult
    your personal tax advisor(s) to determine whether or not a copy of this Section 83(b) election should be filed with
    your state personal income tax return(s).
  * Retain one copy of the completed election form for your personal permanent records.  Note: An additional copy of
    the completed election form must be delivered to the transferee (recipient) of the property if the service provider
    and the transferee are not the same person.

  Please note that the election must be filed with the IRS within 30 days of the date of your restricted stock grant.
  Failure to file within that time will render the election void and you may recognize ordinary taxable income as your
  vesting restrictions lapse. The Company and its counsel cannot assume responsibility for failure to file the election
  in a timely manner under any circumstances.
---

Date: {{signatory.signature.inserted_at|date}}

Certified Mail Number: {{certified_mail.number}}

IRS Address: {{taxpayer.irs_address}}

Re:	Election Under Section 83(b) of the Internal Revenue Code

To Whom It May Concern:

Enclosed please find an executed form of election under Section 83(b) of the Internal Revenue Code of 1986, as amended,
filed with respect to an interest in {{issuance.share_class.org.name}}.

Also enclosed is a copy of this letter and a stamped, self-addressed envelope. Please acknowledge receipt of these
materials by marking the copy when received and returning it to the undersigned.

Thank you very much for your assistance.

Very truly yours,

{{signatory.signature.mark}}

{{signatory.name}}{% if taxpayer.is_entity %} on behalf of {{taxpayer.name}}.{% endif %}

## SECTION 83(B) ELECTION

Dated: {{signatory.signature.inserted_at|date}}

Department of the Treasury
Internal Revenue Service
{{taxpayer.irs_address}}

Re:	Election Under Section 83(b)
To Whom It May Concern:

The undersigned taxpayer hereby elects, pursuant to Section 83(b) of the Internal Revenue Code of 1986, as amended, to
include in gross income as compensation for services the excess (if any) of the fair market value of the shares
described below over the amount paid for those shares. The following information is supplied in accordance with Treasury
Regulation § 1.83-2:

1.  The name, social security number, address of the undersigned, and the taxable year for which this election is being
    made are:

    **Name**: {{taxpayer.name}}

    {{#if taxpayer.is_person}}
    **Social Security Number**: {{taxpayer.ssn}}
    {{else}}
    **Employer Identification Number**: {{taxpayer.ein}}
    {{/if}}

    **Address**: {{taxpayer.address}}

    **Taxable year**: {{issuance.taxable_year}}

    **Calendar year**: {{issuance.calendar_year}}

2.  The property that is the subject of this election: {{issuance.shares}} shares of
    {{issuance.share_class.name}} of {{issuance.share_class.org.name}}, a
    {{issuance.share_class.org.org_type.name}} from {{issuance.share_class.org.org_type.jurisdiction.name}}
    (the “Company”).

3.  The date on which the Shares were transferred to the undersigned: {{issuance.inserted_at|date}}.

4.	The Shares are subject to the following restrictions: {{issuance.restrictions}}.
5.	The fair market value of the Shares at the time of the transfer to the undersigned (determined without regard to any
    restriction other than a nonlapse restriction as defined in Treasury Regulation § 1.83-3(h)):

    {{issuance.fair_market_value_per_share|currency}} per Share x {{issuance.shares}} Shares =
    {{issuance.fair_market_value_of_shares|currency}}.

6.	The amount paid for the Shares transferred: {{issuance.amount_paid_per_share|currency}} per Share x
    {{issuance.shares}} Shares = {{issuance.amount_paid_for_shares|currency}}.
7.	The amount to include in gross income is: {{issuance.amount_to_include_in_gross_income|currency}}.

The undersigned taxpayer will file this election with the Internal Revenue Service office with which taxpayer files
taxpayer’s annual income tax return not later than 30 days after the date of transfer of the Shares. A copy of the
election also will be furnished to the person for whom the services were performed and the transferee of the Shares, if
any. The undersigned is the person performing the services in connection with which the Shares were transferred.

Very truly yours,

{{signatory.signature.mark}}

{{signatory.name}}{% if taxpayer.is_entity %} on behalf of {{taxpayer.name}}.{% endif %}
