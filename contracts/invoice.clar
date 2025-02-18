;; Invoice Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var invoice-nonce uint u0)

;; Data Maps
(define-map invoices
  { invoice-id: uint }
  {
    supplier: principal,
    buyer: principal,
    amount: uint,
    due-date: uint,
    paid: bool
  }
)

;; Public Functions

;; Create a new invoice
(define-public (create-invoice (buyer principal) (amount uint) (due-date uint))
  (let
    (
      (invoice-id (var-get invoice-nonce))
    )
    (asserts! (is-none (map-get? invoices { invoice-id: invoice-id })) err-already-exists)
    (map-set invoices
      { invoice-id: invoice-id }
      {
        supplier: tx-sender,
        buyer: buyer,
        amount: amount,
        due-date: due-date,
        paid: false
      }
    )
    (var-set invoice-nonce (+ invoice-id u1))
    (ok invoice-id)
  )
)

;; Pay an invoice
(define-public (pay-invoice (invoice-id uint))
  (let
    (
      (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get buyer invoice)) err-unauthorized)
    (asserts! (not (get paid invoice)) err-unauthorized)
    (try! (stx-transfer? (get amount invoice) tx-sender (get supplier invoice)))
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice { paid: true })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get invoice details
(define-read-only (get-invoice (invoice-id uint))
  (ok (unwrap! (map-get? invoices { invoice-id: invoice-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set invoice-nonce u0)
)

