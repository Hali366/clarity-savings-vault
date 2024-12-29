;; CryptoNest Savings Vault Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant min-deposit u1000) ;; Minimum 1000 tokens
(define-constant max-deposit u1000000000) ;; Maximum 1B tokens

;; Data Variables
(define-data-var interest-rate uint u500) ;; 5.00% represented as basis points
(define-map deposits { user: principal } { balance: uint, deposit-time: uint })
(define-map total-deposits uint uint) ;; Track total deposits for interest calculations

;; Private Functions
(define-private (calculate-interest (principal uint) (time-elapsed uint))
    (let (
        (rate (var-get interest-rate))
        (time-factor (/ time-elapsed u31536000)) ;; Convert seconds to years
    )
    ;; Simple interest formula: principal * rate * time
    (/ (* (* principal rate) time-factor) u10000)
    )
)

;; Public Functions
(define-public (deposit (amount uint))
    (let (
        (sender tx-sender)
        (current-time block-height)
    )
    (asserts! (>= amount min-deposit) err-invalid-amount)
    (asserts! (<= amount max-deposit) err-invalid-amount)
    
    (map-set deposits { user: sender }
        {
            balance: amount,
            deposit-time: current-time
        }
    )
    
    ;; Update total deposits
    (map-set total-deposits u0 
        (+ (default-to u0 (map-get? total-deposits u0)) amount)
    )
    (ok true)
    )
)

(define-public (withdraw (amount uint))
    (let (
        (sender tx-sender)
        (deposit-info (unwrap! (map-get? deposits { user: sender }) err-insufficient-balance))
        (current-balance (get balance deposit-info))
        (deposit-time (get deposit-time deposit-info))
        (interest-earned (calculate-interest current-balance (- block-height deposit-time)))
        (total-available (+ current-balance interest-earned))
    )
    
    (asserts! (<= amount total-available) err-insufficient-balance)
    
    ;; Update balance after withdrawal
    (if (is-eq amount total-available)
        (map-delete deposits { user: sender })
        (map-set deposits { user: sender }
            {
                balance: (- total-available amount),
                deposit-time: block-height
            }
        )
    )
    
    ;; Update total deposits
    (map-set total-deposits u0 
        (- (default-to u0 (map-get? total-deposits u0)) amount)
    )
    (ok true)
    )
)

(define-read-only (get-balance (user principal))
    (let (
        (deposit-info (map-get? deposits { user: user }))
    )
    (if (is-some deposit-info)
        (let (
            (info (unwrap-panic deposit-info))
            (balance (get balance info))
            (deposit-time (get deposit-time info))
            (interest (calculate-interest balance (- block-height deposit-time)))
        )
        (ok (+ balance interest)))
        (ok u0)
    ))
)

(define-read-only (get-interest-rate)
    (ok (var-get interest-rate))
)

(define-public (update-interest-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set interest-rate new-rate)
        (ok true)
    )
)