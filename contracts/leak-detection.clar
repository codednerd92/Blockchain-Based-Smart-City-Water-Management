;; Leak Detection Contract
;; Identifies system inefficiencies

(define-data-var admin principal tx-sender)

;; Data structure for leak reports
(define-map leak-reports
  { report-id: (string-ascii 64) }
  {
    location: (string-ascii 100),
    severity: uint,
    detection-time: uint,
    status: (string-ascii 20),
    reported-by: principal
  }
)

;; Counter for generating report IDs
(define-data-var report-counter uint u0)

;; Public function to report a leak
(define-public (report-leak
    (location (string-ascii 100))
    (severity uint))
  (let (
    (report-id (concat "LEAK-" (to-string (var-get report-counter))))
  )
    (begin
      ;; Increment the report counter
      (var-set report-counter (+ (var-get report-counter) u1))

      ;; Create the leak report
      (ok (map-set leak-reports
        { report-id: report-id }
        {
          location: location,
          severity: severity,
          detection-time: block-height,
          status: "reported",
          reported-by: tx-sender
        }
      ))
    )
  )
)

;; Public function to update leak status
(define-public (update-leak-status
    (report-id (string-ascii 64))
    (status (string-ascii 20)))
  (let ((report (unwrap! (map-get? leak-reports { report-id: report-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (ok (map-set leak-reports
        { report-id: report-id }
        (merge report {
          status: status
        })
      ))
    )
  )
)

;; Read-only function to get leak report
(define-read-only (get-leak-report (report-id (string-ascii 64)))
  (map-get? leak-reports { report-id: report-id })
)

;; Admin functions
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
