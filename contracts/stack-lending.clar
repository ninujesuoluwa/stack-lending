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