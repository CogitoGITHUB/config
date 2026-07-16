(define-module (substrate kernel-space linux)
  #:use-module (srfi srfi-1)
  #:use-module (gnu system linux-initrd)
  #:use-module (gnu packages base)
  #:use-module (guix modules)
  #:use-module (gnu packages parallel)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu services)
  #:use-module (gnu services linux)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils))

;;; ============================================================================
;;; Helper Functions and Utilities
;;; ============================================================================

(define* (nonfree uri #:optional (comment ""))
  ((@@ (guix licenses) license) "nonfree" uri comment))

(define (linux-url version)
  (string-append "mirror://kernel.org"
                 "/linux/kernel/v" (version-major version) ".x"
                 "/linux-" version ".tar.xz"))

(define (nonguix-extra-linux-options linux-or-version)
  (define linux-version
    (if (package? linux-or-version)
        (package-version linux-or-version)
        linux-or-version))
  (reverse (fold (lambda (opt opts)
                   (if (version>=? linux-version (car opt))
                       (cons* (cdr opt) opts)
                       opts))
                 '()
                 '(("3.10" . "CONFIG_MT76x2U=m")
                   ("3.10" . "CONFIG_DRM_AMDGPU_CIK=y")
                   ("3.10" . "CONFIG_DRM_AMDGPU_SI=y")
                   ("5.15" . "CONFIG_MT7921E=m")
                   ("6.12" . "CONFIG_SND_SOC_INTEL_USER_FRIENDLY_LONG_NAMES=y")
                   ("6.12" . "CONFIG_SND_SOC_INTEL_SOUNDWIRE_SOF_MACH=m")))))

(define* (corrupt-linux freedo
                        #:key
                        (name "linux")
                        (configs "")
                        (defconfig "nonguix_defconfig")
                        (get-extra-configs nonguix-extra-linux-options)
                        modconfig)
  (define gexp-inputs (@@ (guix gexp) gexp-inputs))
  (define linux-srcarch (@@ (gnu packages linux) linux-srcarch))
  (define extract-gexp-inputs (compose gexp-inputs force origin-uri))

  (define (find-source-hash sources url)
    (let ((versioned-origin
           (find (lambda (source)
                   (let ((uri (origin-uri source)))
                     (and (string? uri) (string=? uri url)))) sources)))
      (if versioned-origin
          (origin-hash versioned-origin)
          #f)))

  (let* ((version (package-version freedo))
         (url (linux-url version))
         (pristine-source (package-source freedo))
         (inputs (map gexp-input-thing (extract-gexp-inputs pristine-source)))
         (sources (filter origin? inputs))
         (hash (find-source-hash sources url)))
    (package
      (inherit
       (customize-linux
        #:name name
        #:linux
        (package
          (inherit freedo)
          (version version)
          (arguments
           (substitute-keyword-arguments (package-arguments freedo)
             ((#:phases phases '%standard-phases)
              #~(modify-phases #$phases
                  (add-before 'configure 'nonguix-configure
                    (lambda args
                      (let ((defconfig
                             (format #f "arch/~a/configs/nonguix_defconfig"
                                     #$(linux-srcarch))))
                        (apply (assoc-ref #$phases 'configure) args)
                        (modify-defconfig
                         ".config" '#$(get-extra-configs this-package))
                        (invoke "make" "savedefconfig")
                        (rename-file "defconfig" defconfig)))))))))
        #:source (origin
                   (method url-fetch)
                   (uri url)
                   (hash hash))
        #:configs configs
        #:defconfig defconfig
        #:modconfig modconfig))
      (home-page "https://www.kernel.org/")
      (synopsis "Linux kernel with nonfree binary blobs included")
      (description
       "The unmodified Linux kernel, including nonfree blobs, for running Guix
System on hardware which requires nonfree software to function."))))

;;; ============================================================================
;;; Linux Kernel Definitions
;;; Version aliases are private — only linux and linux-lts are exported.
;;; ============================================================================

(define linux-6.19 (corrupt-linux linux-libre-6.19))
(define linux-6.18 (corrupt-linux linux-libre-6.18))
(define linux-6.12 (corrupt-linux linux-libre-6.12))
(define linux-6.6  (corrupt-linux linux-libre-6.6))
(define linux-6.1  (corrupt-linux linux-libre-6.1))
(define linux-5.15 (corrupt-linux linux-libre-5.15))
(define linux-5.10 (corrupt-linux linux-libre-5.10))

(define-public linux     linux-6.18)
(define-public linux-lts linux-6.12)

;;; ============================================================================
;;; Linux Firmware
;;; ============================================================================

(define-public linux-firmware
  (package
    (name "linux-firmware")
    (version "20260410")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kernel.org/linux/kernel/firmware/"
                                  "linux-firmware-" version ".tar.xz"))
              (sha256
               (base32
                "0y71y41bykla8xhclihfriwjms578bl0panxrvn0jswzspb2x0dp"))))
    (build-system gnu-build-system)
    (arguments
     (list #:tests? #f
           #:strip-binaries? #f
           #:validate-runpath? #f
           #:make-flags #~(list (string-append "DESTDIR=" #$output))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'patch-out-check_whence.py
                 (lambda _
                   (substitute* "copy-firmware.sh"
                     (("./check_whence.py") "true"))))
               (delete 'configure)
               (replace 'install
                 (lambda* (#:key (parallel-build? #t) (make-flags '())
                           #:allow-other-keys)
                   (let ((num-jobs (if parallel-build?
                                       (number->string (parallel-job-count))
                                       "1")))
                     (setenv "ZSTD_CLEVEL" "19")
                     (setenv "ZSTD_NBTHREADS" num-jobs)
                     (apply invoke "make" "install-zst" "-j" num-jobs
                            make-flags)))))))
    (native-inputs (list parallel rdfind zstd))
    (home-page
     "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git")
    (synopsis "Nonfree firmware blobs for Linux")
    (description "Nonfree firmware blobs for enabling support for various
hardware in the Linux kernel.")
    (license (nonfree "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/WHENCE"))))

;;; ============================================================================
;;; Microcode Packages
;;; ============================================================================

(define (select-firmware keep)
  #~(lambda _
      (use-modules (ice-9 regex))
      (substitute* "WHENCE"
        (("^(File|RawFile): *([^ ]*)(.*)" _ type file rest)
         (string-append (if (string-match #$keep file) type "Skip") ": " file rest))
        (("^Link: *(.*) *-> *(.*)" _ file target)
         (string-append (if (string-match #$keep target) "Link" "Skip")
                        ": " file " -> " target)))))

(define-public intel-microcode
  (package
    (name "intel-microcode")
    (version "20250512")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files.git")
             (commit (string-append "microcode-" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0da4aj0hpj6xn9vfb0k7mznndv53ihbv3mhjz71skwmy1vbibay5"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~(let ((doc (string-append "share/doc/" #$name "-" #$version "/")))
               `(("intel-ucode" "lib/firmware/")
                 ("README.md" ,doc)
                 ("releasenote.md" ,doc)
                 ("security.md" ,doc)))))
    (home-page "https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files")
    (synopsis "Processor microcode firmware for Intel CPUs")
    (description "Updated system processor microcode for Intel i686 and x86-64.")
    (license (nonfree "file://license"))))

(define-public amd-microcode
  (package
    (inherit linux-firmware)
    (name "amd-microcode")
    (arguments
     (cons* #:license-file-regexp "LICENSE.amd-ucode"
            (substitute-keyword-arguments (package-arguments linux-firmware)
              ((#:phases phases #~%standard-phases)
               #~(modify-phases #$phases
                   (add-after 'unpack 'select-firmware
                     #$(select-firmware "^amd-ucode/")))))))
    (synopsis "Processor microcode firmware for AMD CPUs")
    (description "Updated system processor microcode for AMD x86-64 processors.")
    (license
     (nonfree
      (string-append "https://git.kernel.org/pub/scm/linux/kernel/git/"
                     "firmware/linux-firmware.git/plain/LICENSE.amd-ucode")))))

;;; ============================================================================
;;; Microcode Initrd
;;; ============================================================================

(define (microcode-initrd* microcode-packages)
  (define builder
    (with-imported-modules (source-module-closure
                            '((guix build utils)
                              (srfi srfi-1)
                              (srfi srfi-26)))
      #~(begin
          (use-modules (guix build utils)
                       (srfi srfi-1)
                       (srfi srfi-26)
                       (rnrs bytevectors)
                       (rnrs io ports))
          (define (concatenate-files files result)
            (define (dump file port)
              (put-bytevector port (call-with-input-file file get-bytevector-all)))
            (call-with-output-file result
              (lambda (port) (for-each (cut dump <> port) files))))
          (let* ((initrd (string-append #$output "/initrd.cpio"))
                 (dest-dir "kernel/x86/microcode")
                 (amd-bin   (string-append dest-dir "/AuthenticAMD.bin"))
                 (intel-bin (string-append dest-dir "/GenuineIntel.bin")))
            (mkdir-p dest-dir)
            (for-each
             (lambda (package)
               (let ((intel-ucode (string-append package "/lib/firmware/intel-ucode"))
                     (amd-ucode   (string-append package "/lib/firmware/amd-ucode")))
                 (when (directory-exists? intel-ucode)
                   (concatenate-files (find-files intel-ucode ".*") intel-bin))
                 (when (directory-exists? amd-ucode)
                   (concatenate-files (find-files amd-ucode "^microcode_amd.*\\.bin$")
                                      amd-bin))))
             '#$microcode-packages)
            (mkdir-p #$output)
            (invoke #$(file-append tar "/bin/tar") "-cf" initrd
                    "-C" dest-dir ".")))))
  (file-append (computed-file "microcode-initrd" builder
                              #:options '(#:local-build? #t))
               "/initrd.cpio"))

(define (combined-initrd . initrds)
  (define builder
    (with-imported-modules (source-module-closure
                            '((guix build utils)
                              (srfi srfi-1)))
      #~(begin
          (use-modules (guix build utils)
                       (srfi srfi-1)
                       (rnrs bytevectors)
                       (rnrs io ports))
          (let ((initrd (string-append #$output "/initrd.img")))
            (mkdir-p #$output)
            (call-with-output-file initrd
              (lambda (out)
                (for-each
                 (lambda (in-file)
                   (call-with-input-file in-file
                     (lambda (in)
                       (put-bytevector out (get-bytevector-all in)))))
                 '#$initrds)))))))
  (file-append (computed-file "combined-initrd" builder
                              #:options '(#:local-build? #t))
               "/initrd.img"))

(define* (microcode-initrd file-systems
                           #:key
                           (initrd base-initrd)
                           (microcode-packages (list amd-microcode intel-microcode))
                           #:allow-other-keys
                           #:rest rest)
  (let ((args (strip-keyword-arguments '(#:initrd #:microcode-packages) rest)))
    (combined-initrd (microcode-initrd* microcode-packages)
                     (apply initrd file-systems args))))

;;; ============================================================================
;;; System Configuration Exports
;;; ============================================================================

(define-public kernel linux)
(define-public kernel-initrd base-initrd)
(define-public kernel-firmware (list linux-firmware))
(define-public kernel-arguments
  '("pci=noaer"
    "rtw88_core.disable_lps_deep=1"
    "net.core.netdev_budget=600"
    "net.core.netdev_budget_usecs=8000"))
(define-public kernel-modules
  (service kernel-module-loader-service-type
           (list "uinput")))