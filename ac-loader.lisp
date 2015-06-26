;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Author      : Frank Tamborello
;;; Copyright   : (c)2015 Frank Tamborello, All Rights Reserved
;;; Availability: public domain
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the Lisp Lesser General Public
;;; License: the GNU Lesser General Public License as published by the
;;; Free Software Foundation (either version 2.1 of the License, 
;;; or, at your option, any later version),
;;; and the Franz, Inc Lisp-specific preamble.
;;;
;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Lesser General Public License for more details.
;;;
;;; You should have received a copy of the Lisp Lesser General Public
;;; License along with this library; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;;; and see Franz, Inc.'s preamble to the GNU Lesser General Public License,
;;; http://opensource.franz.com/preamble.html.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 
;;; Filename    : ac-loader.lisp
;;; Revision    : 1
;;; 
;;; Description : Loads ACT-Concurrently along with ACT-R
;;; 
;;; Usage 	: Place in the ACT-R user-loads folder, along with the rest
;;;		of the ACT-Concurrently library.
;;; 
;;; Bugs        : None known
;;; 
;;; Todo        : 
;;; 
;;; ----- History -----
;;; 2015.06.15	fpt [r1]
;;;	: inception
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(load 
 (merge-pathnames 
   "act-concurrently/act-concurrently.lisp" 
   (make-pathname :name nil :type nil
                  :defaults #. (or *compile-file-truename*
                                   *load-truename*))))