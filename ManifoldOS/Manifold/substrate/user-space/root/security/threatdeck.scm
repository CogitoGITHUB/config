(define-module (substrate user-space root security threatdeck)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages tls)
  #:export (threatdeck))

(define-public threatdeck
  (package
    (name "threatdeck")
    (version "0.6.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/gripebomb/ThreatDeck/releases/"
                    "download/v" version
                    "/ThreatDeck-x86_64-linux"))
              (sha256
               (base32
                "11rj1fy2ba5k3zqghb0ib8yyjkk9iaas2lzqgybnszmslrky0d3p"))))
    (build-system trivial-build-system)
    (native-inputs
     (list patchelf))
    (inputs
     (list glibc (list gcc "lib") openssl))
    (arguments
     (list #:modules (quote ((guix build utils)))
           #:builder
           (quasiquote (begin
             (use-modules (guix build utils))
             (let* ((out     (assoc-ref %outputs "out"))
                    (src     (assoc-ref %build-inputs "source"))
                    (binfile (string-append out "/bin/ThreatDeck"))
                    (glibc   (assoc-ref %build-inputs "glibc"))
                    (gcc     (assoc-ref %build-inputs "gcc"))
                    (openssl (assoc-ref %build-inputs "openssl"))
                    (patchelf (assoc-ref %build-inputs "patchelf"))
                    (linker  (string-append glibc
                                            "/lib/ld-linux-x86-64.so.2"))
                    (rpath   (string-append glibc "/lib:" gcc "/lib:" openssl "/lib")))
               (setenv "PATH" (string-append patchelf "/bin"))
               (mkdir-p (string-append out "/bin"))
               (copy-file src binfile)
               (chmod binfile #o755)
               (invoke "patchelf"
                       "--set-interpreter" linker
                       "--set-rpath" rpath
                       binfile))))))
    (synopsis "Terminal-based threat intelligence platform")
    (description
     "ThreatDeck is a terminal-based threat intelligence monitoring and
alerting platform for SOCs, security researchers, and threat intelligence
analysts.  Supports multi-source feeds, keyword matching, IOC extraction,
and notifications.")
    (home-page "https://github.com/gripebomb/ThreatDeck")
    (license license:expat)))
