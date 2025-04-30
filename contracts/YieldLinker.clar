(define-constant contract-owner tx-sender)

;; Add block height function
(define-read-only (get-block-height)
    (ok burn-block-height))

;; A map tracking each user's deposit data.
(define-map user-deposits 
  {user: principal}
  {amount: uint, deposit-time: uint, yield: uint})

;; A variable tracking the total amount deposited.
(define-data-var total-deposits uint u0)

;; Public function: deposit funds into YieldLinker.
(define-public (deposit (amount uint))
  (begin
    ;; Transfer funds from sender to contract.
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    ;; Update total deposits.
    (var-set total-deposits (+ (var-get total-deposits) amount))
    ;; Check if the user already has a deposit record.
    (if (is-some (map-get? user-deposits {user: tx-sender}))
        (let ((current (unwrap-panic (map-get? user-deposits {user: tx-sender})))
              (height burn-block-height))
          (map-set user-deposits
            {user: tx-sender}
            {amount: (+ (get amount current) amount),
             deposit-time: height,
             yield: (get yield current)}))
        ;; Else, create a new record.
        (let ((height burn-block-height))
          (map-set user-deposits 
            {user: tx-sender}
            {amount: amount,
             deposit-time: height,
             yield: u0})))
    (ok "Deposit successful")))

;; Read-only function to get a user's deposit record.
(define-read-only (get-deposit (user principal))
  (match (map-get? user-deposits {user: user})
    deposit-data (ok deposit-data)
    (err "No deposit found")))
