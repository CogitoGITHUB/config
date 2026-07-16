(define-module (forms monitoring siomon)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (gnu packages gcc)
  #:use-module (substrate user-space root shell archive gzip)
  #:use-module (gnu packages elf)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (siomon))

(define-public siomon
  (package
    (name "siomon")
    (version "0.2.3")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/level1techs/siomon/releases/download/v" version
              "/sio-linux-x86_64.tar.gz"))
        (sha256 (base32 "0pyb3wqdz3j6nb98nvg9f7fbj2nij4yz3yl583p14xw0g5y6vk0y"))))
    (build-system trivial-build-system)
    (inputs `(("tar" ,tar)
              ("gzip" ,gzip)
              ("patchelf" ,patchelf)
              ("glibc" ,glibc)
              ("gcc-lib" ,gcc "lib")))
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (src (assoc-ref %build-inputs "source"))
                (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                (gzip (string-append (assoc-ref %build-inputs "gzip") "/bin"))
                (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                (glibc (assoc-ref %build-inputs "glibc"))
                (gcc-lib (assoc-ref %build-inputs "gcc-lib"))
                (interp (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                (rpath (string-append glibc "/lib:" gcc-lib "/lib")))
           (setenv "PATH" gzip)
           (mkdir-p (string-append out "/bin"))
           (invoke tar "-xzf" src "-C" (string-append out "/bin"))
           (invoke patchelf "--set-interpreter" interp
                    "--set-rpath" rpath
                    (string-append out "/bin/sio"))))))
    (home-page "https://github.com/level1techs/siomon")
    (synopsis "Linux hardware information and real-time sensor monitoring")
    (description
     "siomon is a comprehensive Linux hardware information and real-time
sensor monitoring tool.  Run @command{sio} to launch an interactive TUI
dashboard that polls all kernel-exported sensors in real time with min/max/avg
tracking, configurable alerts, and CSV logging.  Subcommands like @command{sio
cpu}, @command{sio gpu}, or @command{sio storage} provide one-shot hardware
information.  Reads directly from kernel interfaces — no userspace daemons
required.  Supports CPU (CPUID, topology, frequency, utilization, RAPL power),
GPU (NVIDIA via NVML, AMD via sysfs, Intel via i915/xe), hwmon sensors,
storage, network, PCI/USB devices, and battery.")
    (license license:expat)))
