;;; ACT-Concurrently Loader

(load 
 (merge-pathnames 
   "act-concurrently/act-concurrently.lisp" 
   (make-pathname :name nil :type nil
                  :defaults #. (or *compile-file-truename*
                                   *load-truename*))))