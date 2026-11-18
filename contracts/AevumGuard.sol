// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
 * @title AevumGuard
 * @notice Non-custodial tUSD8 (0x456569838f1d43009A91ebA4263147Afd7233483) spending-cap,
 *         session-expiration, and merchant-allowlist payment guardrail for AI agents
 *         on QDay Aevum Testnet (Chain ID 44005).
 */
contract AevumGuard {
    IERC20 public immutable token;

    struct SessionPolicy {
        address owner;
        address agent;
        uint256 maxPerTx;
        uint256 totalBudget;
        uint256 spent;
        uint64 expiresAt;
        bool active;
    }

    uint256 public nextSessionId = 1;
    uint256 public totalPaymentsSettled;

    mapping(uint256 => SessionPolicy) public sessions;
    mapping(uint256 => mapping(address => bool)) public allowedMerchants;

    event SessionCreated(
        uint256 indexed sessionId,
        address indexed owner,
        address indexed agent,
        uint256 maxPerTx,
        uint256 totalBudget,
        uint64 expiresAt
    );
    event MerchantUpdated(uint256 indexed sessionId, address indexed merchant, bool allowed);
    event GuardedPaymentExecuted(
        uint256 indexed sessionId,
        address indexed agent,
        address indexed merchant,
        uint256 amount,
        string invoiceRef
    );
    event SessionRevoked(uint256 indexed sessionId, address indexed owner);

    error NotOwner();
    error NotAgent();
    error SessionInactive();
    error SessionExpired();
    error ExceedsPerTxCap();
    error ExceedsSessionBudget();
    error MerchantNotAllowed();
    error ZeroAmount();
    error TransferFailed();

    constructor(address _token) {
        token = IERC20(_token);
    }

    function createSession(
        address agent,
        uint256 maxPerTx,
        uint256 totalBudget,
        uint64 durationSeconds,
        address[] calldata merchants
    ) external returns (uint256 sessionId) {
        if (maxPerTx == 0 || totalBudget == 0 || durationSeconds == 0) revert ZeroAmount();

        sessionId = nextSessionId++;
        uint64 expiresAt = uint64(block.timestamp) + durationSeconds;

        sessions[sessionId] = SessionPolicy({
            owner: msg.sender,
            agent: agent,
            maxPerTx: maxPerTx,
            totalBudget: totalBudget,
            spent: 0,
            expiresAt: expiresAt,
            active: true
        });

        for (uint256 i = 0; i < merchants.length; i++) {
            allowedMerchants[sessionId][merchants[i]] = true;
            emit MerchantUpdated(sessionId, merchants[i], true);
        }

        emit SessionCreated(sessionId, msg.sender, agent, maxPerTx, totalBudget, expiresAt);
    }

    function setMerchant(uint256 sessionId, address merchant, bool allowed) external {
        if (sessions[sessionId].owner != msg.sender) revert NotOwner();
        allowedMerchants[sessionId][merchant] = allowed;
        emit MerchantUpdated(sessionId, merchant, allowed);
    }

    function executeAgentPayment(
        uint256 sessionId,
        address merchant,
        uint256 amount,
        string calldata invoiceRef
    ) external {
        SessionPolicy storage policy = sessions[sessionId];

        if (!policy.active) revert SessionInactive();
        if (msg.sender != policy.agent) revert NotAgent();
        if (block.timestamp > policy.expiresAt) revert SessionExpired();
        if (amount == 0) revert ZeroAmount();
        if (amount > policy.maxPerTx) revert ExceedsPerTxCap();
        if (policy.spent + amount > policy.totalBudget) revert ExceedsSessionBudget();
        if (!allowedMerchants[sessionId][merchant]) revert MerchantNotAllowed();

        policy.spent += amount;
        totalPaymentsSettled += 1;

        bool ok = token.transferFrom(policy.owner, merchant, amount);
        if (!ok) revert TransferFailed();

        emit GuardedPaymentExecuted(sessionId, msg.sender, merchant, amount, invoiceRef);
    }

    function revokeSession(uint256 sessionId) external {
        SessionPolicy storage policy = sessions[sessionId];
        if (policy.owner != msg.sender) revert NotOwner();
        policy.active = false;
        emit SessionRevoked(sessionId, msg.sender);
    }

    function remainingBudget(uint256 sessionId) external view returns (uint256) {
        SessionPolicy storage policy = sessions[sessionId];
        if (!policy.active || block.timestamp > policy.expiresAt) return 0;
        return policy.totalBudget - policy.spent;
    }
}
