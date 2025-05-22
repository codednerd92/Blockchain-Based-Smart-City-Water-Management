;; Consumption Tracking Contract
;; Records water usage patterns

(define-data-var admin principal tx-sender)

;; Data structure for consumption records
(define-map consumption-records
  { meter-id: (string-ascii 64), timestamp: uint }
  {
    user-id: (string-ascii 64),
    consumption: uint,
    recorded-by: principal
  }
)

;; Map to track total consumption by user
(define-map user-consumption
  { user-id: (string-ascii 64) }
  { total-consumption: uint }
)

;; Public function to record consumption
(define-public (record-consumption
    (meter-id (string-ascii 64))
    (user-id (string-ascii 64))
    (consumption uint))
  (let (
    (timestamp block-height)
    (current-total (default-to { total-consumption: u0 } (map-get? user-consumption { user-id: user-id })))
  )
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))

      ;; Update user's total consumption
      (map-set user-consumption
        { user-id: user-id }
        { total-consumption: (+ consumption (get total-consumption current-total)) }
      )

      ;; Record this consumption entry
      (ok (map-set consumption-records
        { meter-id: meter-id, timestamp: timestamp }
        {
          user-id: user-id,
          consumption: consumption,
          recorded-by: tx-sender
        }
      ))
    )
  )
)

;; Read-only function to get consumption for a specific meter at a specific time
(define-read-only (get-consumption-record (meter-id (string-ascii 64)) (timestamp uint))
  (map-get? consumption-records { meter-id: meter-id, timestamp: timestamp })
)

;; Read-only function to get total consumption for a user
(define-read-only (get-user-consumption (user-id (string-ascii 64)))
  (default-to { total-consumption: u0 } (map-get? user-consumption { user-id: user-id }))
)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
