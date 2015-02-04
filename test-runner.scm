#!/usr/bin/env petite --script
(load "compiler.scm")
(define os (if (equal? (system "uname") "Darwin") "OSX" "LINUX"))
(define summary (if (equal? os "OSX") display (lambda(msg) (display msg) (system (format "say \"~a\"" msg)))))
(define remove-ext
  (lambda(scm-filename)
    (list->string (reverse (cddddr (reverse (string->list scm-filename)))))))

(define ^formatter
  (lambda (path)
    (lambda (scm-filename)
      (format (string-append "tests/" path) (remove-ext scm-filename)))))

(define format-cisc-name (^formatter "results-cisc/~a.c"))
(define format-output-name (^formatter "outputs/~a"))
(define format-exec-name (^formatter "results/~a"))
(define format-input-name 
  (lambda(scm-filename)
    (format "tests/inputs/~a" scm-filename)))

(define file->sexpres
  (lambda(filename)
    (let ((input (open-input-file filename)))
      (letrec ((run
                 (lambda()
                   (let ((e (read input)))
                     (if (eof-object? e)
                       (begin (close-input-port input) '())
                       (cons e (run)))))))
        (run)))))

(define perform-compilation
  (lambda (scm-file)
    (let* ((cisc-name (format-cisc-name scm-file))
           (exec-name (format-exec-name scm-file)))
      (begin
        (compile-scheme-file (format-input-name scm-file) "out.c")
        (system "make > /dev/null 2>&1") ;Remove the > /dev/null ... part if you want to see make output
        ; Remove old files if they exists, or rename-file will fail
        (if (file-exists? cisc-name) (delete-file cisc-name))
        (if (file-exists? exec-name) (delete-file exec-name))

        ; Moving out.c to it's actual name
        (rename-file "out.c" cisc-name)
        ; Moving the executable created to its actual name
        (rename-file "out" exec-name)
        (delete-file "out.o") ;Cleanup, otherwise next iterations uses same object file!
        ))))

(define perform-test-comparison
  (lambda (scm-file stats)
    (let* ((exec-name   (format-exec-name scm-file))
           (output-file (string-append exec-name ".output"))
           (cmd (format "./~a > ~a" exec-name output-file))
           (test-result (format "Test ~2a) ~a : ~~a~%" (+ 1 (car stats)) scm-file)))
      (begin
        ; Run executable and redirect output to results directory
        (system cmd)
        ; Now read out expected output vs. our generated output and compare them
        (let ((expected (file->sexpres (format-output-name scm-file)))
              (got      (file->sexpres output-file)))
          (if (equal? expected got)
            (begin ; Do if TRUE
              (display (format test-result "PASSED"))
              (list (+ 1 (car stats)) (+ 1 (cadr stats)) (caddr stats)))
            (begin ; Do if FALSE
              (display (format test-result "FAILED"))
              (display (format "\t\tExpected: ~a~%\t\tGot: ~a~%" expected got))
              (list (+ 1 (car stats)) (cadr stats) (+ 1 (caddr stats)))
              )))
        ))))

(letrec ((args (cdr (command-line)))
         (input-files (directory-list "tests/inputs/"))
         (only-scm-files (lambda (filename) (string-ci=? (path-extension filename) "scm"))))
  (let ((scm-files (filter only-scm-files input-files)))
    (map perform-compilation scm-files)
    (let* ((results (fold-right perform-test-comparison `(0 0 0) scm-files))
           (total-tests  (car results))
           (passed      (cadr results))
           (failed      (caddr results)))
      (display (format "~30,,,'=@a~%" "="))
      (summary (format "All Test completed~%\t~a Passed~%\t~a Failed~%" passed failed))
      (display (format "~4f% Success rate (~a out of ~a)~%" (* 100 (/ passed total-tests)) passed total-tests)))))
