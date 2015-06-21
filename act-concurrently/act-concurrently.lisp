;;; ACT-Concurrently
;;; Revision: 18
;;; Usage: Load with ACT-R by placing into the user-loads folder
;;;
;;; To Do:
;;; 1. Instruct users to name their model file "model.lisp" and to place it into the
;;; task-manager directory inside of ACT-R's user-loads directory. Use merge-pathnames 
;;; to load the model-file into *model*.
;;;
;;;
;;; 2. Add some informative status messages to the worker and manager, like "Ready to work
;;; & listening for jobs" or "Sending job to worker ~a" or "Receiving data from worker 
;;; ~a."
;;;
;;;
;;; N. How can I know when all the workers have finished? 
;;; Each manager thread listens to its socket. When a worker returns, the manager thread
;;; calls a finish function, which marks it as finished. When all task manager threads are
;;; marked finished, signal the human (or whatever).
;;;
;;;
;;; N+1. Consider switching to some kind of thread-pool design a la Dean & Ghemawat (2008)'s 
;;; mapreduce to achieve resilience for issues like varying processor speeds and hiccups.
;;; That could also make it easier to signal worker completion.
;;;
;;; 
;;;
;;; Bugs: None known
;;;
;;;
;;; Revision History
;;; 2015.04.04 1
;;; 1. Inception. 
;;;
;;; 2015.04.19 2
;;; 1. Use thread-pool & mailbox
;;;
;;; 2015.04.19 3
;;; 1. Use mailboxes to store data
;;;
;;; 2015.04.20 4
;;; 1. Redefined stop-pool to destroy the threads so they don't just multiply
;;; as a program starts and stops, since kiuma's thread-pool package just lets
;;; them pile up. Just call start-pool to have a pool of threads ready to go again.
;;;
;;; 2015.04.20 5
;;; 1. Pooled threads now call a worker in another Lisp image listening for a job.
;;; The job result is then sent back to the task manager's mailbox.
;;;
;;; 2015.04.21 6
;;; 1. Actually simultaneously runs two instances of an ACT-R model (UNRAVEL)
;;; and returns its data to the mailbox.
;;;
;;; 2015.04.23 7
;;; 1. Print prettily when all workers are done
;;;
;;; 2015.04.23 8
;;; 1. Send-job-to-worker now accepts a string to parameter addr to 
;;; to pass to usocket:with-client-socket.
;;;
;;; 2015.04.24 9
;;; Ditched thread-pool since I couldn't seem to get it to start thread
;;; execution simultaneously. Working directly with bordeaux-threads,
;;; which loads for usocket anyway, seems to work well.
;;;
;;; 2015.05.19 10
;;; Cleaned up a bit.
;;;
;;; 2015.05.20 11
;;; Read in a file, transmit it to the workers, workers each evaluate  
;;; the message.
;;; Note: Does not play well with model code containing reader macros,
;;; such as to construct a circular list.
;;;
;;; 2015.06.01 12
;;; Made friendlier for command-line loading.
;;;
;;; 2015.06.02 13
;;; I suspect I had a bug in worker-listen-for-job such that its call
;;; to usocket:socket-listen hard-wired the host parameter to only
;;; listen for connection requests emanating from the 127.0.0.1, the
;;; localhost. So now what do I give it for host, its externally-facing
;;; IP address? Yes!
;;;
;;; 2015.06.11 14
;;; Bundled mailbox & usocket
;;;
;;; 2015.06.15 15
;;; Bug: Bundling works great when I tell Lisp to execute it, but 
;;; ACT-R's apparently telling Lisp to compile it, and for some reason
;;; when it does that ASDF cannot find the systems, either when I have 
;;; the bundle in its own sub-directory and have code to load bundle.lisp
;;; or I put the bundle directly into user-loads and let ACT-R find 
;;; bundle.lisp itself. 
;;; Solution: Let ACT-R compile tm-loader.lisp, which loads task-manager.lisp,
;;; which in turn loads bundle.lisp and load-systems usocket & mailbox.
;;;
;;; 2015.06.16 16
;;; 1. Parameterized for the manager each worker's addr & port. Splice 
;;; those into a function defined to start the workers.
;;;
;;; 2. Parameterized for the workers their own addr & port.
;;;
;;; 2015.06.16 17
;;; Renamed "ACT-Concurrently"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Load system libraries-DO NOT CHANGE THIS!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(load 
 (merge-pathnames 
   "ac-bundle/bundle.lisp" 
   (make-pathname :name nil :type nil
                  :defaults #. (or *compile-file-truename*
                                   *load-truename*))))
(asdf:load-system :usocket)
(asdf:load-system :mailbox) 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Worker
;;; If this is a worker node, 
;;; then place the worker's address and port here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Worker's address replaces nil, format it as a string, like "127.0.0.1"
(defvar *worker-address* nil)

;; Worker's port replaces nil, format it as an integer, like 4321
(defvar *worker-port* nil) 


;; Do not edit this
(defun worker-listen-for-job ()
  (let ((connections (list 
                      (usocket:socket-listen 
                       *worker-address* 
                       *worker-port* 
                       :reuse-address t))))
    (unwind-protect
	 (loop 
           (loop for ready in 
             (usocket:wait-for-input connections :ready-only t)
		  do (if (typep ready 'usocket:stream-server-usocket)
			 (push (usocket:socket-accept ready) connections)
			 (let* ((stream (usocket:socket-stream ready))
				(msg (read stream)))
                           (when msg
                             (write 
                              (let (ret-val)
                                (dolist (item msg ret-val)
                                  (setf ret-val (eval item))))
                              :stream stream
                              :readably t))
			   (usocket:socket-close ready)
			   (setf connections (remove ready connections))))))
      (loop for c in connections do (loop while (usocket:socket-close c))))))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Manager
;;; If this is the manager,
;;; then place here the model's run call as well as  
;;; the workers' addresses and ports.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar *mailbox* (mailbox:make-mailbox))
(defvar *model-file-path* nil)
(setf *model-file-path* nil)
;; (setf *model-file-path* "/Users/frank/Documents/Lisp/Concurrency/test-program.lisp")
;; (setf *model-file-path* "/Users/frank/Documents/NRL/Error/UNRAVEL/UNRAVEL.lisp")
(defvar *model* nil)
(setf *model* nil)


;; Whatever function and arguments you call to run your model,
;; place it here, inside its own list, led by a single quote, like '((run-model :n 3))
(defvar *model-run-call* '((run-model :n 3)))


;; Worker addresses and ports
;; Format them as a quoted list of "dotted pair" lists,
;; like '(("127.0.0.1" . 4321) ("192.168.2.8" . 4321))
;; where each dotted pair is the address and port of one worker.
(defvar *worker-addresses-and-ports* 
  '(("127.0.0.1" . 4321)
    ("127.0.0.1" . 4322)))


;; PG's aif from "On Lisp"
(unless (fboundp 'aif)
  (defmacro aif (test-form then-form &optional else-form)
    `(let ((it ,test-form))
       (if it ,then-form ,else-form))))

(defun read-in-the-model-file ()
  (with-open-file (the-file *model-file-path* :direction :input)
    (do (model eof)
        ((not (null eof))
         (setf *model* (reverse model)))
      (aif (read the-file nil nil)
           (push it model)
           (setf eof t)))))

;; (read-in-the-model-file)

(defun send-job-to-worker (message addr port)
  (usocket:with-client-socket (sock str addr port)
    (write message :stream str :readably t)
    (force-output str)
;; wait indefinitely for the worker to return
    (when (usocket:wait-for-input sock) 
      (mailbox:post-mail (read str) *mailbox*))))


(defun send-out-jobs ()
  (let ((w-threads))
    (dolist (w *worker-addresses-and-ports* w-threads)
      (push
       (bt:make-thread
        (lambda ()
          (send-job-to-worker
           (append *model* `(,*model-run-call*))
           (car w)
           (cdr w))))
       w-threads))))






;; read the mail 
(defvar *data* nil)
(setf *data* nil)
(defun read-mail-data ()
  (do ((output (mailbox:read-mail *mailbox*) (mailbox:read-mail *mailbox*)))
      ((null output)
       (format t "end of mailbox~%"))
    (push output *data*)))

