;; Infrastructure Verification Contract
;; Validates water system components

(define-data-var admin principal tx-sender)

;; Data structure for infrastructure components
(define-map infrastructure-components
  { component-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    type: (string-ascii 50),
    location: (string-ascii 100),
    installation-date: uint,
    last-verified: uint,
    status: (string-ascii 20),
    verified-by: principal
  }
)

;; Public function to register a new component
(define-public (register-component
    (component-id (string-ascii 64))
    (name (string-ascii 100))
    (type (string-ascii 50))
    (location (string-ascii 100))
    (installation-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? infrastructure-components { component-id: component-id })) (err u100))
    (ok (map-set infrastructure-components
      { component-id: component-id }
      {
        name: name,
        type: type,
        location: location,
        installation-date: installation-date,
        last-verified: block-height,
        status: "active",
        verified-by: tx-sender
      }
    ))
  )
)

;; Public function to verify a component
(define-public (verify-component
    (component-id (string-ascii 64))
    (status (string-ascii 20)))
  (let ((component (unwrap! (map-get? infrastructure-components { component-id: component-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set infrastructure-components
        { component-id: component-id }
        (merge component {
          last-verified: block-height,
          status: status,
          verified-by: tx-sender
        })
      ))
    )
  )
)

;; Public function to get component details
(define-read-only (get-component (component-id (string-ascii 64)))
  (map-get? infrastructure-components { component-id: component-id })
)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
