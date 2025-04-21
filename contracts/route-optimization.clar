;; Route Optimization Contract
;; Manages efficient delivery sequencing

(define-data-var admin principal tx-sender)

;; Data structure for location coordinates
(define-map locations principal
  {
    latitude: int,  ;; Scaled by 1,000,000 for precision
    longitude: int  ;; Scaled by 1,000,000 for precision
  }
)

;; Data structure for routes
(define-map carrier-routes principal
  {
    package-sequence: (list 20 uint),  ;; List of package IDs in delivery order
    total-distance: uint,              ;; Estimated total distance in meters
    last-updated: uint                 ;; Block height when last updated
  }
)

;; Public function to register or update a location
(define-public (register-location (user principal) (latitude int) (longitude int))
  (begin
    (asserts! (or (is-eq tx-sender user) (is-eq tx-sender (var-get admin))) (err u1))
    (asserts! (and (>= latitude (* -90 1000000)) (<= latitude (* 90 1000000))) (err u2)) ;; Valid latitude
    (asserts! (and (>= longitude (* -180 1000000)) (<= longitude (* 180 1000000))) (err u3)) ;; Valid longitude

    (map-set locations user {
      latitude: latitude,
      longitude: longitude
    })
    (ok true)
  )
)

;; Helper function to get absolute value of an integer
(define-read-only (get-absolute (value int))
  (if (< value 0)
      (* value -1)
      value
  )
)

;; Helper function to calculate distance between two points (simplified)
(define-read-only (calculate-distance (lat1 int) (lon1 int) (lat2 int) (lon2 int))
  ;; This is a simplified distance calculation
  ;; In a real implementation, you would use the Haversine formula
  ;; For simplicity, we're using a basic approximation
  (let
    (
      (lat-diff (get-absolute (- lat1 lat2)))
      (lon-diff (get-absolute (- lon1 lon2)))
    )
    (+ lat-diff lon-diff) ;; Manhattan distance scaled by coordinate system
  )
)

;; Public function to optimize route for a carrier
(define-public (optimize-route (carrier principal) (package-ids (list 20 uint)))
  (begin
    (asserts! (is-eq tx-sender carrier) (err u4)) ;; Only carrier can optimize their route

    ;; In a real implementation, this would use a proper algorithm
    ;; For simplicity, we're just storing the provided sequence

    (map-set carrier-routes carrier {
      package-sequence: package-ids,
      total-distance: u0, ;; Would calculate actual distance in real implementation
      last-updated: block-height
    })
    (ok true)
  )
)

;; Public function to update a route with a new package
(define-public (add-package-to-route (carrier principal) (package-id uint))
  (begin
    (asserts! (is-eq tx-sender carrier) (err u4)) ;; Only carrier can update their route

    (match (map-get? carrier-routes carrier)
      route-data (let
        ((current-sequence (get package-sequence route-data))
         (new-sequence (unwrap! (as-max-len? (append current-sequence package-id) u20) (err u5))))

        (map-set carrier-routes carrier
          (merge route-data {
            package-sequence: new-sequence,
            last-updated: block-height
          }))
        (ok true)
      )
      ;; If no route exists, create a new one with just this package
      (begin
        (map-set carrier-routes carrier {
          package-sequence: (list package-id),
          total-distance: u0,
          last-updated: block-height
        })
        (ok true)
      )
    )
  )
)

;; Read-only function to get a carrier's optimized route
(define-read-only (get-carrier-route (carrier principal))
  (map-get? carrier-routes carrier)
)

;; Read-only function to get a location
(define-read-only (get-location (user principal))
  (map-get? locations user)
)

;; Function to transfer admin rights (only current admin)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
