(require 'lispbuilder-sdl)

(defstruct ball x y r direction-x direction-y vel-x vel-y color)

(defvar *inertia* 0.0
  "Value to remove to the velocity of the balls at every frame")

(defun invert-direction-ball (ball &rest axis)
  "Invert the direction of a ball.

The list `AXIS' should be composed of the keywords :x or :y or both,
and the ball will have the direction of the velocity of those axis
inverted.

Returns `NIL'."
  (dolist (argument axis)
    (when (equal argument :x)
      (setf (ball-direction-x ball) (* -1 (ball-direction-x ball))))
    (when (equal argument :y)
      (setf (ball-direction-y ball) (* -1 (ball-direction-y ball))))))

(defun move-ball (ball)
  "Updates the value of a vel-x and vel-y of a ball, only taking in
consideration the global inertia, ie. it doesn't detect collisions."
  (if (> (ball-vel-x ball) 0)
    (setf (ball-vel-x ball) (- (ball-vel-x ball) *inertia*))
    (setf (ball-vel-x ball) 0))
  (if (> (ball-vel-y ball) 0)
    (setf (ball-vel-y ball) (- (ball-vel-y ball) *inertia*))
    (setf (ball-vel-y ball) 0))
  (incf (ball-x ball) (* (ball-vel-x ball) (ball-direction-x ball)))
  (incf (ball-y ball) (* (ball-vel-y ball) (ball-direction-y ball))))

(defun move-balls (list-balls)
  "Calls the function move-ball for a list of balls."
  (dolist (ball list-balls)
    (move-ball ball)))

(defun draw-ball (ball)
  "Draw a ball on the screen."
  (sdl:draw-filled-circle-* (round (ball-x ball)) (round (ball-y ball)) (ball-r ball)
    :color (ball-color ball)))

(defun draw-balls (list-balls)
  "Calls the function draw-ball for a list of balls."
  (dolist (ball list-balls)
    (draw-ball ball)))

(defun right-side (ball)
  "Returns the value of the right side of a ball.

It's the value of its rightmost pixel."
  (+ (ball-x ball) (ball-r ball)))

(defun left-side (ball)
  "Returns the value of the left side of a ball.

It's the value of its leftmost pixel."
  (- (ball-x ball) (ball-r ball)))

(defun bottom-side (ball)
  "Returns the value of the bottom side of a ball.

It's the value of its bottommost pixel." 
  (+ (ball-y ball) (ball-r ball)))

(defun top-side (ball)
  "Returns the value of the top side of a ball.

It's the value of its topmost pixel."
  (- (ball-y ball) (ball-r ball)))

(defun is-above-p (y-value-1 y-value-2)
  "Check if value y-value-1 is above (in terms of y coordinates on the screen) the y-value-2.

This is used because SDL uses the top-left corner as the
coordinates (0,0), so to check if something is above another thing, it
is necessary to use <= on the y coordinates."
  (<= y-value-1 y-value-2))

(defun is-below-p (y-value-1 y-value-2)
  "Check if value y-value-1 is below (in terms of y coordinates on the screen) the y-value-2.

This is used because SDL uses the top-left corner as the
coordinates (0,0), so to check if something is below another thing, it
is necessary to use >= on the y coordinates."
  (>= y-value-1 y-value-2))

(defun delta (x y)
  "Returns the distance between 2 points on a line."
  (abs (- x y)))

(defun verify-collision-between-2-balls (ball-1 ball-2)
  ;; Can't do anything until the balls overlap
  (when (overlap-balls ball-1 ball-2)
    (cond
      ;; First check for the situation similar to this one:
      ;;       +---+             
      ;;       |   |             
      ;;       | 1 |             
      ;;       |  ++--+          
      ;;       +--++  |          
      ;;          | 2 |
      ;;          |   |
      ;;          +---+
      ((and (is-above-p (top-side ball-2) (bottom-side ball-1))
         (<= (left-side ball-2) (right-side ball-1)))
        (cond
          ;; Check to see if the following situation happened:
          ;;    +---+   
          ;;    |   |   
          ;;    | 1 |   
          ;;    |+--++  
          ;;    ++--+|  
          ;;     | 2 |  
          ;;     |   |  
          ;;     +---+  
          ;;
          ;; In this case, we should only change the direction-y of the balls
          ((> (delta (right-side ball-1) (left-side ball-2))
             (delta (top-side ball-2) (bottom-side ball-1)))
            (invert-direction-ball ball-1 :y)
            (invert-direction-ball ball-2 :y))
          ;; Check to see if the following situation happened:
          ;; +---+   
          ;; |  ++--+
          ;; | 1||  |
          ;; |  ||2 |
          ;; +--++  |
          ;;    +---+
          ;;
          ;; In this case, we should only change the direction-x of the balls
          ((> (delta (top-side ball-2) (bottom-side ball-1))
             (delta (right-side ball-1) (left-side ball-2)))
            (invert-direction-ball ball-1 :x)
            (invert-direction-ball ball-2 :x))
          ;; Assume that the following situation happened:
          ;; +---+   
          ;; |   |   
          ;; | 1 |   
          ;; |  ++--+
          ;; +--++  |
          ;;    | 2 |
          ;;    |   |
          ;;    +---+      
          ;;
          ;; In this case, we change the values of direction-x and direction-y on both balls
          (t
            (invert-direction-ball ball-1 :x :y)
            (invert-direction-ball ball-2 :x :y))))

      ;; Check for the situation similar to this one:
      ;;    +---+
      ;;    |   |
      ;;    | 1 |  
      ;; +--++  |
      ;; |  ++--+
      ;; | 2 |   
      ;; |   |   
      ;; +---+   
      ((and (is-above-p (top-side ball-2) (bottom-side ball-1))
         (<= (left-side ball-1) (right-side ball-2)))
        (cond
          ;; Check to see if the following situation happened:
          ;;  +---+  
          ;;  |   |  
          ;;  | 1 |  
          ;; ++--+|  
          ;; |+--++  
          ;; | 2 |   
          ;; |   |   
          ;; +---+   
          ;; In this case, we should only change the direction-y of the balls
          ((> (delta (left-side ball-1) (right-side ball-2))
             (delta (top-side ball-2) (bottom-side ball-1)))
            (invert-direction-ball ball-1 :y)
            (invert-direction-ball ball-2 :y))
          ;; Check to see if the following situation happened:
          ;;    +---+
          ;; +--++  |
          ;; |  ||1 |
          ;; | 2||  |
          ;; |  ++--+
          ;; +---+   
          ;; In this case, we should only change the direction-x of the balls
          ((> (delta (top-side ball-2) (bottom-side ball-2))
             (delta (left-side ball-1) (right-side ball-2)))
            (invert-direction-ball ball-1 :x)
            (invert-direction-ball ball-2 :y))
          ;; Assume that the following situation happened:
          ;;    +---+
          ;;    |   |
          ;;    | 1 |
          ;; +--++  |
          ;; |  ++--+
          ;; | 2 |   
          ;; |   |   
          ;; +---+   
          ;; In this case, we change the values of direction-x and direction-y on both balls
          (t
            (invert-direction-ball ball-1 :x :y)
            (invert-direction-ball ball-2 :x :y))))

      ;; Check for the situation similar to this one:
      ;; +---+    
      ;; |   |    
      ;; | 2 |    
      ;; |  ++--+ 
      ;; +--++  | 
      ;;    | 1 | 
      ;;    |   | 
      ;;    +---+ 
      ((and (is-above-p (top-side ball-1) (bottom-side ball-2))
         (<= (left-side ball-1) (right-side ball-2)))
        (cond
          ;; Check to see if the following situation happened:
          ;; +---+  
          ;; |   |  
          ;; | 2 |  
          ;; |+--++ 
          ;; ++--+| 
          ;;  | 1 | 
          ;;  |   | 
          ;;  +---+ 
          ;; In this case, we should only change the direction-y of the balls
          ((> (delta (left-side ball-1) (right-side ball-2))
             (delta (top-side ball-1) (bottom-side ball-2)))
            (invert-direction-ball ball-1 :y)
            (invert-direction-ball ball-2 :y))
          ;; Check to see if the following situation happened:
          ;; +---+   
          ;; |  ++--+
          ;; | 2||  |
          ;; |  ||1 |
          ;; +--++  |
          ;;    +---+
          ;; In this case, we should only change the direction-x of the balls
          ((> (delta (top-side ball-1) (bottom-side ball-2))
             (delta (left-side ball-1) (right-side ball-2)))
            (invert-direction-ball ball-1 :x)
            (invert-direction-ball ball-2 :x))
          ;; Assume that the following situation happened:
          ;; +---+   
          ;; |   |   
          ;; | 2 |   
          ;; |  ++--+
          ;; +--++  |
          ;;    | 1 |
          ;;    |   |
          ;;    +---+
          ;; In this case, we change the values of direction-x and direction-y on both balls
          (t
            (invert-direction-ball ball-1 :x :y)
            (invert-direction-ball ball-2 :x :y))))

      ;; Check for the situation similar to this one:
      ;;    +---+ 
      ;;    |   | 
      ;;    | 2 | 
      ;; +--++  | 
      ;; |  ++--+ 
      ;; | 1 |    
      ;; |   |    
      ;; +---+    
      ((and (is-above-p (top-side ball-1) (bottom-side ball-2))
         (<= (left-side ball-2) (right-side ball-1)))
        (cond
          ;; Check to see if the following situation happened:
          ;;  +---+
          ;;  |   |
          ;;  | 2 |
          ;; ++--+|
          ;; |+--++
          ;; | 1 | 
          ;; |   | 
          ;; +---+ 
          ;; In this case, we should only change the direction-y of the balls
          ((> (delta (left-side ball-2) (right-side ball-1))
             (delta (top-side ball-1) (bottom-side ball-2)))
            (invert-direction-ball ball-1 :y)
            (invert-direction-ball ball-2 :y))
          ;; Check to see if the following situation happened:
          ;;    +---+
          ;; +--++  |
          ;; |  ||2 |
          ;; | 1||  |
          ;; |  ++--+
          ;; +---+   
          ;; In this case, we should only change the direction-x of the balls         
          ((> (delta (top-side ball-1) (bottom-side ball-2))
             (delta (left-side ball-2) (right-side ball-1)))
            (invert-direction-ball ball-1 :x)
            (invert-direction-ball ball-2 :x))
          ;; Assume that the following situation happened:
          ;;    +---+ 
          ;;    |   | 
          ;;    | 2 | 
          ;; +--++  | 
          ;; |  ++--+ 
          ;; | 1 |    
          ;; |   |    
          ;; +---+    
          ;; In this case, we change the values of direction-x and direction-y on both balls
          (t
            (invert-direction-ball ball-1 :x :y)
            (invert-direction-ball ball-2 :x :y)))))
    ;(exchange-energy-between-balls ball-1 ball-2)
    ))

(defun exchange-energy-between-balls (ball-1 ball-2)
  ;; The ball with more velocity decelerates, while the ball with less
  ;; velocity accelerates

  ;; Check to see if the balls are the same
  (unless (and (= (ball-x ball-1) (ball-x ball-2))
            (= (ball-y ball-1) (ball-y ball-2)))
    (let ((abs-vel-ball-1 (sqrt (+
                                  (* (ball-vel-x ball-1)
                                    (ball-vel-x ball-1))
                                  (* (ball-vel-y ball-1)
                                    (ball-vel-y ball-1)))))
           (abs-vel-ball-2 (sqrt (+
                                   (* (ball-vel-x ball-2)
                                     (ball-vel-x ball-2))
                                   (* (ball-vel-y ball-2)
                                     (ball-vel-y ball-2))))))
      (if (> abs-vel-ball-1 abs-vel-ball-2)
        (progn
          (setf (ball-vel-x ball-1) (- (ball-vel-x ball-1) 0.7))
          (setf (ball-vel-x ball-2) (+ (ball-vel-x ball-2) 0.5))
          (setf (ball-vel-y ball-1) (- (ball-vel-y ball-1) 0.7))
          (setf (ball-vel-y ball-2) (+ (ball-vel-y ball-2) 0.5)))
        (progn
          (setf (ball-vel-x ball-1) (- (ball-vel-x ball-1) 0.7))
          (setf (ball-vel-x ball-1) (+ (ball-vel-x ball-1) 0.5))
          (setf (ball-vel-y ball-1) (- (ball-vel-y ball-1) 0.7))
          (setf (ball-vel-y ball-1) (+ (ball-vel-y ball-1) 0.5)))))))

(defun degree-to-rad (degree)
  (* degree (/ pi 180)))

(defun amostrate (x y r steps)
  ;; FIXME. steps does nothing, this function always works as if steps
  ;; had the value 6
  (let ((deg (/ 180 steps))
         (return-list '()))
    (dolist (k '(0 1 2 3 4 5))
      (push (cons (round (+ x (* r (cos (* (degree-to-rad (/ deg steps)) k)))))
              (round (+ y (* r (sin (* (degree-to-rad (/ deg steps)) k))))))
        return-list)
      (push (cons (round (- x (* r (cos (* (degree-to-rad (/ deg steps)) k)))))
              (round (- y (* r (sin (* (degree-to-rad (/ deg steps)) k))))))
        return-list))
    return-list))    
      

(defun overlap-balls (ball-1 ball-2)
  "Indicates if ball-2 overlaps ball-1"
  (let* ((point-1 (list (right-side ball-2) (top-side ball-2)))
          (point-2 (list (right-side ball-2) (bottom-side ball-2)))
          (point-3 (list (left-side ball-2) (bottom-side ball-2)))
          (point-4 (list (left-side ball-2) (top-side ball-2)))
          (points (list point-1 point-2 point-3 point-4)))
    (remove-if #'null
      (mapcar #'(lambda (point)
                  (let ((point-x (car point))
                         (point-y (cadr point)))
                    (and
                      ;; Check the values in X
                      (and (<= (left-side ball-1) point-x)
                        (<= point-x (right-side ball-1)))
                      ;; Check the values in Y
                      (and (<= (top-side ball-1) point-y)
                        (<= point-y (bottom-side ball-1))))))
        points))))

(defun create-ball-stand-still (x y r)
  "Creates a ball with color `COLOR' on coordinates (X Y), but with velocity 0."
  (make-ball :x x :y y :r r
    :direction-x 1 :direction-y 1
    :vel-x 0 :vel-y 0
    :color sdl:*green*))

(defun create-column-balls (column-number mid-x mid-y radius &key (separation 2))
  "Creates a vertical column of balls."
  (let (;; The number of balls on this column
         (number-of-balls (+ column-number 3))
         (value-x-of-column
           ;; The columns whose number is positive are the ones further
           ;; away from the white ball
           (if (> column-number 0)
             (- mid-x (+ (* 2 (abs column-number) radius) separation))
             (+ mid-x (+ (* 2 (abs column-number) radius) separation))))
         (column-number (abs column-number))
         (return-list '()))
    (if (zerop (mod column-number 2))
      ;; This is the algorithm for placing balls on a even column
      ;; (for example, the one that contains the middle-ball)
      (progn
        ;; If the number-of-balls to draw is 1, then only draw the middle ball
        ;; (this should only happend to the column closest to the white ball)
        (unless (= number-of-balls 1)
          ;; k indicates the distance between a ball and the column's middle ball
          (loop for k from 1 below number-of-balls by 2 do
            (let ((delta-y-of-ball (+
                                     (* 2 (ceiling (/ k 2)) radius)
                                     separation)))
              (push
                (create-ball-stand-still value-x-of-column (- mid-y delta-y-of-ball) radius)
                return-list)
              (push
                (create-ball-stand-still value-x-of-column (+ mid-y delta-y-of-ball) radius)
                return-list))))
        ;; Create the column's middle ball
        (push (create-ball-stand-still value-x-of-column (+ mid-y separation) radius)
          return-list))
      ;; This is the algorithm for placing balls on a odd column
      ;; k indicates the distance between a ball and the middle ball on an odd column
      (loop for k from 1 below number-of-balls by 2 do
        (let ((delta-y-of-ball (+ (* k radius) separation)))
          (push
            (create-ball-stand-still value-x-of-column (- mid-y delta-y-of-ball) radius)
            return-list)
          (push
            (create-ball-stand-still value-x-of-column (+ mid-y delta-y-of-ball) radius)
            return-list))))
    return-list))
          
                             
(defun create-initial-balls (mid-x mid-y radius)
  "Returns a list of balls, on the position they should occupy in the beginning of the game"
  (let* (
          ;; The order in which the balls are created
          ;;
          ;;        ---                 
          ;;       /   \                
          ;;       | 13|---             
          ;;       \   /   \            
          ;;        ---| 9 |---         
          ;;       /   \   /   \        
          ;;       | 11|---| 4 |---     
          ;;       \   /   \   /   \    
          ;;        ---| 7 |---| 2 |--- 
          ;;       /   \   /   \   /   \
          ;;       | 15|---| M |---| 1 |
          ;;       \   /   \   /   \   /
          ;;        ---| 8 |---| 3 |--- 
          ;;       /   \   /   \   /    
          ;;       | 12|---| 5 |---  ^   
          ;;       \   /   \   /     |     
          ;;        ---| 10|---  ^    \__ Column -2 
          ;;       /   \   /     |     
          ;;       | 14|---  ^    \______ Column -1     
          ;;       \   /     |          
          ;;        ---  ^    \__________ Column 0
          ;;             |
          ;;         ^    \______________ Column 1
          ;;         |
          ;;          \__________________ Column 2
          ;;
          ;; To add more balls just keep increasing the number of columns
          ;;
          ;; The M ball represents the middle-ball
          ;; The middle-ball is the black ball on the oficial game
          (column-1 (create-column-balls -2 mid-x mid-y radius))
          (column-2 (create-column-balls -1 mid-x mid-y radius))
          ;; Column where the middle-ball will be created
          (column-3 (create-column-balls 0 mid-x mid-y radius))
          (column-4 (create-column-balls 1 mid-x mid-y radius))
          (column-5 (create-column-balls 2 mid-x mid-y radius)))
    (append column-1 column-2 column-3 column-4 column-5)))


(defun draw-hole (hole)
  "Draw a hole on the screen."
  (sdl:draw-filled-circle-* (round (ball-x hole)) (round (ball-y hole)) (ball-r hole)
    :color sdl:*black* :stroke-color sdl:*green*))

(defun draw-holes (list-holes)
  "Calls the function draw-hole on a list of holes."
  (dolist (ball list-holes)
    (draw-hole ball)))

(defun create-holes (x y width height)
  "Create 6 holes on the screen."
  ;; FIXME: For now holes are just balls that don't move
  (let ((radius 20))
    (list ;; Holes on the corners of the table
      (create-ball-stand-still x y radius)
      (create-ball-stand-still (+ x width) y radius)
      (create-ball-stand-still (+ x width) (+ y height) radius)
      (create-ball-stand-still x (+ y height) radius)
      ;; Holes on the middle of the table
      (create-ball-stand-still (+ x (/ width 2)) y radius)
      (create-ball-stand-still (+ x (/ width 2)) (+ y height) radius))))


(defun draw-table (x y width height)
  "Draw the table of the game."
  ;; The inside
  (sdl:draw-rectangle-* x y width height)
  ;; The outside
  (sdl:draw-rectangle-* (- x 30) (- y 30) (+ width 60) (+ height 60)))


(defun billard ()
  (let* ((bola1 (make-ball :x (+ 100 (random 400)) :y (+ 100 (random 400)) :r 10
                  :direction-x -1 :direction-y 1
                  :vel-x (1+ (random 15)) :vel-y (1+ (random 15))
                  :color sdl:*yellow*))
          (bola2 (make-ball :x (+ 100 (random 400)) :y (+ 100 (random 400)) :r 10
                   :direction-x 1 :direction-y -1
                   :vel-x (1+ (random 15)) :vel-y (1+ (random 15))
                   :color sdl:*cyan*))
          (bolas (list bola1 bola2))
          
          ;;(bolas (create-initial-balls 200 300 10))

          ;; Table configurations
          (table-x 100)
          (table-y 100)
          (table-width 600)
          (table-height 400)
          ;; FIXME: For now holes are just balls that are stopped
          (holes (create-holes table-x table-y table-width table-height))
          (window-width 800)
          (window-height 600))
    (push (make-ball :x 600 :y 300 :r 10
            :direction-x 1 :direction-y 1
            :vel-x 15 :vel-y 0
            :color sdl:*white*)
      bolas)
    (sdl:with-init ()
      (sdl:window window-width window-height :position t
        :title-caption "Billard")
      (draw-balls bolas)
      (draw-holes holes)
      (sdl:with-events ()
        (:quit-event () t)
        (:key-down-event ()
          (when (sdl:key-down-p :sdl-key-escape)
            (sdl:push-quit-event)))
        (:idle ()
          (sdl:clear-display sdl:*black*)
          ;; TODO: This should probably be a macro, but it also works like this
          (mapcar #'(lambda (ball)
                      (when (or (>= (bottom-side ball) (+ table-y table-height))
                              (<= (top-side ball) table-y))
                        (invert-direction-ball ball :y))
                      (when (or (>= (right-side ball) (+ table-x table-width))
                              (<= (left-side ball) table-x))
                        (invert-direction-ball ball :x)))
            bolas)

          ;; Verify collision between balls
          (dolist (ball-1 bolas)
            (mapcar #'(lambda (ball-2)
                        (verify-collision-between-2-balls ball-1 ball-2))
              bolas))
                    
          ;; Verify collision between balls and holes
          ;; Remove balls that collide with holes
          (setf bolas (remove-if #'null
                        (mapcar #'(lambda (ball)
                                    ;; Verify if this ball is
                                    ;; overlapping any of the
                                    ;; existing holes
                                    (unless (remove-if #'null
                                              (mapcar #'(lambda (hole)
                                                          (when (overlap-balls hole ball)
                                                            hole))
                                                holes))
                                      ball))
                          bolas)))
          (move-balls bolas)
          (draw-table table-x table-y table-width table-height)
          (draw-balls bolas)
          (draw-holes holes)
          (sdl:update-display))))))
         
