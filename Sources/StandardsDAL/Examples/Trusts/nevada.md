---
title: Nevada Trust
respondent_type: org
code: nevada_trust
flow:
  BEGIN:
    _: person__trustee
  person__trustee:
    _: END
alignment:
  BEGIN:
    _: staff_review
  staff_review:
    _: notarization__for_trustee
  notarization__for_trustee:
    yes: END
    _: staff_review
description: >
  A basic Nevada trust.
---

## Community Property

Nevada is a community property state but does not recognize a community property
trust. Should the laws change, we will
update this document to reflect the new laws.
