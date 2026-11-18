# 🛡️ AevumGuard — Non-Custodial tUSD8 Guardrails for AI Agents

**Live Contract (`QDay Aevum Testnet`, Chain ID `44005`):** `0xc83B216791017805FC35a1ECfc85712c8994EEEF`  
**Settlement Token (`tUSD8`, 6 decimals):** `0x456569838f1d43009A91ebA4263147Afd7233483`  
**Live Web Demo:** `https://zerocentplus.github.io/aevum-guard-pay/`

---

## Problem Statement
When autonomous AI agents or automated scripts are given direct ERC-20 spending authority, a single prompt injection, logic bug, or compromised session key can drain the user's entire stablecoin balance (*runaway spending*).

## Architecture & Security Controls
**AevumGuard** enforces deterministic, on-chain least-privilege guardrails around `tUSD8` payments without taking custody of user funds:
1. **Per-Transaction Spend Cap (`maxPerTx`):** Rejects any single payment exceeding the configured threshold (`ExceedsPerTxCap`).
2. **Cumulative Session Budget (`totalBudget`):** Tracks cumulative spend per session and blocks overspending (`ExceedsSessionBudget`).
3. **Time-Bounded Session Expiration (`expiresAt`):** Automatically invalidates agent permissions after `durationSeconds` (`SessionExpired`).
4. **Merchant Allowlist (`allowedMerchants`):** Restricts payouts strictly to owner-approved recipient addresses (`MerchantNotAllowed`).
5. **Instant Owner Kill-Switch (`revokeSession`):** Allows immediate single-transaction revocation of an active agent session.
6. **Verifiable Audit Trail:** Emits indexed `SessionCreated`, `GuardedPaymentExecuted`, and `SessionRevoked` events with invoice references.

## Quickstart
1. Open the live web dashboard (`https://zerocentplus.github.io/aevum-guard-pay/`) and connect MetaMask on **QDay Aevum Testnet (Chain ID 44005)**.
2. Click **Step 1A: Approve tUSD8 for Guard** to grant a bounded ERC-20 allowance.
3. Configure your AI agent address, per-tx cap, total session budget, expiration window, and allowed merchant, then click **Step 1B: Create Guarded Session**.
4. Execute guarded `tUSD8` payments with an invoice reference or test instant revocation via **Instant Revoke Session**.

## Built By
**David Kirvalidze (ZeroCentPlus Security Research)** — [Portfolio](https://zerocentplus.framer.website) · [GitHub](https://github.com/zerocentplus)
