;; Factoring Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-factored (err u103))

;; Data Variables
(define-data-var factoring-nonce uint u0)

;; Data Maps
(define-map factored-invoices
  { factoring-id: uint }
  {
    invoice-id: uint,
    factor: principal,
    amount: uint,
    fee: uint
  }
)

;; Public Functions

;; Factor an invoice
(define-public (factor-invoice (invoice-id uint) (fee uint))
  (let
    (
      (invoice (unwrap! (contract-call? .invoice get-invoice invoice-id) err-not-found))
      (factoring-id (var-get factoring-nonce))
    )
    (asserts! (is-eq tx-sender (get supplier invoice)) err-unauthorized)
    (asserts! (not (get paid invoice)) err-unauthorized)
    (asserts! (is-none (map-get? factored-invoices { factoring-id: factoring-id })) err-already-factored)
    (try! (stx-transfer? (- (get amount invoice) fee) tx-sender (get supplier invoice)))
    (map-set factored-invoices
      { factoring-id: factoring-id }
      {
        invoice-id: invoice-id,
        factor: tx-sender,
        amount: (get amount invoice),
        fee: fee
      }
    )
    (var-set factoring-nonce (+ factoring-id u1))
    (ok factoring-id)
  )
)

;; Collect factored invoice payment
(define-public (collect-factored-payment (factoring-id uint))
  (let
    (
      (factored-invoice (unwrap! (map-get? factored-invoices { factoring-id: factoring-id }) err-not-found))
      (invoice (unwrap! (contract-call? .invoice get-invoice (get invoice-id factored-invoice)) err-not-found))
    )
    (asserts! (is-eq tx-sender (get factor factored-invoice)) err-unauthorized)
    (asserts! (get paid invoice) err-unauthorized)
    (try! (stx-transfer? (get amount factored-invoice) (get buyer invoice) tx-sender))
    (ok true)
  )
)

;; Read-only Functions

;; Get factored invoice details
(define-read-only (get-factored-invoice (factoring-id uint))
  (ok (unwrap! (map-get? factored-invoices { factoring-id: factoring-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set factoring-nonce u0)
)

