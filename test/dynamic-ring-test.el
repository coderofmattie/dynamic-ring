
;; Add source paths to load path so the tests can find the source files
;; Adapted from:
;; https://github.com/Lindydancer/cmake-font-lock/blob/47687b6ccd0e244691fb5907aaba609e5a42d787/test/cmake-font-lock-test-setup.el#L20-L27
(defvar dynamic-ring-test-setup-directory
  (if load-file-name
      (file-name-directory load-file-name)
    default-directory))

(dolist (dir '("." ".."))
  (add-to-list 'load-path
               (concat dynamic-ring-test-setup-directory dir)))

;;

(require 'dynamic-ring)
(require 'cl)

(ert-deftest dyn-ring-test ()
  ;; null constructor
  (should (make-dyn-ring))

  ;; dyn-ring-empty-p
  (should (dyn-ring-empty-p (make-dyn-ring)))
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (should-not (dyn-ring-empty-p ring)))

  ;; dyn-ring-size
  (should (= 0 (dyn-ring-size (make-dyn-ring))))
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (should (= 1 (dyn-ring-size ring))))

  ;; dyn-ring-head
  (should (null (dyn-ring-head (make-dyn-ring))))
  (let* ((ring (make-dyn-ring))
         (elem (dyn-ring-insert ring 1)))
    (should (equal elem (dyn-ring-head ring))))

  ;; dyn-ring-value
  (should (null (dyn-ring-value (make-dyn-ring))))
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (should (= 1 (dyn-ring-value ring)))))

(ert-deftest dyn-ring-element-test ()
  ;; constructor
  (should (dyn-ring-make-element 1))

  ;; dyn-ring-element-value
  (should (= 1
             (dyn-ring-element-value
              (dyn-ring-make-element 1))))

  ;; dyn-ring-set-element-value
  (let ((elem (dyn-ring-make-element 1)))
    (dyn-ring-set-element-value elem 2)
    (should (= 2
               (dyn-ring-element-value elem))))

  ;; dyn-ring-element-previous and dyn-ring-element-next
  (let* ((ring (make-dyn-ring))
         (elem (dyn-ring-insert ring 1)))
    (should (null (dyn-ring-element-previous elem)))
    (should (null (dyn-ring-element-next elem))))
  (let* ((ring (make-dyn-ring))
         (elem (dyn-ring-insert ring 1))
         (elem2 (dyn-ring-insert ring 2)))
    (should (equal elem2 (dyn-ring-element-previous elem)))
    (should (equal elem2 (dyn-ring-element-next elem)))
    (should (equal elem (dyn-ring-element-previous elem2)))
    (should (equal elem (dyn-ring-element-next elem2)))))

(ert-deftest dyn-ring-traverse-test ()
  ;; empty ring
  (let ((ring (make-dyn-ring))
        (memo (list)))
    (letf ((memofn (lambda (arg)
                     (push arg memo))))
      (should-not (dyn-ring-traverse ring memofn))
      (should (null memo))))

  ;; one-element ring
  (let* ((ring (make-dyn-ring))
         (memo (list)))
    (letf ((memofn (lambda (arg)
                     (push arg memo))))
      (dyn-ring-insert ring 1)
      (should (dyn-ring-traverse ring memofn))
      (should (equal memo (list 1)))))

  ;; two-element ring
  (let* ((ring (make-dyn-ring))
         (memo (list)))
    (letf ((memofn (lambda (arg)
                     (push arg memo))))
      (dyn-ring-insert ring 1)
      (dyn-ring-insert ring 2)
      (should (dyn-ring-traverse ring memofn))
      (should (equal memo (list 1 2)))))

  ;; 3-element ring
  (let* ((ring (make-dyn-ring))
         (memo (list)))
    (letf ((memofn (lambda (arg)
                     (push arg memo))))
      (dyn-ring-insert ring 1)
      (dyn-ring-insert ring 2)
      (dyn-ring-insert ring 3)
      (should (dyn-ring-traverse ring memofn))
      (should (equal memo (list 1 2 3))))))

(ert-deftest dyn-ring-traverse-collect-test ()
  ;; empty ring
  (let ((ring (make-dyn-ring)))
    (let ((result (dyn-ring-traverse-collect ring #'1+)))
      (should (null result))))

  ;; one-element ring
  (let ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (let ((result (dyn-ring-traverse-collect ring #'1+)))
      (should (equal result (list 2)))))

  ;; two-element ring
  (let* ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (dyn-ring-insert ring 2)
    (let ((result (dyn-ring-traverse-collect ring #'1+)))
      (should (equal result (list 2 3)))))

  ;; 3-element ring
  (let* ((ring (make-dyn-ring)))
    (dyn-ring-insert ring 1)
    (dyn-ring-insert ring 2)
    (dyn-ring-insert ring 3)
    (let ((result (dyn-ring-traverse-collect ring #'1+)))
      (should (equal result (list 2 3 4))))))

(ert-deftest dyn-ring-insert-test ()
  ;; empty ring
  (let ((ring (make-dyn-ring)))
    (should (dyn-ring-insert ring 1))
    (should (= 1 (dyn-ring-value ring)))
    (should (null (dyn-ring-element-previous (dyn-ring-head ring))))
    (should (null (dyn-ring-element-next (dyn-ring-head ring)))))

  ;; one-element ring
  (let* ((ring (make-dyn-ring))
         (elem1 (dyn-ring-insert ring 1)))
    (let ((new (dyn-ring-insert ring 2)))
      (should new)
      (should (= 2 (dyn-ring-value ring)))
      (should (eq (dyn-ring-element-previous new)
                  elem1))
      (should (eq (dyn-ring-element-next new)
                  elem1))
      (should (eq (dyn-ring-element-previous elem1)
                  new))
      (should (eq (dyn-ring-element-next elem1)
                  new))))

  ;; two-element ring
  (let* ((ring (make-dyn-ring))
         (elem1 (dyn-ring-insert ring 1))
         (elem2 (dyn-ring-insert ring 2)))
    (let ((new (dyn-ring-insert ring 3)))
      (should new)
      (should (= 3 (dyn-ring-value ring)))
      (should (eq (dyn-ring-element-previous new)
                  elem1))
      (should (eq (dyn-ring-element-next new)
                  elem2))
      (should (eq (dyn-ring-element-previous elem1)
                  elem2))
      (should (eq (dyn-ring-element-next elem1)
                  new))
      (should (eq (dyn-ring-element-previous elem2)
                  new))
      (should (eq (dyn-ring-element-next elem2)
                  elem1)))))

