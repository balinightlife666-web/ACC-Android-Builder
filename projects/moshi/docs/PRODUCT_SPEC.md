# MOSHI — PRODUCT SPEC v1.0

## Primary navigation
- Chats
- Communities
- Business
- Activity
- Me

Discover can be introduced after the core communication loops are stable.

## Account
Each user has an immutable internal MOSHI ID, display name, unique username, avatar, and device sessions. Public identity must not require exposing a phone number.

## Personal chat MVP
- text
- emoji
- images
- video
- files
- voice notes
- reply
- reactions
- edit/delete
- forward/copy
- pin
- read receipts
- typing indicator
- presence

## Groups MVP
- create group
- avatar/description
- invite members/link
- owner/admin/moderator/member roles
- mute/leave/remove

## Business Mode MVP
A personal account can enable Business Mode in-place.

Business profile fields:
- business name
- handle
- category
- description
- logo/cover
- address (optional)
- opening hours
- links

Catalog item fields:
- title
- product or service type
- images
- price and currency
- description
- variants/options
- stock/availability (optional)
- active/inactive

Customer workflow:
Catalog → Item → Ask / Order / Book → Chat → Order Draft → Confirmed → Processing → Completed/Cancelled

Business utilities:
- quick replies
- greeting message
- away message
- labels
- customer notes (private)
- order status

## AI Summary MVP
Input: conversation ID + unread range or selected range.
Output:
- short summary
- key points
- decisions
- action items
- important messages
- important links/files

The service must preserve source message IDs for traceability.

## Future
- AI natural-language chat search
- voice-note transcription
- translation
- smart replies
- follow-up detection for business chats
- invoice/payment integrations
