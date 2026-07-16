(define-module (substrate user-space root data textual-fastdatatable)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages time)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages python-build)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (python-textual-fastdatatable))

(define-public python-textual-fastdatatable
  (package
    (name "python-textual-fastdatatable")
    (version "0.14.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://files.pythonhosted.org/packages/source/t/textual-fastdatatable/textual_fastdatatable-" version ".tar.gz"))
       (sha256
        (base32 "00c94607qy3ij2j8bmi9zf6bsl591ll5l8kzzdffpiwnzc4f56fb"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (propagated-inputs (list python-numpy python-pandas python-pyarrow
                             python-textual python-tzdata))
    (native-inputs (list python-hatchling))
    (home-page "https://github.com/Maxteabag/textual-fastdatatable")
    (synopsis
     "A performance-focused reimplementation of Textual's DataTable widget")
    (description
     "This package provides a performance-focused reimplementation of Textual's
@code{DataTable} widget, with a pluggable data storage backend.")
    (license license:expat)))
