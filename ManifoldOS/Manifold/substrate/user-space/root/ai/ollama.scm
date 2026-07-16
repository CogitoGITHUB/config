(define-module (substrate user-space root ai ollama)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (substrate user-space root shell archive unzip)
  #:use-module (substrate user-space root shell archive zstd)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu services)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (ollama))

(define-public ollama
  (package
    (name "ollama")
    (version "0.19.0")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/ollama/ollama/releases/download/v" version
              "/ollama-linux-amd64.tar.zst"))
        (sha256 (base32 "1lm54ssmcnrhr7yhfb5xwwis22j3ymgvk8a30l1r3rb9lb1vxv5k"))))
    (build-system trivial-build-system)
    (inputs (list bash tar zstd patchelf glibc `(,gcc "lib")))
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (src (assoc-ref %build-inputs "source"))
                (glibc (assoc-ref %build-inputs "glibc"))
                (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
                (zstd (string-append (assoc-ref %build-inputs "zstd") "/bin/zstd"))
                (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
                (interp (string-append glibc "/lib/ld-linux-x86-64.so.2"))
                (gcc (assoc-ref %build-inputs "gcc"))
                (libstdc++ (string-append gcc "/lib"))
                (ollama-real (string-append out "/bin/ollama-real"))
                (ollama-bin (string-append out "/bin/ollama")))
           (setenv "PATH" (string-append (assoc-ref %build-inputs "bash") "/bin:" (assoc-ref %build-inputs "tar") "/bin:" (assoc-ref %build-inputs "zstd") "/bin"))
           (mkdir-p out)
           (invoke "sh" "-c" (string-append zstd " -d -c " src " | " tar " xf - -C " out))
           (rename-file (string-append out "/bin/ollama") ollama-real)
           (invoke patchelf "--set-interpreter" interp "--set-rpath" (string-append glibc "/lib:" libstdc++) ollama-real)
           (call-with-output-file ollama-bin
             (lambda (port)
               (format port "#!/bin/sh\nexec ~a \"$@\"\n" ollama-real)))
           (chmod ollama-bin #o555)))))
    (home-page "https://ollama.com")
    (synopsis "Get up and running with large language models locally")
    (description "Ollama is a tool for running large language models locally on your machine. It supports Llama, Mistral, Phi, and many other open models.")
    (license license:expat)))

;; Service configuration
#;(define-record-type* <ollama-service-configuration>
  ollama-service-configuration make-ollama-service-configuration
  ollama-service-configuration?
  (ollama        ollama-service-configuration-ollama
                 (default ollama))
  (host          ollama-service-configuration-host
                 (default "0.0.0.0"))
  (port          ollama-service-configuration-port
                 (default 11434))
  (models-path   ollama-service-configuration-models-path
                 (default "/var/lib/ollama")))

#;(define (ollama-shepherd-service config)
  (let ((ollama-pkg (ollama-service-configuration-ollama config))
        (host (ollama-service-configuration-host config))
        (port (ollama-service-configuration-port config))
        (models (ollama-service-configuration-models-path config)))
    (list (shepherd-service
           (provision '(ollama))
           (requirement '(networking))
           (documentation "Run the Ollama LLM server")
           (start #~(make-forkexec-constructor
                     (list #$(file-append ollama-pkg "/bin/ollama") "serve")
                     #:log-file "/var/log/ollama.log"
                     #:environment-variables
                     (list (string-append "OLLAMA_HOST=" #$host ":" #$(number->string port))
                           (string-append "OLLAMA_MODELS=" #$models))))
           (stop #~(make-kill-destructor))
           (auto-start? #t)))))

#;(define-public ollama-service-type
  (service-type (name 'ollama)
                (extensions (list (service-extension
                                   shepherd-root-service-type
                                   (lambda (config)
                                     (ollama-shepherd-service config)))))
                (default-value (ollama-service-configuration))
                (description "Run the Ollama LLM server as a background service.")))

;; Convenience function
#;(define* (ollama-service #:key (ollama ollama)
                         (host "0.0.0.0")
                         (port 11434)
                         (models-path "/var/lib/ollama"))
  "Return an Ollama service with the given configuration."
  (service ollama-service-type
           (ollama-service-configuration
            (ollama ollama)
            (host host)
            (port port)
            (models-path models-path))))
