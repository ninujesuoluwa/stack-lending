;; Title: StackLending: Decentralized Credit Protocol
;;
;; Summary: A trustless lending protocol that establishes on-chain credit scores
;; and enables collateralized loans with dynamic interest rates based on credit history.
;;
;; Description: 
;; StackLending creates a foundation for DeFi lending on Stacks by implementing:
;; 1. On-chain credit scoring based on borrowing/repayment history
;; 2. Dynamic collateral requirements tied to credit scores
;; 3. Risk-adjusted interest rates
;; 4. Transparent loan management with automated settlements
;;
;; The protocol enables capital-efficient borrowing for users who maintain good credit,
;; reducing collateral requirements as they demonstrate reliability.

;; Constants

(define-constant CONTRACT-OWNER tx-sender)

;; Error Codes
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-LOAN-NOT-FOUND (err u4))
(define-constant ERR-LOAN-DEFAULTED (err u5))
(define-constant ERR-INSUFFICIENT-SCORE (err u6))
(define-constant ERR-ACTIVE-LOAN (err u7))
(define-constant ERR-NOT-DUE (err u8))
(define-constant ERR-INVALID-DURATION (err u9))
(define-constant ERR-INVALID-LOAN-ID (err u10))

;; Credit Score Parameters
(define-constant MIN-SCORE u50)
(define-constant MAX-SCORE u100)
(define-constant MIN-LOAN-SCORE u70)

;; Data Maps

(define-map UserScores
  { user: principal }
  {
    score: uint,
    total-borrowed: uint,
    total-repaid: uint,
    loans-taken: uint,
    loans-repaid: uint,
    last-update: uint,
  }
)

(define-map Loans
  { loan-id: uint }
  {
    borrower: principal,
    amount: uint,
    collateral: uint,
    due-height: uint,
    interest-rate: uint,
    is-active: bool,
    is-defaulted: bool,
    repaid-amount: uint,
  }
)

(define-map UserLoans
  { user: principal }
  { active-loans: (list 20 uint) }
)

;; Variables

(define-data-var next-loan-id uint u0)
(define-data-var total-stx-locked uint u0)

;; User Management Functions

;; Initialize a new user's credit score
;; Creates a credit profile for a new user with the minimum score
(define-public (initialize-score)
  (let ((sender tx-sender))
    (asserts! (is-none (map-get? UserScores { user: sender })) ERR-UNAUTHORIZED)
    (ok (map-set UserScores { user: sender } {
      score: MIN-SCORE,
      total-borrowed: u0,
      total-repaid: u0,
      loans-taken: u0,
      loans-repaid: u0,
      last-update: stacks-block-height,
    }))
  )
)

;; Loan Functions

;; Request a new loan
;; Allows a user to request a loan with required collateral based on their credit score
(define-public (request-loan
    (amount uint)
    (collateral uint)
    (duration uint)
  )
  (let (
      (sender tx-sender)
      (loan-id (+ (var-get next-loan-id) u1))
      (user-score (unwrap! (map-get? UserScores { user: sender }) ERR-UNAUTHORIZED))
      (active-loans (default-to { active-loans: (list) } (map-get? UserLoans { user: sender })))
    )
    ;; Validate request
    (asserts! (>= (get score user-score) MIN-LOAN-SCORE) ERR-INSUFFICIENT-SCORE)
    (asserts! (<= (len (get active-loans active-loans)) u5) ERR-ACTIVE-LOAN)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (and (> duration u0) (<= duration u52560)) ERR-INVALID-DURATION)
    ;; Max ~1 year assuming 10-min blocks
    ;; Calculate required collateral based on credit score
    (let ((required-collateral (calculate-required-collateral amount (get score user-score))))
      (asserts! (>= collateral required-collateral) ERR-INSUFFICIENT-BALANCE)
      ;; Transfer collateral
      (try! (stx-transfer? collateral sender (as-contract tx-sender)))
      ;; Create loan
      (map-set Loans { loan-id: loan-id } {
        borrower: sender,
        amount: amount,
        collateral: collateral,
        due-height: (+ stacks-block-height duration),
        interest-rate: (calculate-interest-rate (get score user-score)),
        is-active: true,
        is-defaulted: false,
        repaid-amount: u0,
      })
      ;; Update user loans
      (try! (update-user-loans sender loan-id))
      ;; Transfer loan amount
      (as-contract (try! (stx-transfer? amount tx-sender sender)))
      ;; Update counters
      (var-set next-loan-id loan-id)
      (var-set total-stx-locked (+ (var-get total-stx-locked) collateral))
      (ok loan-id)
    )
  )
)

;; Repay an active loan
;; Allows a borrower to repay their loan, fully or partially
(define-public (repay-loan
    (loan-id uint)
    (amount uint)
  )
  (let (
      (sender tx-sender)
      (loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
    )
    (asserts! (is-eq sender (get borrower loan)) ERR-UNAUTHORIZED)
    (asserts! (get is-active loan) ERR-LOAN-NOT-FOUND)
    (asserts! (not (get is-defaulted loan)) ERR-LOAN-DEFAULTED)
    (asserts! (<= loan-id (var-get next-loan-id)) ERR-INVALID-LOAN-ID)
    ;; Calculate total amount due
    (let ((total-due (calculate-total-due loan)))
      (asserts! (>= amount u0) ERR-INVALID-AMOUNT)
      ;; Transfer repayment
      (try! (stx-transfer? amount sender (as-contract tx-sender)))
      ;; Update loan
      (let ((new-repaid-amount (+ (get repaid-amount loan) amount)))
        (map-set Loans { loan-id: loan-id }
          (merge loan {
            repaid-amount: new-repaid-amount,
            is-active: (< new-repaid-amount total-due),
          })
        )
        ;; If loan fully repaid, update score and return collateral
        (if (>= new-repaid-amount total-due)
          (begin
            (try! (update-credit-score sender true loan))
            (as-contract (try! (stx-transfer? (get collateral loan) tx-sender sender)))
            (var-set total-stx-locked
              (- (var-get total-stx-locked) (get collateral loan))
            )
          )
          true
        )
        (ok true)
      )
    )
  )
)

;; Helper Functions

;; Calculate collateral requirements based on credit score
;; Determines the collateral needed based on the user's credit score
(define-private (calculate-required-collateral
    (amount uint)
    (score uint)
  )
  (let ((collateral-ratio (- u100 (/ (* score u50) u100))))
    (/ (* amount collateral-ratio) u100)
  )
)

;; Calculate interest rate based on credit score
;; Determines the interest rate percentage based on the user's credit score
(define-private (calculate-interest-rate (score uint))
  (let ((base-rate u10))
    (- base-rate (/ (* score u5) u100))
  )
)

;; Calculate the total amount due including interest
;; Calculates the total amount due for a loan including interest
(define-private (calculate-total-due (loan {
  borrower: principal,
  amount: uint,
  collateral: uint,
  due-height: uint,
  interest-rate: uint,
  is-active: bool,
  is-defaulted: bool,
  repaid-amount: uint,
}))
  (let ((interest (* (get amount loan) (get interest-rate loan))))
    (+ (get amount loan) (/ interest u100))
  )
)