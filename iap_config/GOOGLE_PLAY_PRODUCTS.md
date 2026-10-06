# Google Play IAP — StepFlow

Package: `com.StepFlowMNG.StepFlow`

Remote config: `https://api2.blwsmartware.net/N297.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `sf_pack_1` | 50 |
| `sf_pack_2` | 100 |
| `sf_pack_3` | 200 |
| `sf_pack_4` | 350 |
| `sf_pack_5` | 500 |
| `sf_pack_6` | 750 |
| `sf_pack_7` | 1000 |
| `sf_pack_8` | 1500 |
| `sf_pack_9` | 2200 |
| `sf_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `sf_remove_ads` | Hide the banner |
| `sf_pro` | More than 8 custom workflows |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
