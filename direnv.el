(require 'json)
(require 'subr-x)

(defvar direnv-cache (make-hash-table :test 'equal))

(defun direnv-clear-cache ()
  (interactive)
  (setq direnv-cache (make-hash-table :test 'equal)))

(defun direnv-find-cached (file)
  (some (lambda (p)
          (when (string-prefix-p p file)
            (gethash p direnv-cache)))
        (hash-table-keys direnv-cache)))

(defun direnv-read-json (&optional ignore-cache)
  (or
   (when (not ignore-cache)
     (or (direnv-find-cached default-directory)
         (direnv-find-cached (buffer-file-name))))
   (let ((direnv-log (get-buffer-create " direnv-log"))
         (json (with-temp-buffer
                 (call-process "direnv" nil (list (current-buffer) nil) nil
                               "export" "json")
                 (when (not (= (point-min) (point-max)))
                   (beginning-of-buffer)
                   (json-read)))))
     (let ((direnv-dir (cdr (assoc 'DIRENV_DIR json))))
       (when direnv-dir
         (puthash (expand-file-name (if (string-prefix-p "-" direnv-dir)
                                        (substring direnv-dir 1)
                                      direnv-dir))
                  json direnv-cache)))
     json)))

(defun direnv-environment (json)
  (mapcar (lambda (el)
            (format "%s=%s" (car el) (cdr el)))
          json))

(defun direnv-path (json)
  (let ((path (cdr (assoc 'PATH json))))
    (when path
      (split-string path ":"))))

(defun direnv-apply (&optional ignore-cache)
  (interactive "p")
  (let ((ignore-cache (when ignore-cache (> ignore-cache 1))))
    (if ignore-cache
        (message "Loading environment (ignoring cache)...")
      (message "Loading environment..."))
    (let* ((json (direnv-read-json ignore-cache))
           (ep (append (direnv-path json)
                       (default-value 'exec-path)))
           (pe (append (direnv-environment json)
                       (default-value 'process-environment))))
      (setq-local exec-path ep)
      (setq-local process-environment pe)
      (message "Applied environment: %s"
               (mapconcat (lambda (v) (format "%s" (car v))) json " ")))))

;;; Used to advice `start-process' and inject the environment and
;;; `exec-path'
(defun direnv-start-process-advice (orig-fun &rest args)
  (let* ((json (direnv-read-json))
         (ep (append (direnv-path json)
                     (default-value 'exec-path)))
         (pe (append (direnv-environment json)
                     (default-value 'process-environment))))
    ;; set the variables locally to hit the direnv cache
    (setq-local exec-path ep)
    (setq-local process-environment pe)
    (apply orig-fun args)))

(advice-add 'start-process :around #'direnv-start-process-advice)

(provide 'direnv)
