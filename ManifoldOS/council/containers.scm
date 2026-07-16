* Containers — WIP

** Status
Container system is active but loader pattern is not yet implemented.
Do NOT restructure existing container files until instructed.

** Current structure

#+BEGIN_SRC
Operating-System/systems/containers/
├── containers.scm          (systems containers containers)         exports: all-container-services
├── core-container.scm      (systems containers core-container)     exports: container-os, container-service
├── devsecops.scm           (systems containers devsecops)          exports: devsecops-os, devsecops-service
└── devsecops/
    └── packages.scm        (systems containers devsecops packages) exports: devsecops-packages
#+END_SRC

** Current pattern — flat, direct imports

#+BEGIN_SRC scheme
(define-module (systems containers containers)
  #:use-module (systems containers core-container)
  #:use-module (systems containers devsecops)
  #:re-export (container-service devsecops-service)
  #:export (all-container-services))
#+END_SRC

** Planned structure — loader pattern (not yet active)

#+BEGIN_SRC
Operating-System/systems/containers/
├── containers.scm
├── core-container.scm
├── loaders/                  <- TO BE CREATED
│   ├── devsecops.scm
│   └── <future>.scm
├── devsecops/
│   ├── devsecops.scm
│   └── packages.scm
└── <future>/
#+END_SRC

** Planned loader pattern

#+BEGIN_SRC scheme
;; systems/containers/loaders/devsecops.scm
(define-module (systems containers loaders devsecops)
  #:use-module (systems containers devsecops)
  #:re-export (devsecops-os devsecops-service)
  #:export (container-devsecops-services))

(define-public container-devsecops-services
  (list devsecops-service))
#+END_SRC

** REPL workflow for containers

#+BEGIN_SRC scheme
;; launch: guix repl -- -L /home/aoeu/.config/guix/Operating-System

(use-modules (systems containers core-container))
container-os

(use-modules (systems containers devsecops))
devsecops-os
devsecops-service

(use-modules (systems containers containers))
all-container-services
#+END_SRC

** Adding a new container (current flat pattern)

Use Template E from module-templates.org.
1. Create systems/containers/<name>.scm
2. Validate in REPL
3. Import in containers.scm, add to all-container-services
4. Validate containers.scm in REPL
