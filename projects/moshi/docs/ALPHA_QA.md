# MOSHI Internal Alpha v0.1 — Two-Device QA

Run this checklist against one pinned APK build and one stable backend endpoint. Record the APK SHA256 and backend commit before testing.

## Gate 0 — server
- `/health` returns 200.
- `/ready` returns 200.
- Restart API and confirm accounts/messages persist.
- If using proper alpha, restart PostgreSQL/API containers and confirm persistence.

## Gate 1 — identity
- Device A creates account A.
- Device B creates account B.
- Close/reopen both apps and confirm session restore.
- Edit display name and confirm persistence.

## Gate 2 — direct realtime chat
- A finds B by username and opens direct chat.
- A sends text; B receives it without manual refresh.
- B replies.
- Verify sent/delivered/read states.
- Edit and soft-delete own message.
- Add/remove reactions.

## Gate 3 — offline resilience
- Disable network on A.
- Send a text and confirm queued state.
- Re-enable network and confirm automatic send without duplicate message.
- Repeat with app restart while the text is queued.

## Gate 4 — media
- Send photo.
- Send supported document.
- Send voice note.
- Open/download received attachment on the other device.
- Queue an attachment offline, restart app, restore network, and confirm one successful upload/message.

## Gate 5 — groups
- Create group containing A and B.
- Send realtime group messages.
- Test admin/moderator/member permissions.
- Remove a member and confirm access is revoked.

## Gate 6 — Business Mode
- Enable Business Mode on A.
- Create Business Profile.
- Add one product with photo, price and stock.
- Add one service.
- Share product/service card to B.
- B taps Ask and sends inquiry.
- B taps Order and receives an Order Draft card.
- B submits order for confirmation.
- A confirms; verify stock decrements exactly once.
- A moves order to processing then completed.
- Run a second order and cancel it after confirmation; verify stock restoration.

## Gate 7 — CRM
- A creates quick reply.
- A creates labels such as `Hot Lead` and `VIP`.
- Assign/remove labels from B.
- Verify another business account cannot see A's customer labels.

## Gate 8 — notifications
This gate remains BLOCKED until Firebase is provisioned.
- Background B; send message from A; receive one notification.
- Kill B app process; send from A; receive one notification.
- Open active conversation and confirm no duplicate foreground notification.
- Test Android notification permission denied then allowed.
- Verify FCM token rotation/re-registration.

## Pass criteria
Internal Alpha communication core passes only when Gates 0–7 pass on physical Android devices. Notification readiness is tracked separately until Firebase activation. AI Catch Me Up should not be treated as device-ready until this baseline is stable.
