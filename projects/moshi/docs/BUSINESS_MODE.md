# MOSHI — BUSINESS MODE v1.0

## Rule
Business is a mode inside the main MOSHI app. No separate APK.

## Profile model
One user owns one or more business profiles. A business profile can have members/roles in a later phase so staff can answer customers without sharing passwords.

## Catalog
Catalog supports both goods and services. This is required because MOSHI should work for sellers as well as service businesses such as DJs, photographers, salons, venues, freelancers and event providers.

## Chat-first commerce
MOSHI does not force checkout before conversation. Every product/service can be shared directly into chat as a structured card.

Card actions:
- Ask
- Order
- Book
- Share

## Order draft
An order draft is a structured object attached to a customer conversation. Initial status model:
- inquiry
- awaiting_confirmation
- confirmed
- processing
- completed
- cancelled

## Automation
Business Mode can configure:
- greeting
- away message
- quick replies
- labels

AI-assisted business features are advisory: summarize customer context, draft replies, identify unanswered leads, and extract potential orders. AI must not autonomously commit financial transactions.
