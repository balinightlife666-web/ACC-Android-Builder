# BBYA Mall v420 mobile visual finding

Observed after user restarted/joined three times on 2026-08-25 +08:00.

- Not a stale-server issue.
- Storefront authority v5 is present but visual result remains low-quality.
- Base tenant formula already places frontX on atrium side (~x +/-47); prior diagnosis that storefronts were reversed was incorrect.
- Real structural bug: SideA/SideB includes a full X-plane wall at the same frontX as StoreGlass.
- More importantly, base tenant design remains primitive and later visual passes stack on top: large R$ plaques, physical fascia slabs, glowing/colored blocks, flat directory slab, dark rectangular atrium stage, repetitive box shell.
- Next pass must replace tenant visual shells rather than patch them.

Evidence source: live user mobile screenshot after three rejoins; source inspected through GitHub cloud.