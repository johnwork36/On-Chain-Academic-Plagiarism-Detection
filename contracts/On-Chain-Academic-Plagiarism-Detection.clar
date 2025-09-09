(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_INSTITUTION (err u103))
(define-constant ERR_INVALID_HASH (err u104))

(define-constant ERR_INVALID_LICENSE (err u105))
(define-constant ERR_LICENSE_EXISTS (err u106))

(define-constant LICENSE_PUBLIC u1)
(define-constant LICENSE_INSTITUTIONAL u2)
(define-constant LICENSE_RESTRICTED u3)
(define-constant LICENSE_PRIVATE u4)

(define-constant CITATION_DIRECT u1)
(define-constant CITATION_INDIRECT u2)
(define-constant CITATION_DERIVATIVE u3)


(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var total-submissions uint u0)
(define-data-var total-institutions uint u0)

(define-map submissions
  { content-hash: (buff 32) }
  {
    institution: principal,
    course-code: (string-ascii 20),
    student-id: (string-ascii 50),
    submission-type: (string-ascii 20),
    timestamp: uint,
    block-height: uint,
    verified: bool
  }
)

(define-map institutions
  { institution: principal }
  {
    name: (string-ascii 100),
    verified: bool,
    total-submissions: uint,
    flagged-submissions: uint,
    reputation-score: uint
  }
)

(define-map content-duplicates
  { content-hash: (buff 32) }
  { duplicate-count: uint, first-submission: uint }
)

(define-map institution-submissions
  { institution: principal, submission-index: uint }
  { content-hash: (buff 32) }
)

(define-public (register-institution (name (string-ascii 100)))
  (let ((institution tx-sender))
    (if (is-none (map-get? institutions { institution: institution }))
      (begin
        (map-set institutions 
          { institution: institution }
          {
            name: name,
            verified: false,
            total-submissions: u0,
            flagged-submissions: u0,
            reputation-score: u100
          }
        )
        (var-set total-institutions (+ (var-get total-institutions) u1))
        (ok true)
      )
      (err ERR_ALREADY_EXISTS)
    )
  )
)

(define-public (verify-institution (institution principal))
  (if (is-eq tx-sender (var-get contract-owner))
    (match (map-get? institutions { institution: institution })
      existing-data
      (begin
        (map-set institutions 
          { institution: institution }
          (merge existing-data { verified: true })
        )
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
    (err ERR_UNAUTHORIZED)
  )
)

(define-public (submit-content (content-hash (buff 32)) (course-code (string-ascii 20)) (student-id (string-ascii 50)) (submission-type (string-ascii 20)))
  (let (
    (institution tx-sender)
    (current-block stacks-block-height)
    (current-time (default-to u0 (get-stacks-block-info? time current-block)))
    (submission-count (var-get total-submissions))
  )
    (match (map-get? institutions { institution: institution })
      institution-data
      (if (get verified institution-data)
        (if (is-none (map-get? submissions { content-hash: content-hash }))
          (begin
            (map-set submissions
              { content-hash: content-hash }
              {
                institution: institution,
                course-code: course-code,
                student-id: student-id,
                submission-type: submission-type,
                timestamp: current-time,
                block-height: current-block,
                verified: true
              }
            )
            (map-set institution-submissions
              { institution: institution, submission-index: (get total-submissions institution-data) }
              { content-hash: content-hash }
            )
            (map-set institutions
              { institution: institution }
              (merge institution-data { total-submissions: (+ (get total-submissions institution-data) u1) })
            )
            (var-set total-submissions (+ submission-count u1))
            (ok content-hash)
          )
          (begin
            (match (map-get? content-duplicates { content-hash: content-hash })
              existing-duplicate
              (map-set content-duplicates
                { content-hash: content-hash }
                { duplicate-count: (+ (get duplicate-count existing-duplicate) u1), first-submission: (get first-submission existing-duplicate) }
              )
              (map-set content-duplicates
                { content-hash: content-hash }
                { duplicate-count: u1, first-submission: current-time }
              )
            )
            (map-set institutions
              { institution: institution }
              (merge institution-data { flagged-submissions: (+ (get flagged-submissions institution-data) u1) })
            )
            (err ERR_ALREADY_EXISTS)
          )
        )
        (err ERR_INVALID_INSTITUTION)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

(define-read-only (check-plagiarism (content-hash (buff 32)))
  (match (map-get? submissions { content-hash: content-hash })
    submission-data
    (ok { 
      exists: true,
      institution: (get institution submission-data),
      course-code: (get course-code submission-data),
      submission-type: (get submission-type submission-data),
      timestamp: (get timestamp submission-data),
      block-height: (get block-height submission-data),
      duplicate-info: (map-get? content-duplicates { content-hash: content-hash })
    })
    (ok { exists: false, institution: tx-sender, course-code: "", submission-type: "", timestamp: u0, block-height: u0, duplicate-info: none })
  )
)

(define-read-only (get-submission-details (content-hash (buff 32)))
  (map-get? submissions { content-hash: content-hash })
)

(define-read-only (get-institution-info (institution principal))
  (map-get? institutions { institution: institution })
)

(define-read-only (get-institution-submission (institution principal) (index uint))
  (map-get? institution-submissions { institution: institution, submission-index: index })
)

(define-read-only (get-duplicate-info (content-hash (buff 32)))
  (map-get? content-duplicates { content-hash: content-hash })
)

(define-read-only (get-total-submissions)
  (var-get total-submissions)
)

(define-read-only (get-total-institutions)
  (var-get total-institutions)
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-public (update-contract-owner (new-owner principal))
  (if (is-eq tx-sender (var-get contract-owner))
    (begin
      (var-set contract-owner new-owner)
      (ok true)
    )
    (err ERR_UNAUTHORIZED)
  )
)

(define-map content-licenses
  { content-hash: (buff 32) }
  {
    license-type: uint,
    attribution-required: bool,
    commercial-use: bool,
    modification-allowed: bool,
    expiry-block: (optional uint),
    licensing-institution: principal
  }
)

(define-public (set-content-license 
  (content-hash (buff 32))
  (license-type uint)
  (attribution-required bool)
  (commercial-use bool)
  (modification-allowed bool)
  (expiry-blocks (optional uint)))
  (let (
    (institution tx-sender)
    (current-block stacks-block-height)
    (expiry-block (match expiry-blocks
      blocks (some (+ current-block blocks))
      none
    ))
  )
    (match (map-get? submissions { content-hash: content-hash })
      submission-data
      (if (is-eq (get institution submission-data) institution)
        (if (and (>= license-type LICENSE_PUBLIC) (<= license-type LICENSE_PRIVATE))
          (if (is-none (map-get? content-licenses { content-hash: content-hash }))
            (begin
              (map-set content-licenses
                { content-hash: content-hash }
                {
                  license-type: license-type,
                  attribution-required: attribution-required,
                  commercial-use: commercial-use,
                  modification-allowed: modification-allowed,
                  expiry-block: expiry-block,
                  licensing-institution: institution
                }
              )
              (ok true)
            )
            (err ERR_LICENSE_EXISTS)
          )
          (err ERR_INVALID_LICENSE)
        )
        (err ERR_UNAUTHORIZED)
      )
      (err ERR_NOT_FOUND)
    )
  )
)

(define-read-only (get-content-license (content-hash (buff 32)))
  (map-get? content-licenses { content-hash: content-hash })
)

(define-read-only (check-license-validity (content-hash (buff 32)))
  (match (map-get? content-licenses { content-hash: content-hash })
    license-data
    (match (get expiry-block license-data)
      expiry-block
      (ok { valid: (<= stacks-block-height expiry-block), license: (some license-data) })
      (ok { valid: true, license: (some license-data) })
    )
    (ok { valid: false, license: none })
  )
)


(define-map content-citations
  { citing-content: (buff 32), cited-content: (buff 32) }
  {
    citation-type: uint,
    citation-context: (string-ascii 100),
    timestamp: uint,
    citing-institution: principal
  }
)

(define-map citation-scores
  { content-hash: (buff 32) }
  {
    times-cited: uint,
    citation-quality-score: uint,
    last-citation-block: uint
  }
)

(define-map institution-citation-stats
  { institution: principal }
  {
    total-citations-made: uint,
    total-citations-received: uint,
    citation-reputation: uint
  }
)

(define-public (submit-with-citations 
  (content-hash (buff 32))
  (course-code (string-ascii 20))
  (student-id (string-ascii 50))
  (submission-type (string-ascii 20))
  (cited-content (list 5 (buff 32)))
  (citation-types (list 5 uint))
  (citation-contexts (list 5 (string-ascii 100))))
  (let (
    (institution tx-sender)
    (current-block stacks-block-height)
    (current-time (default-to u0 (get-stacks-block-info? time current-block)))
  )
    (let ((submission-count (var-get total-submissions)))
      (match (map-get? institutions { institution: institution })
        institution-data
        (if (get verified institution-data)
          (if (is-none (map-get? submissions { content-hash: content-hash }))
            (begin
              (map-set submissions
                { content-hash: content-hash }
                {
                  institution: institution,
                  course-code: course-code,
                  student-id: student-id,
                  submission-type: submission-type,
                  timestamp: current-time,
                  block-height: current-block,
                  verified: true
                }
              )
              (map-set institution-submissions
                { institution: institution, submission-index: (get total-submissions institution-data) }
                { content-hash: content-hash }
              )
              (map-set institutions
                { institution: institution }
                (merge institution-data { total-submissions: (+ (get total-submissions institution-data) u1) })
              )
              (var-set total-submissions (+ submission-count u1))
              (process-citations content-hash cited-content citation-types citation-contexts 
                                institution current-time)
              (update-citation-stats institution (len cited-content))
              (ok content-hash)
            )
            (err ERR_ALREADY_EXISTS)
          )
          (err ERR_INVALID_INSTITUTION)
        )
        (err ERR_NOT_FOUND)
      )
    )
  )
)

(define-private (process-citations 
  (citing-content (buff 32))
  (cited-list (list 5 (buff 32)))
  (type-list (list 5 uint))
  (context-list (list 5 (string-ascii 100)))
  (institution principal)
  (timestamp uint))
  (begin
    (process-citation-at-index citing-content cited-list type-list context-list institution timestamp u0)
    (process-citation-at-index citing-content cited-list type-list context-list institution timestamp u1)
    (process-citation-at-index citing-content cited-list type-list context-list institution timestamp u2)
    (process-citation-at-index citing-content cited-list type-list context-list institution timestamp u3)
    (process-citation-at-index citing-content cited-list type-list context-list institution timestamp u4)
    true
  )
)

(define-private (process-citation-at-index
  (citing-content (buff 32))
  (cited-list (list 5 (buff 32)))
  (type-list (list 5 uint))
  (context-list (list 5 (string-ascii 100)))
  (institution principal)
  (timestamp uint)
  (index uint))
  (let (
    (cited-content (default-to 0x (element-at cited-list index)))
    (citation-type (default-to u0 (element-at type-list index)))
    (citation-context (default-to "" (element-at context-list index)))
  )
    (if (> (len cited-content) u0)
      (begin
        (map-set content-citations
          { citing-content: citing-content, cited-content: cited-content }
          {
            citation-type: citation-type,
            citation-context: citation-context,
            timestamp: timestamp,
            citing-institution: institution
          }
        )
        (update-cited-content-score cited-content citation-type)
        true
      )
      false
    )
  )
)

(define-private (update-cited-content-score (content-hash (buff 32)) (citation-type uint))
  (let (
    (current-score (default-to 
      { times-cited: u0, citation-quality-score: u0, last-citation-block: u0 }
      (map-get? citation-scores { content-hash: content-hash })
    ))
    (quality-boost (if (is-eq citation-type CITATION_DIRECT) u3
                    (if (is-eq citation-type CITATION_INDIRECT) u2 u1)))
  )
    (map-set citation-scores
      { content-hash: content-hash }
      {
        times-cited: (+ (get times-cited current-score) u1),
        citation-quality-score: (+ (get citation-quality-score current-score) quality-boost),
        last-citation-block: stacks-block-height
      }
    )
  )
)

(define-private (update-citation-stats (institution principal) (citation-count uint))
  (let (
    (current-stats (default-to 
      { total-citations-made: u0, total-citations-received: u0, citation-reputation: u100 }
      (map-get? institution-citation-stats { institution: institution })
    ))
  )
    (map-set institution-citation-stats
      { institution: institution }
      (merge current-stats 
        { 
          total-citations-made: (+ (get total-citations-made current-stats) citation-count),
          citation-reputation: (+ (get citation-reputation current-stats) citation-count)
        }
      )
    )
  )
)

(define-read-only (get-content-citations (content-hash (buff 32)))
  (ok {
    citation-score: (map-get? citation-scores { content-hash: content-hash }),
    citing-this-content: (filter-citations-by-cited content-hash)
  })
)

(define-read-only (get-citation-relationship (citing-content (buff 32)) (cited-content (buff 32)))
  (map-get? content-citations { citing-content: citing-content, cited-content: cited-content })
)

(define-read-only (get-institution-citation-stats (institution principal))
  (map-get? institution-citation-stats { institution: institution })
)

(define-private (filter-citations-by-cited (cited-content (buff 32)))
  none
)