
:tanat

"30.2"

#s(hash-table test equal data ("straight" ("2025-10-11 01:08:28" ("emacs") (:type git :host github :repo "radian-software/straight.el" :files ("straight*.el") :branch "main" :package "straight" :local-repo "straight.el")) "org-elpa" ("2025-10-11 01:08:28" nil (:local-repo nil :package "org-elpa" :type git)) "melpa" ("2025-10-11 01:08:41" nil (:type git :host github :repo "melpa/melpa" :build nil :package "melpa" :local-repo "melpa")) "gnu-elpa-mirror" ("2025-10-11 01:08:42" nil (:type git :host github :repo "emacs-straight/gnu-elpa-mirror" :build nil :package "gnu-elpa-mirror" :local-repo "gnu-elpa-mirror")) "use-package" ("2025-10-11 01:08:46" ("emacs" "bind-key") (:type git :host github :repo "emacs-straight/use-package" :files ("*" (:exclude ".git")) :package "use-package" :local-repo "use-package")) "bind-key" ("2025-10-11 01:08:45" ("emacs") (:type git :host github :repo "emacs-straight/bind-key" :files ("*" (:exclude ".git")) :package "bind-key" :local-repo "bind-key")) "org" ("2025-10-11 01:10:48" ("emacs") (:type git :host github :protocol https :repo "emacs-straight/org-mode" :local-repo "org" :depth full :pre-build (straight-recipes-org-elpa--build) :build (:not autoloads) :files (:defaults "lisp/*.el" ("etc/styles/" "etc/styles/*")) :package "org")) "denote" ("2025-10-17 14:09:31" ("emacs") (:type git :host github :repo "protesilaos/denote" :files ("*" (:exclude ".git")) :package "denote" :local-repo "denote")) "org-roam" ("2025-10-17 20:21:49" ("emacs" "dash" "org" "emacsql" "magit-section") (:type git :host github :repo "org-roam/org-roam" :files (:defaults "extensions/*" "org-roam-pkg.el") :package "org-roam" :local-repo "org-roam")) "dash" ("2025-10-17 20:21:27" ("emacs") (:type git :files ("dash.el" "dash.texi" "dash-pkg.el") :host github :repo "magnars/dash.el" :package "dash" :local-repo "dash.el")) "emacsql" ("2025-10-17 20:21:30" ("emacs") (:type git :files (:defaults "README.md" "sqlite" "emacsql-pkg.el") :host github :repo "magit/emacsql" :package "emacsql" :local-repo "emacsql")) "magit-section" ("2025-10-17 20:21:48" ("emacs" "compat" "cond-let" "llama" "seq") (:type git :files ("lisp/magit-section.el" "docs/magit-section.texi" "magit-section-pkg.el" "magit-section-pkg.el") :host github :repo "magit/magit" :package "magit-section" :local-repo "magit")) "compat" ("2025-10-17 20:21:45" ("emacs" "seq") (:type git :host github :repo "emacs-straight/compat" :files ("*" (:exclude ".git")) :package "compat" :local-repo "compat")) "seq" ("2025-10-17 20:21:44" nil (:type git :host github :repo "emacs-straight/seq" :files ("*" (:exclude ".git")) :package "seq" :local-repo "seq")) "cond-let" ("2025-10-17 20:21:46" ("emacs") (:type git :host github :repo "tarsius/cond-let" :package "cond-let" :local-repo "cond-let")) "llama" ("2025-10-17 20:21:47" ("emacs" "compat") (:type git :files ("llama.el" ".dir-locals.el" "llama-pkg.el") :host github :repo "tarsius/llama" :package "llama" :local-repo "llama")) "org-roam-ui" ("2025-10-17 20:22:11" ("emacs" "org-roam" "simple-httpd" "websocket") (:type git :host github :repo "org-roam/org-roam-ui" :files (:defaults "out" "org-roam-ui-pkg.el") :package "org-roam-ui" :local-repo "org-roam-ui")) "simple-httpd" ("2025-10-17 20:22:09" ("cl-lib") (:type git :host github :repo "skeeto/emacs-web-server" :package "simple-httpd" :local-repo "emacs-web-server")) "nongnu-elpa" ("2025-10-17 20:22:04" nil (:type git :repo "https://github.com/emacsmirror/nongnu_elpa.git" :depth (full single-branch) :local-repo "nongnu-elpa" :build nil :package "nongnu-elpa")) "el-get" ("2025-10-17 20:22:07" nil (:type git :host github :repo "dimitri/el-get" :build nil :package "el-get" :local-repo "el-get")) "emacsmirror-mirror" ("2025-10-17 20:22:09" nil (:type git :host github :repo "emacs-straight/emacsmirror-mirror" :build nil :package "emacsmirror-mirror" :local-repo "emacsmirror-mirror")) "websocket" ("2025-10-17 20:22:11" ("cl-lib") (:type git :host github :repo "ahyatt/emacs-websocket" :package "websocket" :local-repo "emacs-websocket"))))

#s(hash-table test equal data ("straight" ((straight-x straight straight-autoloads straight-ert-print-hack) (autoload 'straight-remove-unused-repos "straight" "Remove unused repositories from the repos and build directories.
A repo is considered \"unused\" if it was not explicitly requested via
`straight-use-package' during the current Emacs session.
If FORCE is non-nil do not prompt before deleting repos.

(fn &optional FORCE)" t) (autoload 'straight-get-recipe "straight" "Interactively select a recipe from one of the recipe repositories.
All recipe repositories in `straight-recipe-repositories' will
first be cloned. After the recipe is selected, it will be copied
to the kill ring. With a prefix argument, first prompt for a
recipe repository to search. Only that repository will be
cloned.

From Lisp code, SOURCES should be a subset of the symbols in
`straight-recipe-repositories'. Only those recipe repositories
are cloned and searched. If it is nil or omitted, then the value
of `straight-recipe-repositories' is used. If SOURCES is the
symbol `interactive', then the user is prompted to select a
recipe repository, and a list containing that recipe repository
is used for the value of SOURCES. ACTION may be `copy' (copy
recipe to the kill ring), `insert' (insert at point), or nil (no
action, just return it).

Optional arg FILTER must be a unary function.
It takes a package name as its sole argument.
If it returns nil the candidate is excluded.

USE-CACHE non-nil means respect the existing straight.el recipe cache,
i.e. display also packages that have been registered in the current
Emacs session even if not found in any recipe repository, and if such a
package is selected, return just the package name as a symbol, instead
of a recipe. (It is not possible to return an actual recipe, as the API
for `straight-get-recipe' returns MELPA-style recipes, while cached
recipes have already been converted into the internal format.)

Within `straight-get-recipe', the symbol `cache' is treated as if it is
also a member of `straight-recipe-repositories', and refers to the set
of packages that have already been registered in the current Emacs
session.

(fn &optional SOURCES ACTION FILTER USE-CACHE)" t) (autoload 'straight-visit-package-website "straight" "Visit the package RECIPE's website.

(fn RECIPE)" t) (autoload 'straight-visit-package "straight" "Open PACKAGE's local repository directory.
When BUILD is non-nil visit PACKAGE's build directory.

(fn PACKAGE &optional BUILD)" t) (autoload 'straight-use-package "straight" "Register, clone, build, and activate a package and its dependencies.
This is the main entry point to the functionality of straight.el.

MELPA-STYLE-RECIPE is either a symbol naming a package, or a list
whose car is a symbol naming a package and whose cdr is a
property list containing e.g. `:type', `:local-repo', `:files',
and VC backend specific keywords.

First, the package recipe is registered with straight.el. If
NO-CLONE is a function, then it is called with two arguments: the
package name as a string, and a boolean value indicating whether
the local repository for the package is available. In that case,
the return value of the function is used as the value of NO-CLONE
instead. In any case, if NO-CLONE is non-nil, then processing
stops here.

Otherwise, the repository is cloned, if it is missing. If
NO-BUILD is a function, then it is called with one argument: the
package name as a string. In that case, the return value of the
function is used as the value of NO-BUILD instead. In any case,
if NO-BUILD is non-nil, then processing halts here. Otherwise,
the package is built and activated. Note that if the package
recipe has a nil `:build' entry, then NO-BUILD is ignored
and processing always stops before building and activation
occurs.

CAUSE is a string explaining the reason why
`straight-use-package' has been called. It is for internal use
only, and is used to construct progress messages. INTERACTIVE is
non-nil if the function has been called interactively. It is for
internal use only, and is used to determine whether to show a
hint about how to install the package permanently.

Return non-nil when package is initially installed, nil otherwise.

Interactively, prompt with a list of available packages in currently
registered recipe repositories. With prefix arg, prompt first for which
recipe repository to list from. If a package has already been registered
in the current Emacs session, the existing recipe is re-used rather than
being looked up anew. With prefix arg, \"cache\" is displayed as one of
the recipe repositories, and allows filtering to only already-registered
packages.

(fn MELPA-STYLE-RECIPE &optional NO-CLONE NO-BUILD CAUSE INTERACTIVE)" t) (autoload 'straight-register-package "straight" "Register a package without cloning, building, or activating it.
This function is equivalent to calling `straight-use-package'
with a non-nil argument for NO-CLONE. It is provided for
convenience. MELPA-STYLE-RECIPE is as for
`straight-use-package'.

(fn MELPA-STYLE-RECIPE)") (autoload 'straight-use-package-no-build "straight" "Register and clone a package without building it.
This function is equivalent to calling `straight-use-package'
with nil for NO-CLONE but a non-nil argument for NO-BUILD. It is
provided for convenience. MELPA-STYLE-RECIPE is as for
`straight-use-package'.

(fn MELPA-STYLE-RECIPE)") (autoload 'straight-use-package-lazy "straight" "Register, build, and activate a package if it is already cloned.
This function is equivalent to calling `straight-use-package'
with symbol `lazy' for NO-CLONE. It is provided for convenience.
MELPA-STYLE-RECIPE is as for `straight-use-package'.

Argument CAUSE is for internal use only.

(fn MELPA-STYLE-RECIPE &optional CAUSE)") (autoload 'straight-use-recipes "straight" "Register a recipe repository using MELPA-STYLE-RECIPE.
This registers the recipe and builds it if it is already cloned.
Note that you probably want the recipe for a recipe repository to
include a nil `:build' property, to unconditionally
inhibit the build phase.

This function also adds the recipe repository to
`straight-recipe-repositories', at the end of the list.

Existing recipe repositories are not searched for a recipe for the
recipe repository you are trying to register, because that is strange
and confusing. If you explicitly want this behavior, you can use the
`straight-use-package' API directly.

Argument CAUSE is for internal use only.

(fn MELPA-STYLE-RECIPE &optional CAUSE)") (autoload 'straight-override-recipe "straight" "Register MELPA-STYLE-RECIPE as a recipe override.
This puts it in `straight-recipe-overrides', depending on the
value of `straight-current-profile'.

(fn MELPA-STYLE-RECIPE)") (autoload 'straight-check-package "straight" "Rebuild a PACKAGE if it has been modified.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. See also `straight-rebuild-package' and
`straight-check-all'.

(fn PACKAGE)" t) (autoload 'straight-check-all "straight" "Rebuild any packages that have been modified.
See also `straight-rebuild-all' and `straight-check-package'.
This function should not be called during init." t) (autoload 'straight-rebuild-package "straight" "Rebuild a PACKAGE.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument RECURSIVE, rebuild
all dependencies as well. See also `straight-check-package' and
`straight-rebuild-all'.

(fn PACKAGE &optional RECURSIVE)" t) (autoload 'straight-rebuild-all "straight" "Rebuild all packages.
See also `straight-check-all' and `straight-rebuild-package'." t) (autoload 'straight-prune-build-cache "straight" "Prune the build cache.
This means that only packages that were built in the last init
run and subsequent interactive session will remain; other
packages will have their build mtime information and any cached
autoloads discarded.") (autoload 'straight-prune-build-directory "straight" "Prune the build directory.
This means that only packages that were built in the last init
run and subsequent interactive session will remain; other
packages will have their build directories deleted.") (autoload 'straight-prune-build "straight" "Prune the build cache and build directory.
This means that only packages that were built in the last init
run and subsequent interactive session will remain; other
packages will have their build mtime information discarded and
their build directories deleted." t) (autoload 'straight-normalize-package "straight" "Normalize a PACKAGE's local repository to its recipe's configuration.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'.

CONVERT-SNAPSHOTS non-nil (interactively, prefix arg) means if the
repository is a snapshot, convert it to a full repository first.

(fn PACKAGE &key CONVERT-SNAPSHOTS)" t) (autoload 'straight-normalize-all "straight" "Normalize all packages. See `straight-normalize-package'.
Return a list of recipes for packages that were not successfully
normalized. If multiple packages come from the same local
repository, only one is normalized.

PREDICATE, if provided, filters the packages that are normalized.
It is called with the package name as a string, and should return
non-nil if the package should actually be normalized.

CONVERT-SNAPSHOTS non-nil (interactively, prefix arg) means if
repositories are snapshots, convert them to full repositories first.

(fn &optional PREDICATE CONVERT-SNAPSHOTS)" t) (autoload 'straight-fetch-package "straight" "Try to fetch a PACKAGE from the primary remote.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument FROM-UPSTREAM,
fetch not just from primary remote but also from upstream (for
forked packages).

(fn PACKAGE &optional FROM-UPSTREAM)" t) (autoload 'straight-fetch-package-and-deps "straight" "Try to fetch a PACKAGE and its (transitive) dependencies.
PACKAGE, its dependencies, their dependencies, etc. are fetched
from their primary remotes.

PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument FROM-UPSTREAM,
fetch not just from primary remote but also from upstream (for
forked packages).

(fn PACKAGE &optional FROM-UPSTREAM)" t) (autoload 'straight-fetch-all "straight" "Try to fetch all packages from their primary remotes.
With prefix argument FROM-UPSTREAM, fetch not just from primary
remotes but also from upstreams (for forked packages).

Return a list of recipes for packages that were not successfully
fetched. If multiple packages come from the same local
repository, only one is fetched.

PREDICATE, if provided, filters the packages that are fetched. It
is called with the package name as a string, and should return
non-nil if the package should actually be fetched.

(fn &optional FROM-UPSTREAM PREDICATE)" t) (autoload 'straight-merge-package "straight" "Try to merge a PACKAGE from the primary remote.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument FROM-UPSTREAM,
merge not just from primary remote but also from upstream (for
forked packages).

(fn PACKAGE &optional FROM-UPSTREAM)" t) (autoload 'straight-merge-package-and-deps "straight" "Try to merge a PACKAGE and its (transitive) dependencies.
PACKAGE, its dependencies, their dependencies, etc. are merged
from their primary remotes.

PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument FROM-UPSTREAM,
merge not just from primary remote but also from upstream (for
forked packages).

(fn PACKAGE &optional FROM-UPSTREAM)" t) (autoload 'straight-merge-all "straight" "Try to merge all packages from their primary remotes.
With prefix argument FROM-UPSTREAM, merge not just from primary
remotes but also from upstreams (for forked packages).

Return a list of recipes for packages that were not successfully
merged. If multiple packages come from the same local
repository, only one is merged.

PREDICATE, if provided, filters the packages that are merged. It
is called with the package name as a string, and should return
non-nil if the package should actually be merged.

(fn &optional FROM-UPSTREAM PREDICATE)" t) (autoload 'straight-pull-package "straight" "Try to pull a PACKAGE from the primary remote.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument FROM-UPSTREAM, pull
not just from primary remote but also from upstream (for forked
packages).

(fn PACKAGE &optional FROM-UPSTREAM)" t) (autoload 'straight-pull-package-and-deps "straight" "Try to pull a PACKAGE and its (transitive) dependencies.
PACKAGE, its dependencies, their dependencies, etc. are pulled
from their primary remotes.

PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'. With prefix argument FROM-UPSTREAM,
pull not just from primary remote but also from upstream (for
forked packages).

(fn PACKAGE &optional FROM-UPSTREAM)" t) (autoload 'straight-pull-all "straight" "Try to pull all packages from their primary remotes.
With prefix argument FROM-UPSTREAM, pull not just from primary
remotes but also from upstreams (for forked packages).

Return a list of recipes for packages that were not successfully
pulled. If multiple packages come from the same local repository,
only one is pulled.

PREDICATE, if provided, filters the packages that are pulled. It
is called with the package name as a string, and should return
non-nil if the package should actually be pulled.

(fn &optional FROM-UPSTREAM PREDICATE)" t) (autoload 'straight-push-package "straight" "Push a PACKAGE to its primary remote, if necessary.
PACKAGE is a string naming a package. Interactively, select
PACKAGE from the known packages in the current Emacs session
using `completing-read'.

(fn PACKAGE)" t) (autoload 'straight-push-all "straight" "Try to push all packages to their primary remotes.

Return a list of recipes for packages that were not successfully
pushed. If multiple packages come from the same local repository,
only one is pushed.

PREDICATE, if provided, filters the packages that are normalized.
It is called with the package name as a string, and should return
non-nil if the package should actually be normalized.

(fn &optional PREDICATE)" t) (autoload 'straight-freeze-versions "straight" "Write version lockfiles for currently activated packages.
This implies first pushing all packages that have unpushed local
changes. If the package management system has been used since the
last time the init-file was reloaded, offer to fix the situation
by reloading the init-file again. If FORCE is
non-nil (interactively, if a prefix argument is provided), skip
all checks and write the lockfile anyway.

Currently, writing version lockfiles requires cloning all lazily
installed packages. Hopefully, this inconvenient requirement will
be removed in the future.

Multiple lockfiles may be written (one for each profile),
according to the value of `straight-profiles'.

(fn &optional FORCE)" t) (autoload 'straight-thaw-versions "straight" "Read version lockfiles and restore package versions to those listed." t) (autoload 'straight-bug-report "straight" "Test straight.el in a clean environment.
ARGS may be any of the following keywords and their respective values:
  - :pre-bootstrap (Form)...
      Forms evaluated before bootstrapping straight.el
      e.g. (setq straight-repository-branch \"develop\")
      Note this example is already in the default bootstrapping code.

  - :post-bootstrap (Form)...
      Forms evaluated in the testing environment after boostrapping.
      e.g. (straight-use-package \\='(example :type git :host github))

  - :interactive Boolean
      If nil, the subprocess will immediately exit after the test.
      Output will be printed to `straight-bug-report--process-buffer'
      Otherwise, the subprocess will be interactive.

  - :preserve Boolean
      If non-nil, the test directory is left in the directory stored in the
      variable `temporary-file-directory'. Otherwise, it is
      immediately removed after the test is run.

  - :executable String
      Indicate the Emacs executable to launch.
      Defaults to the path of the current Emacs executable.

  - :raw Boolean
      If non-nil, the raw process output is sent to
      `straight-bug-report--process-buffer'. Otherwise, it is
      formatted as markdown for submitting as an issue.

  - :user-dir String
      If non-nil, the test is run with `user-emacs-directory' set to STRING.
      Otherwise, a temporary directory is created and used.
      Unless absolute, paths are expanded relative to the variable
      `temporary-file-directory'.

ARGS are accessible within the :pre/:post-bootsrap phases via the
locally bound plist, straight-bug-report-args.

(fn &rest ARGS)" nil t) (function-put 'straight-bug-report 'lisp-indent-function 0) (autoload 'straight-dependencies "straight" "Return a list of PACKAGE's dependencies, as strings.
PACKAGE is a string. If the dependencies have dependencies themselves,
then instead of strings they will be lists whose cars are the
dependencies and whose cdrs are the recursive dependencies in the same
format returned from `straight-dependencies'.

Interactively, the user selects a package to show dependencies for, and
the dependencies are shown in the echo area.

(fn &optional PACKAGE)" t) (autoload 'straight-dependents "straight" "Return a list of PACKAGE's dependents, as strings.
Dependents are packages that have the given package as a dependency. In
other words, this is the opposite of `straight-dependencies'.

PACKAGE is a string. If the dependents have dependents themselves, then
instead of strings they will be lists whose cars are the dependents and
whose cdrs are the recursive dependents in the same format returned from
`straight-dependents'.

(fn &optional PACKAGE)" t) (register-definition-prefixes "straight" '("straight-")) (register-definition-prefixes "straight-ert-print-hack" '("+without-print-limits")) (defvar straight-x-pinned-packages nil "List of pinned packages.") (register-definition-prefixes "straight-x" '("straight-x-")) (provide 'straight-autoloads)) "bind-key" ((bind-key-pkg bind-key bind-key-autoloads) (defvar personal-keybindings nil "List of bindings performed by `bind-key'.

Elements have the form ((KEY . [MAP]) CMD ORIGINAL-CMD)") (autoload 'bind-key "bind-key" "Bind KEY-NAME to COMMAND in KEYMAP (`global-map' if not passed).

KEY-NAME may be a vector, in which case it is passed straight to
`define-key'.  Or it may be a string to be interpreted as
spelled-out keystrokes, e.g., \"C-c C-z\".  See the documentation
of `edmacro-mode' for details.

COMMAND must be an interactive function or lambda form.

KEYMAP, if present, should be a keymap variable or symbol.
For example:

  (bind-key \"M-h\" #\\='some-interactive-function my-mode-map)

  (bind-key \"M-h\" #\\='some-interactive-function \\='my-mode-map)

If PREDICATE is non-nil, it is a form evaluated to determine when
a key should be bound. It must return non-nil in such cases.
Emacs can evaluate this form at any time that it does redisplay
or operates on menu data structures, so you should write it so it
can safely be called at any time.

(fn KEY-NAME COMMAND &optional KEYMAP PREDICATE)" nil t) (autoload 'unbind-key "bind-key" "Unbind the given KEY-NAME, within the KEYMAP (if specified).
See `bind-key' for more details.

(fn KEY-NAME &optional KEYMAP)" nil t) (autoload 'bind-key* "bind-key" "Similar to `bind-key', but overrides any mode-specific bindings.

(fn KEY-NAME COMMAND &optional PREDICATE)" nil t) (autoload 'bind-keys "bind-key" "Bind multiple keys at once.

Accepts keyword arguments:
:map MAP               - a keymap into which the keybindings should be
                         added
:prefix KEY            - prefix key for these bindings
:prefix-map MAP        - name of the prefix map that should be created
                         for these bindings
:prefix-docstring STR  - docstring for the prefix-map variable
:menu-name NAME        - optional menu string for prefix map
:repeat-docstring STR  - docstring for the repeat-map variable
:repeat-map MAP        - name of the repeat map that should be created
                         for these bindings. If specified, the
                         `repeat-map' property of each command bound
                         (within the scope of the `:repeat-map' keyword)
                         is set to this map.
:exit BINDINGS         - Within the scope of `:repeat-map' will bind the
                         key in the repeat map, but will not set the
                         `repeat-map' property of the bound command.
:continue BINDINGS     - Within the scope of `:repeat-map' forces the
                         same behavior as if no special keyword had
                         been used (that is, the command is bound, and
                         it's `repeat-map' property set)
:continue-only BINDINGS - Within the scope of `:repeat-map', will make
                         the command continue but not enter the repeat
                         map, via the `repeat-continue' property
:filter FORM           - optional form to determine when bindings apply

The rest of the arguments are conses of keybinding string and a
function symbol (unquoted).

(fn &rest ARGS)" nil t) (autoload 'bind-keys* "bind-key" "Bind multiple keys at once, in `override-global-map'.
Accepts the same keyword arguments as `bind-keys' (which see).

This binds keys in such a way that bindings are not overridden by
other modes.  See `override-global-mode'.

(fn &rest ARGS)" nil t) (autoload 'describe-personal-keybindings "bind-key" "Display all the personal keybindings defined by `bind-key'." t) (register-definition-prefixes "bind-key" '("bind-key" "override-global-m")) (provide 'bind-key-autoloads)) "use-package" ((use-package-delight use-package-pkg use-package-ensure use-package-lint use-package-jump use-package-diminish use-package use-package-autoloads use-package-ensure-system-package use-package-core use-package-bind-key) (autoload 'use-package-autoload-keymap "use-package-bind-key" "Load PACKAGE and bind key sequence invoking this function to KEYMAP-SYMBOL.
Then simulate pressing the same key sequence a again, so that the
next key pressed is routed to the newly loaded keymap.

This function supports use-package's :bind-keymap keyword.  It
works by binding the given key sequence to an invocation of this
function for a particular keymap.  The keymap is expected to be
defined by the package.  In this way, loading the package is
deferred until the prefix key sequence is pressed.

(fn KEYMAP-SYMBOL PACKAGE OVERRIDE)") (autoload 'use-package-normalize-binder "use-package-bind-key" "

(fn NAME KEYWORD ARGS)") (defalias 'use-package-normalize/:bind 'use-package-normalize-binder) (defalias 'use-package-normalize/:bind* 'use-package-normalize-binder) (defalias 'use-package-autoloads/:bind 'use-package-autoloads-mode) (defalias 'use-package-autoloads/:bind* 'use-package-autoloads-mode) (autoload 'use-package-handler/:bind "use-package-bind-key" "

(fn NAME KEYWORD ARGS REST STATE &optional BIND-MACRO)") (defalias 'use-package-normalize/:bind-keymap 'use-package-normalize-binder) (defalias 'use-package-normalize/:bind-keymap* 'use-package-normalize-binder) (autoload 'use-package-handler/:bind-keymap "use-package-bind-key" "

(fn NAME KEYWORD ARGS REST STATE &optional OVERRIDE)") (autoload 'use-package-handler/:bind-keymap* "use-package-bind-key" "

(fn NAME KEYWORD ARG REST STATE)") (register-definition-prefixes "use-package-bind-key" '("use-package-handler/:bind*")) (autoload 'use-package "use-package-core" "Declare an Emacs package by specifying a group of configuration options.

For the full documentation, see Info node `(use-package) top'.
Usage:

  (use-package package-name
     [:keyword [option]]...)

:init            Code to run before PACKAGE-NAME has been loaded.
:config          Code to run after PACKAGE-NAME has been loaded.  Note that
                 if loading is deferred for any reason, this code does not
                 execute until the lazy load has occurred.
:preface         Code to be run before everything except `:disabled'; this
                 can be used to define functions for use in `:if', or that
                 should be seen by the byte-compiler.

:mode            Form to be added to `auto-mode-alist'.
:magic           Form to be added to `magic-mode-alist'.
:magic-fallback  Form to be added to `magic-fallback-mode-alist'.
:interpreter     Form to be added to `interpreter-mode-alist'.

:commands        Define autoloads for commands defined by the package.
                 This is useful if the package is being lazily loaded,
                 and you wish to conditionally call functions in your
                 `:init' block that are defined in the package.
:autoload        Similar to `:commands', but used for non-interactive functions.
:hook            Specify hook(s) to attach this package to.

:bind            Bind keys, and define autoloads for the bound commands.
:bind*           Bind keys, and define autoloads for the bound commands,
                 *overriding all minor mode bindings*.
:bind-keymap     Bind a key prefix to an auto-loaded keymap defined in the
                 package.  This is like `:bind', but for keymaps.
:bind-keymap*    Like `:bind-keymap', but overrides all minor mode bindings

:defer           Defer loading of a package -- this is implied when using
                 `:commands', `:bind', `:bind*', `:mode', `:magic', `:hook',
                 `:magic-fallback', or `:interpreter'.  This can be an integer,
                 to force loading after N seconds of idle time, if the package
                 has not already been loaded.
:demand          Prevent the automatic deferred loading introduced by constructs
                 such as `:bind' (see `:defer' for the complete list).

:after           Delay the effect of the use-package declaration
                 until after the named libraries have loaded.
                 Before they have been loaded, no other keyword
                 has any effect at all, and once they have been
                 loaded it is as if `:after' was not specified.

:if EXPR         Initialize and load only if EXPR evaluates to a non-nil value.
:disabled        The package is ignored completely if this keyword is present.
:defines         Declare certain variables to silence the byte-compiler.
:functions       Declare certain functions to silence the byte-compiler.
:load-path       Add to the `load-path' before attempting to load the package.
:diminish        Support for diminish.el (if installed).
:delight         Support for delight.el (if installed).
:custom          Call `Custom-set' or `set-default' with each variable
                 definition without modifying the Emacs `custom-file'.
                 (compare with `custom-set-variables').
:custom-face     Call `face-spec-set' with each face definition.
:ensure          Loads the package using package.el if necessary.
:pin             Pin the package to an archive.
:vc              Install the package directly from a version control system
                 (using `package-vc.el').

(fn NAME &rest ARGS)" nil t) (function-put 'use-package 'lisp-indent-function 'defun) (register-definition-prefixes "use-package-core" '("use-package-")) (autoload 'use-package-normalize/:delight "use-package-delight" "Normalize arguments to delight.

(fn NAME KEYWORD ARGS)") (autoload 'use-package-handler/:delight "use-package-delight" "

(fn NAME KEYWORD ARGS REST STATE)") (register-definition-prefixes "use-package-delight" '("use-package-normalize-delight")) (autoload 'use-package-normalize/:diminish "use-package-diminish" "

(fn NAME KEYWORD ARGS)") (autoload 'use-package-handler/:diminish "use-package-diminish" "

(fn NAME KEYWORD ARG REST STATE)") (register-definition-prefixes "use-package-diminish" '("use-package-normalize-diminish")) (autoload 'use-package-normalize/:ensure "use-package-ensure" "

(fn NAME KEYWORD ARGS)") (autoload 'use-package-handler/:ensure "use-package-ensure" "

(fn NAME KEYWORD ENSURE REST STATE)") (register-definition-prefixes "use-package-ensure" '("use-package-")) (autoload 'use-package-normalize/:ensure-system-package "use-package-ensure-system-package" "Turn ARGS into a list of conses of the form (PACKAGE-NAME . INSTALL-COMMAND).

(fn NAME-SYMBOL KEYWORD ARGS)") (autoload 'use-package-handler/:ensure-system-package "use-package-ensure-system-package" "Execute the handler for `:ensure-system-package' keyword in `use-package'.

(fn NAME KEYWORD ARG REST STATE)") (register-definition-prefixes "use-package-ensure-system-package" '("use-package-ensure-system-package-")) (autoload 'use-package-jump-to-package-form "use-package-jump" "Attempt to find and jump to the `use-package' form that loaded PACKAGE.
This will only find the form if that form actually required
PACKAGE.  If PACKAGE was previously required then this function
will jump to the file that originally required PACKAGE instead.

(fn PACKAGE)" t) (register-definition-prefixes "use-package-jump" '("use-package-find-require")) (autoload 'use-package-lint "use-package-lint" "Check for errors in `use-package' declarations.
For example, if the module's `:if' condition is met, but even
with the specified `:load-path' the module cannot be found." t) (register-definition-prefixes "use-package-lint" '("use-package-lint-declaration")) (provide 'use-package-autoloads)) "org" ((ox-odt ob-sqlite org-indent ob-forth org-datetree ob-ditaa ob-css org-tempo ol-rmail ob-clojure ob-sql org-goto ob-lilypond oc-basic ob-java org-mouse org-element ob-ref ob-plantuml org-ctags ob-scheme ol-bbdb org-protocol org-colview ob-gnuplot ol-gnus org-refile ox-latex org-plot org-keys ob-shell ob-octave org-persist org-archive ob-ruby ox-publish ol-info ol-man org-fold ob-lisp ob-C ob-emacs-lisp ox-koma-letter ol-docview ob-tangle org ox org-footnote ob-lob org-list ob-groovy org-lint ol-irc ox-html org-clock oc org-cycle ob-ocaml ol-eshell org-inlinetask ob-lua org-loaddefs oc-csl ob-perl org-feed org-habit oc-biblatex ob-matlab org-compat ob-sass org-macro ol-mhe ob-csharp ob org-table ob-exp ob-awk ol-w3m ob-dot ob-js ob-table ol-eww ob-python org-entities ob-processing oc-natbib org-num ol-bibtex org-attach-git ox-org org-version org-macs ob-eval ox-man ob-fortran org-agenda ox-ascii ob-julia org-timer org-capture ox-beamer ob-maxima ob-R ob-screen org-src ob-latex org-id ob-eshell org-fold-core ol-doi org-mobile ox-icalendar ob-comint org-crypt org-pcomplete ox-md ol ob-haskell ob-core ob-sed ob-org org-attach ob-calc ob-makefile oc-bibtex org-faces org-duration org-element-ast ox-texinfo)) "denote" ((denote-autoloads denote \.dir-locals) (put 'denote-directory 'safe-local-variable (lambda (val) (or (stringp val) (listp val) (eq val 'local) (eq val 'default-directory)))) (put 'denote-known-keywords 'safe-local-variable #'listp) (put 'denote-infer-keywords 'safe-local-variable (lambda (val) (or val (null val)))) (autoload 'denote-sort-files "denote" "Returned sorted list of Denote FILES.

With COMPONENT as a symbol among `denote-sort-components',
sort files based on the corresponding file name component.

With COMPONENT as the symbol of a function, use it to perform the
sorting.  In this case, the function is called with two arguments, as
described by `sort'.

With COMPONENT as a nil value keep the original date-based
sorting which relies on the identifier of each file name.

With optional REVERSE as a non-nil value, reverse the sort order.

(fn FILES COMPONENT &optional REVERSE)") (autoload 'denote-sort-dired "denote" "Produce Dired buffer with sorted files from variable `denote-directory'.
When called interactively, prompt for FILES-MATCHING-REGEXP and,
depending on the value of the user option `denote-sort-dired-extra-prompts',
also prompt for SORT-BY-COMPONENT, REVERSE, and EXCLUDE-REGEXP.

1. FILES-MATCHING-REGEXP limits the list of Denote files to
   those matching the provided regular expression.

2. SORT-BY-COMPONENT sorts the files by their file name component (one
   among `denote-sort-components').  If it is nil, sorting is performed
   according to the user option `denote-sort-dired-default-sort-component',
   falling back to the identifier.

3. REVERSE is a boolean to reverse the order when it is a non-nil value.
   If `denote-sort-dired-extra-prompts' is configured to skip this
   prompt, then the sorting is done according to the user option
   `denote-sort-dired-default-reverse-sort', falling back to
   nil (i.e. no reverse sort).

4. EXCLUDE-REGEXP excludes the files that match the given regular
   expression.  This is done after FILES-MATCHING-REGEXP and
   OMIT-CURRENT have been applied.

When called from Lisp, the arguments are a string, a symbol among
`denote-sort-components', a non-nil value, and a string, respectively.

(fn FILES-MATCHING-REGEXP SORT-BY-COMPONENT REVERSE EXCLUDE-REGEXP)" t) (autoload 'denote "denote" "Create a new note with the appropriate metadata and file name.

Run the `denote-after-new-note-hook' after creating the new note and
return its path.  Before returning the path, determine what needs to be
done to the buffer, in accordance with the user option `denote-kill-buffers'.

When called interactively, the metadata and file name are prompted
according to the value of `denote-prompts'.

When called from Lisp, all arguments are optional.

- TITLE is a string or a function returning a string.

- KEYWORDS is a list of strings.  The list can be empty or the
  value can be set to nil.

- FILE-TYPE is a symbol among those described in the user option
  `denote-file-type'.

- DIRECTORY is a string representing the path to either the
  value of the variable `denote-directory' or a subdirectory
  thereof.  The subdirectory must exist: Denote will not create
  it.  If DIRECTORY does not resolve to a valid path, the first
  item in the variable `denote-directory' is used instead.

- DATE is a string representing a date like 2022-06-30 or a date
  and time like 2022-06-16 14:30.  A nil value or an empty string
  is interpreted as the `current-time'.

- IDENTIFIER is a string identifying the note.  It should have the
  format of the variable `denote-date-identifier-format', like
  20220630T1430000.

- TEMPLATE is a symbol which represents the key of a cons cell in
  the user option `denote-templates'.  The value of that key is
  inserted to the newly created buffer after the front matter.

- SIGNATURE is a string.

(fn &optional TITLE KEYWORDS FILE-TYPE DIRECTORY DATE TEMPLATE SIGNATURE IDENTIFIER)" t) (autoload 'denote-type "denote" "Create note while prompting for a file type.

This is the equivalent of calling `denote' when `denote-prompts'
has the `file-type' prompt appended to its existing prompts." t) (function-put 'denote-type 'interactive-only 't) (autoload 'denote-date "denote" "Create note while prompting for a date.

The date can be in YEAR-MONTH-DAY notation like 2022-06-30 or
that plus the time: 2022-06-16 14:30.  When the user option
`denote-date-prompt-use-org-read-date' is non-nil, the date
prompt uses the more powerful Org+calendar system.

This is the equivalent of calling `denote' when `denote-prompts'
has the `date' prompt appended to its existing prompts." t) (function-put 'denote-date 'interactive-only 't) (autoload 'denote-subdirectory "denote" "Create note while prompting for a subdirectory.

Available candidates include the value of the variable
`denote-directory' and any subdirectory thereof.

This is the equivalent of calling `denote' when `denote-prompts'
has the `subdirectory' prompt appended to its existing prompts." t) (function-put 'denote-subdirectory 'interactive-only 't) (autoload 'denote-template "denote" "Create note while prompting for a template.

Available candidates include the keys in the `denote-templates'
alist.  The value of the selected key is inserted in the newly
created note after the front matter.

This is the equivalent of calling `denote' when `denote-prompts'
has the `template' prompt appended to its existing prompts." t) (function-put 'denote-template 'interactive-only 't) (autoload 'denote-signature "denote" "Create note while prompting for a file signature.

This is the equivalent of calling `denote' when `denote-prompts'
has the `signature' prompt appended to its existing prompts." t) (function-put 'denote-signature 'interactive-only 't) (autoload 'denote-region "denote" "Call `denote' and insert therein the text of the active region.

Note that, currently, `denote-save-buffers' and
`denote-kill-buffers' are NOT respected.  The buffer is not
saved or killed at the end of `denote-region'." t) (function-put 'denote-region 'interactive-only 't) (autoload 'denote-open-or-create "denote" "Visit TARGET file in variable `denote-directory'.
If file does not exist, invoke `denote' to create a file.  In that case,
use the last input at the file prompt as the default value of the title
prompt.

(fn TARGET)" t) (autoload 'denote-open-or-create-with-command "denote" "Like `denote-open-or-create' but use one of the `denote-commands-for-new-notes'." t) (function-put 'denote-open-or-create-with-command 'interactive-only 't) (autoload 'denote-rename-file "denote" "Rename file and update existing front matter if appropriate.

Always rename the file where it is located in the file system:
never move it to another directory.

If in Dired, consider FILE to be the one at point, else the
current file, else prompt with minibuffer completion for one.
When called from Lisp, FILE is a file system path represented as
a string.

If FILE has a Denote-compliant identifier, retain it while
updating components of the file name referenced by the user
option `denote-prompts'.  By default, these are the TITLE and
KEYWORDS.  The SIGNATURE is another one.  When called from Lisp,
TITLE and SIGNATURE are strings, while KEYWORDS is a list of
strings.

The IDENTIFIER is a string that has the format of variable
`denote-date-identifier-format'.

If there is no identifier, create a new identifier using
`denote-get-identifier-function'.  By default, it creates a new
identifier using the date parameter, the date of last modification or
the `current-time'.

In interactive use, and assuming `denote-prompts' includes a
title entry, make the TITLE prompt have prefilled text in the
minibuffer that consists of the current title of FILE.  The
current title is either retrieved from the front matter (such as
the #+title in Org) or from the file name.

Do the same for the SIGNATURE prompt, subject to `denote-prompts',
by prefilling the minibuffer with the current signature of FILE,
if any.

Same principle for the KEYWORDS prompt: convert the keywords in
the file name into a comma-separated string and prefill the
minibuffer with it (the KEYWORDS prompt accepts more than one
keywords, each separated by a comma, else the `crm-separator').

For all prompts, interpret an empty input as an instruction to
remove that file name component.  For example, if a TITLE prompt
is available and FILE is 20240211T093531--some-title__keyword1.org
then rename FILE to 20240211T093531__keyword1.org.

In interactive use, if there is no entry for a file name
component in `denote-prompts', keep it as-is.

When called from Lisp, the special symbol `keep-current' can be
used for the TITLE, KEYWORDS, SIGNATURE, DATE, and IDENTIFIER
parameters to keep them as-is.

[ NOTE: Please check with your minibuffer user interface how to
  provide an empty input.  The Emacs default setup accepts the
  empty minibuffer contents as they are, though popular packages
  like `vertico' use the first available completion candidate
  instead.  For `vertico', the user must either move one up to
  select the prompt and then type RET there with empty contents,
  or use the command `vertico-exit-input' with empty contents.
  That Vertico command is bound to M-RET as of this writing on
  2024-02-13 08:08 +0200. ]

As a final step, ask for confirmation, showing the difference
between old and new file names.  Do not ask for confirmation if
the user option `denote-rename-confirmations' does not contain
the symbol `modify-file-name'.

If FILE has front matter for TITLE and KEYWORDS, ask to rewrite
their values in order to reflect the new input, unless
`denote-rename-confirmations' lacks `rewrite-front-matter'.  When
the `denote-save-buffers' is nil (the default), do not save the
underlying buffer, thus giving the user the option to
double-check the result, such as by invoking the command
`diff-buffer-with-file'.  The rewrite of the TITLE and KEYWORDS
in the front matter should not affect the rest of the front
matter.

If the file does not have front matter but is among the supported file
types (per the user option `denote-file-type'), add front matter to the
top of it and leave the buffer unsaved for further inspection.  Save the
buffer if `denote-save-buffers' is non-nil.

When `denote-kill-buffers' is t or `on-rename', kill the buffer
if it was not already being visited before the rename operation.

For the front matter of each file type, refer to the variables:

- `denote-org-front-matter'
- `denote-text-front-matter'
- `denote-toml-front-matter'
- `denote-yaml-front-matter'

Construct the file name in accordance with the user option
`denote-file-name-components-order'.

Run the `denote-after-rename-file-hook' after renaming FILE.

This command is intended to (i) rename Denote files, (ii) convert
existing supported file types to Denote notes, and (ii) rename
non-note files (e.g. PDF) that can benefit from Denote's
file-naming scheme.

For a version of this command that works with multiple files
one-by-one, use `denote-dired-rename-files'.

(fn FILE TITLE KEYWORDS SIGNATURE DATE IDENTIFIER)" t) (autoload 'denote-dired-rename-files "denote" "Rename Dired marked files same way as `denote-rename-file'.
Rename each file in sequence, making all the relevant prompts.
Unlike `denote-rename-file', do not prompt for confirmation of
the changes made to the file: perform them outright (same as
setting `denote-rename-confirmations' to a nil value)." '(dired-mode)) (function-put 'denote-dired-rename-files 'interactive-only 't) (autoload 'denote-dired-rename-marked-files-with-keywords "denote" "Rename marked files in Dired to a Denote file name by writing keywords.

Specifically, do the following:

- retain the file's existing name and make it the TITLE field,
  per Denote's file-naming scheme;

- sluggify the TITLE, according to our conventions (check the
  user option `denote-file-name-slug-functions');

- prepend an identifier to the TITLE;

- preserve the file's extension, if any;

- prompt once for KEYWORDS and apply the user's input to the
  corresponding field in the file name, rewriting any keywords
  that may exist while removing keywords that do exist if
  KEYWORDS is empty;

- add or rewrite existing front matter to the underlying file, if it is
  recognized as a Denote note (per the user option `denote-file-type'),
  such that it includes the new keywords.

Construct the file name in accordance with the user option
`denote-file-name-components-order'.

Run the `denote-after-rename-file-hook' after renaming is done.

Also see the specialized commands to only add or remove keywords:

- `denote-dired-rename-marked-files-add-keywords'.
- `denote-dired-rename-marked-files-remove-keywords'." '(dired-mode)) (function-put 'denote-dired-rename-marked-files-with-keywords 'interactive-only 't) (autoload 'denote-dired-rename-marked-files-add-keywords "denote" "Like `denote-dired-rename-marked-files-with-keywords' to only add keywords." '(dired-mode)) (function-put 'denote-dired-rename-marked-files-add-keywords 'interactive-only 't) (autoload 'denote-dired-rename-marked-files-remove-keywords "denote" "Like `denote-dired-rename-marked-files-with-keywords' to only remove keywords." '(dired-mode)) (function-put 'denote-dired-rename-marked-files-remove-keywords 'interactive-only 't) (autoload 'denote-rename-file-using-front-matter "denote" "Rename FILE using its front matter as input.
When called interactively, FILE is the variable `buffer-file-name' or
the Dired file at point, which is subsequently inspected for the
requisite front matter.  It is thus implied that the FILE has a file
type that is supported by Denote, per the user option `denote-file-type'.

The values of `denote-rename-confirmations',
`denote-save-buffers' and `denote-kill-buffers' are respected.

Only the front matter lines that appear in the front matter template (as
defined in `denote-file-types') will be handled.

To change the identifier (date) of the note with this command, the
identifier line (if present) of the front matter must be modified.
Modifying the date line has no effect.

While this command generally does not modify the front matter, there are
exceptions.  The value of the `date' line will follow that of the
`identifier' line.  If they are both in the front matter template and
the `date' line is missing, it will be added again.  Similarly, if they
are both in the front matter template and the `date' line is present and
the `identifier' line has been removed, the `date' line will be removed
as well.  Also, if the keywords are out of order and
`denote-sort-keywords' is non-nil, they will be sorted.  There will be a
prompt for this if `denote-rename-confirmations' contains
`rewrite-front-matter'.

Construct the file name in accordance with the user option
`denote-file-name-components-order'.

(fn FILE)" t) (autoload 'denote-dired-rename-marked-files-using-front-matter "denote" "Call `denote-rename-file-using-front-matter' over the Dired marked files.
Refer to the documentation of that command for the technicalities.

Marked files must count as notes for the purposes of Denote, which means
that they at least have an identifier in their file name and use a
supported file type, per the user option `denote-file-type'.  Files that
do not meet this criterion are ignored because Denote cannot know if
they have front matter and what that may be." '(dired-mode)) (autoload 'denote-change-file-type-and-front-matter "denote" "Change file type of FILE and add an appropriate front matter.

If in Dired, consider FILE to be the one at point, else the
current file, else prompt with minibuffer completion for one.

Add a front matter in the format of the NEW-FILE-TYPE at the
beginning of the file.

Retrieve the title of FILE from a line starting with a title
field in its front matter, depending on the previous file
type (e.g.  #+title for Org).  The same process applies for
keywords.

As a final step, ask for confirmation, showing the difference
between old and new file names.

Important note: No attempt is made to modify any other elements
of the file.  This needs to be done manually.

Construct the file name in accordance with the user option
`denote-file-name-components-order'.

(fn FILE NEW-FILE-TYPE)" t) (autoload 'denote-dired-mode "denote" "Fontify all Denote-style file names.

Add this or `denote-dired-mode-in-directories' to
`dired-mode-hook'.

This is a minor mode.  If called interactively, toggle the `Denote-Dired
mode' mode.  If the prefix argument is positive, enable the mode, and if
it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate the variable `denote-dired-mode'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (autoload 'denote-dired-mode-in-directories "denote" "Enable `denote-dired-mode' in `denote-dired-directories'.
Add this function to `dired-mode-hook'.

If `denote-dired-directories-include-subdirectories' is non-nil,
also enable it in all subdirectories.") (autoload 'denote-link "denote" "Create link to FILE note in variable `denote-directory' with DESCRIPTION.

When called interactively, prompt for FILE using completion.  In this
case, derive FILE-TYPE from the current buffer.  FILE-TYPE is used to
determine the format of the link.

Return the DESCRIPTION of the link in the format specified by
`denote-link-description-format'.  The default is to return the text of
the active region or the title of the note (plus the signature if
present).

With optional ID-ONLY as a non-nil argument, such as with a universal
prefix (\\[universal-argument]), insert links with just the identifier
and no further description.  In this case, the link format is always
[[denote:IDENTIFIER]].

If the DESCRIPTION is empty, format the link the same as with ID-ONLY.

When called from Lisp, FILE is a string representing a full file system
path.  FILE-TYPE is a symbol as described in the user option
`denote-file-type'.  DESCRIPTION is a string.  Whether the caller treats
the active region specially, is up to it.

(fn FILE FILE-TYPE DESCRIPTION &optional ID-ONLY)" t) (autoload 'denote-find-link "denote" "Use minibuffer completion to visit linked file.
Also see `denote-find-backlink'." t) (function-put 'denote-find-link 'interactive-only 't) (autoload 'denote-link-after-creating "denote" "Create new note in the background and link to it directly.

Use `denote' interactively to produce the new note.  Its doc
string explains which prompts will be used and under what
conditions.

With optional ID-ONLY as a prefix argument create a link that
consists of just the identifier.  Else try to also include the
file's title.  This has the same meaning as in `denote-link'.

For a variant of this, see `denote-link-after-creating-with-command'.

IMPORTANT NOTE: Normally, `denote' does not save the buffer it
produces for the new note.  This is a safety precaution to not
write to disk unless the user wants it (e.g. the user may choose
to kill the buffer, thus cancelling the creation of the note).
However, for this command the creation of the note happens in the
background and the user may miss the step of saving their buffer.
We thus have to save the buffer in order to (i) establish valid
links, and (ii) retrieve whatever front matter from the target
file.  Though see `denote-save-buffer-after-creation'.

(fn &optional ID-ONLY)" t) (autoload 'denote-link-after-creating-with-command "denote" "Like `denote-link-after-creating' but prompt for note-making COMMAND.
Use this to, for example, call `denote-signature' so that the
newly created note has a signature as part of its file name.

Optional ID-ONLY has the same meaning as in the command
`denote-link-after-creating'.

(fn COMMAND &optional ID-ONLY)" t) (autoload 'denote-link-or-create "denote" "Use `denote-link' on TARGET file, creating it if necessary.

If TARGET file does not exist, call `denote-link-after-creating' which
runs the `denote' command interactively to create the file.  The
established link will then be targeting that new file.  In that case,
use the last input at the file prompt as the default value of the title
prompt.

With optional ID-ONLY as a prefix argument create a link that
consists of just the identifier.  Else try to also include the
file's title.  This has the same meaning as in `denote-link'.

(fn TARGET &optional ID-ONLY)" t) (autoload 'denote-grep "denote" "Search QUERY in the content of Denote files.
QUERY should be a regular expression accepted by `xref-search-program'.

The files to search for are those returned by `denote-directory-files'
with a non-nil TEXT-ONLY argument.

Results are put in a buffer which allows folding and further
filtering (see the manual for details).

You can insert a link to a grep search in any note by using the command
`denote-query-contents-link'.

(fn QUERY)" t) (autoload 'denote-grep-marked-dired-files "denote" "Do the equivalent of `denote-grep' for QUERY in marked Dired files.

(fn QUERY)" t) (autoload 'denote-grep-files-referenced-in-region "denote" "Perform `denote-grep' QUERY in files referenced between START and END.
When called interactively, prompt for QUERY.  Also get START and END as
the buffer positions that delimit the marked region.  When called from
Lisp, QUERY is a string, while START and END are buffer positions, as
integers.

Find references to files by their identifier.  This includes links with
just the identifier (as described in `denote-link' and related), links
written by an Org dynamic block (see the `denote-org' package), or even
file listings such as those of `dired' and the command-line `ls' program.

(fn QUERY START END)" t) (autoload 'denote-backlinks "denote" "Produce a buffer with backlinks to the current note.

Show the names of files linking to the current file.

Place the buffer below the current window or wherever the user option
`denote-backlinks-display-buffer-action' specifies." t) (autoload 'denote-find-backlink "denote" "Use minibuffer completion to visit backlink to current file.
Visit the file itself, not the location where the link is.  For a
context-sensitive operation, use `denote-find-backlink-with-location'.

Alo see `denote-find-link'." t) (function-put 'denote-find-backlink 'interactive-only 't) (autoload 'denote-find-backlink-with-location "denote" "Like `denote-find-backlink' but jump to the exact location of the link." t) (function-put 'denote-find-backlink-with-location 'interactive-only 't) (autoload 'denote-query-contents-link "denote" "Insert query link for file contents.
Prompt for QUERY or use the text of the active region.  When the user
follows this link, place any matches in a separate buffer (using the
built-in Xref mechanism).  This is the equivalent of a Unix grep command
across the variable `denote-directory'.

(fn QUERY)" t) (autoload 'denote-query-filenames-link "denote" "Insert query link for file names.
Prompt for QUERY or use the text of the active region.  When the user
follows this link, place any matches in a separate buffer (using the
built-in Dired mechanism).  This is the equivalent of a Unix find
command across the variable `denote-directory'.

(fn QUERY)" t) (autoload 'denote-fontify-links-mode-maybe "denote" "Enable `denote-fontify-links-mode' in a denote file unless in `org-mode'.") (autoload 'denote-fontify-links-mode "denote" "A minor mode to fontify and fold Denote links.

Enabled this mode only when the current buffer is a Denote note and the
major mode is not `org-mode' (or derived therefrom).  Consider using
`denote-fontify-links-mode-maybe' for this purpose.

This is a minor mode.  If called interactively, toggle the
`Denote-Fontify-Links mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate the variable `denote-fontify-links-mode'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (autoload 'denote-add-links "denote" "Insert links to all files whose file names match REGEXP.
Use this command to reference multiple files at once.  Particularly
useful for the creation of metanotes (read the manual for more on the
matter).

Optional ID-ONLY has the same meaning as in `denote-link': it
inserts links with just the identifier.

(fn REGEXP &optional ID-ONLY)" t) (autoload 'denote-link-to-file-with-contents "denote" "Link to a file whose contents match QUERY.
This is similar to `denote-link', except that the file prompt is limited
to files matching QUERY.  Optional ID-ONLY has the same meaning as in
`denote-link'.

(fn QUERY &optional ID-ONLY)" t) (autoload 'denote-link-to-all-files-with-contents "denote" "Link to all files whose contents match QUERY.
This is similar to `denote-add-links', except it searches inside file
contents, not file names.  Optional ID-ONLY has the same meaning as in
`denote-link' and `denote-add-links'.

(fn QUERY &optional ID-ONLY)" t) (autoload 'denote-link-dired-marked-notes "denote" "Insert Dired marked FILES as links in BUFFER.

FILES conform with the Denote file-naming scheme, such that they can be
linked to using the `denote:' link type.

The BUFFER is one which visits a Denote note file.  If there are
multiple BUFFER candidates in buffers, prompt with completion for
one among them.  If there is none, throw an error.

With optional ID-ONLY as a prefix argument, insert links with
just the identifier (same principle as with `denote-link').

This command is meant to be used from a Dired buffer.

(fn FILES BUFFER &optional ID-ONLY)" '(dired-mode)) (defvar denote-menu-bar-mode t "Non-nil if Denote-Menu-Bar mode is enabled.
See the `denote-menu-bar-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `denote-menu-bar-mode'.") (custom-autoload 'denote-menu-bar-mode "denote" nil) (autoload 'denote-menu-bar-mode "denote" "Show Denote menu bar.

This is a global minor mode.  If called interactively, toggle the
`Denote-Menu-Bar mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='denote-menu-bar-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (autoload 'denote-link-ol-follow "denote" "Find file of type `denote:' matching LINK.
LINK is the identifier of the note, optionally followed by a file search
option akin to that of standard Org `file:' link types.  Read Info
node `(org) Query Options'.

If LINK is not an identifier, then it is not pointing to a file but to a
query of file contents or file names (see the commands
`denote-query-contents-link' and `denote-query-filenames-link').

Uses the function `denote-directory' to establish the path to the file.

(fn LINK)") (autoload 'denote-link-ol-complete "denote" "Like `denote-link' but for Org integration.
This lets the user complete a link through the `org-insert-link'
interface by first selecting the `denote:' hyperlink type.") (autoload 'denote-link-ol-store "denote" "Handler for `org-store-link' adding support for denote: links.
Optional INTERACTIVE? is used by `org-store-link'.

Also see the user option `denote-org-store-link-to-heading'.

(fn &optional INTERACTIVE?)") (autoload 'denote-link-ol-export "denote" "Export a `denote:' link from Org files.
The LINK, DESCRIPTION, and FORMAT are handled by the export
backend.

(fn LINK DESCRIPTION FORMAT)") (eval-after-load 'org `(funcall ',(lambda nil (with-no-warnings (org-link-set-parameters "denote" :follow #'denote-link-ol-follow :face #'denote-get-link-face :help-echo #'denote-link-ol-help-echo :complete #'denote-link-ol-complete :store #'denote-link-ol-store :export #'denote-link-ol-export))))) (autoload 'denote-org-capture "denote" "Create new note through `org-capture-templates'.
Use this as a function that returns the path to the new file.
The file is populated with Denote's front matter.  It can then be
expanded with the usual specifiers or strings that
`org-capture-templates' supports.

This function obeys `denote-prompts', but it ignores `file-type',
if present: it always sets the Org file extension for the created
note to ensure that the capture process works as intended,
especially for the desired output of the
`denote-org-capture-specifiers' (which can include arbitrary
text).

Consult the manual for template samples.") (autoload 'denote-org-capture-with-prompts "denote" "Like `denote-org-capture' but with optional prompt parameters.

When called without arguments, do not prompt for anything.  Just
return the front matter with title and keyword fields empty and
the date and identifier fields specified.  Also make the file
name consist of only the identifier plus the Org file name
extension.

Otherwise produce a minibuffer prompt for every non-nil value
that corresponds to the TITLE, KEYWORDS, SUBDIRECTORY, DATE, and
TEMPLATE arguments.  The prompts are those used by the standard
`denote' command and all of its utility commands.

When returning the contents that fill in the Org capture
template, the sequence is as follows: front matter, TEMPLATE, and
then the value of the user option `denote-org-capture-specifiers'.

Important note: in the case of SUBDIRECTORY actual subdirectories
must exist---Denote does not create them.  Same principle for
TEMPLATE as templates must exist and are specified in the user
option `denote-templates'.

(fn &optional TITLE KEYWORDS SUBDIRECTORY DATE TEMPLATE)") (defvar denote-rename-buffer-mode nil "Non-nil if Denote-Rename-Buffer mode is enabled.
See the `denote-rename-buffer-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `denote-rename-buffer-mode'.") (custom-autoload 'denote-rename-buffer-mode "denote" nil) (autoload 'denote-rename-buffer-mode "denote" "Automatically rename Denote buffers to be easier to read.

A buffer is renamed upon visiting the underlying file.  This
means that existing buffers are not renamed until they are
visited again in a new buffer (files are visited with the command
`find-file' or related).

This is a global minor mode.  If called interactively, toggle the
`Denote-Rename-Buffer mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='denote-rename-buffer-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (register-definition-prefixes "denote" '("denote-")) (provide 'denote-autoloads)) "dash" ((dash-autoloads dash) (autoload 'dash-fontify-mode "dash" "Toggle fontification of Dash special variables.

Dash-Fontify mode is a buffer-local minor mode intended for Emacs
Lisp buffers.  Enabling it causes the special variables bound in
anaphoric Dash macros to be fontified.  These anaphoras include
`it', `it-index', `acc', and `other'.  In older Emacs versions
which do not dynamically detect macros, Dash-Fontify mode
additionally fontifies Dash macro calls.

See also `dash-fontify-mode-lighter' and
`global-dash-fontify-mode'.

This is a minor mode.  If called interactively, toggle the `Dash-Fontify
mode' mode.  If the prefix argument is positive, enable the mode, and if
it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate the variable `dash-fontify-mode'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (put 'global-dash-fontify-mode 'globalized-minor-mode t) (defvar global-dash-fontify-mode nil "Non-nil if Global Dash-Fontify mode is enabled.
See the `global-dash-fontify-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-dash-fontify-mode'.") (custom-autoload 'global-dash-fontify-mode "dash" nil) (autoload 'global-dash-fontify-mode "dash" "Toggle Dash-Fontify mode in all buffers.
With prefix ARG, enable Global Dash-Fontify mode if ARG is positive;
otherwise, disable it.

If called from Lisp, toggle the mode if ARG is `toggle'.
Enable the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

Dash-Fontify mode is enabled in all buffers where
`dash--turn-on-fontify-mode' would do it.

See `dash-fontify-mode' for more information on Dash-Fontify mode.

(fn &optional ARG)" t) (autoload 'dash-register-info-lookup "dash" "Register the Dash Info manual with `info-lookup-symbol'.
This allows Dash symbols to be looked up with \\[info-lookup-symbol]." t) (register-definition-prefixes "dash" '("!cdr" "!cons" "--" "->" "-a" "-butlast" "-c" "-d" "-e" "-f" "-gr" "-i" "-juxt" "-keep" "-l" "-m" "-no" "-o" "-p" "-r" "-s" "-t" "-u" "-value-to-list" "-when-let" "-zip" "dash-")) (provide 'dash-autoloads)) "emacsql" ((emacsql-sqlite emacsql-sqlite-module emacsql-sqlite-builtin emacsql-mysql emacsql-psql emacsql emacsql-pg emacsql-autoloads emacsql-compiler) (autoload 'emacsql-show-last-sql "emacsql" "Display the compiled SQL of the s-expression SQL expression before point.
A prefix argument causes the SQL to be printed into the current buffer.

(fn &optional PREFIX)" t) (register-definition-prefixes "emacsql" '("emacsql-")) (register-definition-prefixes "emacsql-compiler" '("emacsql-")) (register-definition-prefixes "emacsql-mysql" '("emacsql-mysql-")) (register-definition-prefixes "emacsql-pg" '("emacsql-pg-connection")) (register-definition-prefixes "emacsql-psql" '("emacsql-psql-")) (register-definition-prefixes "emacsql-sqlite" '("emacsql-")) (register-definition-prefixes "emacsql-sqlite-builtin" '("emacsql-sqlite-builtin-connection")) (register-definition-prefixes "emacsql-sqlite-module" '("emacsql-sqlite-module-connection")) (provide 'emacsql-autoloads)) "seq" ((seq-pkg seq-25 seq-24 seq-autoloads seq) (register-definition-prefixes "seq-24" '("seq")) (autoload 'seq-subseq "seq-25" "Return the sequence of elements of SEQUENCE from START to END.
END is exclusive.

If END is omitted, it defaults to the length of the sequence.  If
START or END is negative, it counts from the end.  Signal an
error if START or END are outside of the sequence (i.e too large
if positive or too small if negative).

(fn SEQUENCE START &optional END)") (autoload 'seq-take "seq-25" "Return the sequence made of the first N elements of SEQUENCE.
The result is a sequence of the same type as SEQUENCE.

If N is a negative integer or zero, an empty sequence is
returned.

(fn SEQUENCE N)") (autoload 'seq-sort-by "seq-25" "Sort SEQUENCE transformed by FUNCTION using PRED as the comparison function.
Elements of SEQUENCE are transformed by FUNCTION before being
sorted.  FUNCTION must be a function of one argument.

(fn FUNCTION PRED SEQUENCE)") (autoload 'seq-filter "seq-25" "Return a list of all the elements in SEQUENCE for which PRED returns non-nil.

(fn PRED SEQUENCE)") (autoload 'seq-remove "seq-25" "Return a list of all the elements in SEQUENCE for which PRED returns nil.

(fn PRED SEQUENCE)") (autoload 'seq-remove-at-position "seq-25" "Return a copy of SEQUENCE with the element at index N removed.

N is the (zero-based) index of the element that should not be in
the result.

The result is a sequence of the same type as SEQUENCE.

(fn SEQUENCE N)") (autoload 'seq-reduce "seq-25" "Reduce the function FUNCTION across SEQUENCE, starting with INITIAL-VALUE.

Return the result of calling FUNCTION with INITIAL-VALUE and the
first element of SEQUENCE, then calling FUNCTION with that result
and the second element of SEQUENCE, then with that result and the
third element of SEQUENCE, etc.  FUNCTION will be called with
INITIAL-VALUE (and then the accumulated value) as the first
argument, and the elements from SEQUENCE as the second argument.

If SEQUENCE is empty, return INITIAL-VALUE and FUNCTION is not called.

(fn FUNCTION SEQUENCE INITIAL-VALUE)") (autoload 'seq-every-p "seq-25" "Return non-nil if PRED returns non-nil for all the elements of SEQUENCE.

(fn PRED SEQUENCE)") (autoload 'seq-some "seq-25" "Return non-nil if PRED returns non-nil for at least one element of SEQUENCE.
If the value is non-nil, it is the first non-nil value returned by PRED.

(fn PRED SEQUENCE)") (autoload 'seq-find "seq-25" "Return the first element in SEQUENCE for which PRED returns non-nil.
If no such element is found, return DEFAULT.

Note that `seq-find' has an ambiguity if the found element is
identical to DEFAULT, as in that case it is impossible to know
whether an element was found or not.

(fn PRED SEQUENCE &optional DEFAULT)") (autoload 'seq-position "seq-25" "Return the (zero-based) index of the first element in SEQUENCE \"equal\" to ELT.
\"Equality\" is defined by the function TESTFN, which defaults to `equal'.

(fn SEQUENCE ELT &optional TESTFN)") (autoload 'seq-positions "seq-25" "Return list of indices of SEQUENCE elements for which TESTFN returns non-nil.

TESTFN is a two-argument function which is called with each element of
SEQUENCE as the first argument and ELT as the second.
TESTFN defaults to `equal'.

The result is a list of (zero-based) indices.

(fn SEQUENCE ELT &optional TESTFN)") (autoload 'seq-uniq "seq-25" "Return a list of the elements of SEQUENCE with duplicates removed.
TESTFN is used to compare elements, and defaults to `equal'.

(fn SEQUENCE &optional TESTFN)") (autoload 'seq-union "seq-25" "Return a list of all the elements that appear in either SEQUENCE1 or SEQUENCE2.
\"Equality\" of elements is defined by the function TESTFN, which
defaults to `equal'.

(fn SEQUENCE1 SEQUENCE2 &optional TESTFN)") (autoload 'seq-intersection "seq-25" "Return a list of all the elements that appear in both SEQUENCE1 and SEQUENCE2.
\"Equality\" of elements is defined by the function TESTFN, which
defaults to `equal'.

(fn SEQUENCE1 SEQUENCE2 &optional TESTFN)") (autoload 'seq-group-by "seq-25" "Apply FUNCTION to each element of SEQUENCE.
Separate the elements of SEQUENCE into an alist using the results as
keys.  Keys are compared using `equal'.

(fn FUNCTION SEQUENCE)") (autoload 'seq-max "seq-25" "Return the largest element of SEQUENCE.
SEQUENCE must be a sequence of numbers or markers.

(fn SEQUENCE)") (autoload 'seq-random-elt "seq-25" "Return a randomly chosen element from SEQUENCE.
Signal an error if SEQUENCE is empty.

(fn SEQUENCE)") (register-definition-prefixes "seq-25" '("seq-")) (provide 'seq-autoloads)) "compat" ((compat-28 compat-27 compat-25 compat-29 compat-30 compat-26 compat-autoloads compat compat-pkg compat-macs) (register-definition-prefixes "compat" '("compat-")) (register-definition-prefixes "compat-macs" '("compat-")) (provide 'compat-autoloads)) "cond-let" ((cond-let-autoloads cond-let) (register-definition-prefixes "cond-let" '("cond-let")) (provide 'cond-let-autoloads)) "llama" ((llama-autoloads \.dir-locals llama) (autoload 'llama "llama" "Expand to a `lambda' expression that wraps around FN and BODY.

This macro provides a compact way to write short `lambda' expressions.
It expands to a `lambda' expression, which calls the function FN with
arguments BODY and returns its value.  The arguments of the `lambda'
expression are derived from symbols found in BODY.

Each symbol from `%1' through `%9', which appears in an unquoted part
of BODY, specifies a mandatory argument.  Each symbol from `&1' through
`&9', which appears in an unquoted part of BODY, specifies an optional
argument.  The symbol `&*' specifies extra (`&rest') arguments.

The shorter symbol `%' can be used instead of `%1', but using both in
the same expression is not allowed.  Likewise `&' can be used instead
of `&1'.  These shorthands are not recognized in function position.

To support binding forms that use a vector as VARLIST (such as `-let'
from the `dash' package), argument symbols are also detected inside of
vectors.

The space between `##' and FN can be omitted because `##' is read-syntax
for the symbol whose name is the empty string.  If you prefer you can
place a space there anyway, and if you prefer to not use this somewhat
magical symbol at all, you can instead use the alternative name `llama'.

Instead of:

  (lambda (a &optional _ c &rest d)
    (foo a (bar c) d))

you can use this macro and write:

  (##foo %1 (bar &3) &*)

which expands to:

  (lambda (%1 &optional _&2 &3 &rest &*)
    (foo %1 (bar &3) &*))

Unused trailing arguments and mandatory unused arguments at the border
between mandatory and optional arguments are also supported:

  (##list %1 _%3 &5 _&6)

becomes:

  (lambda (%1 _%2 _%3 &optional _&4 &5 _&6)
    (list %1 &5))

Note how `_%3' and `_&6' are removed from the body, because their names
begin with an underscore.  Also note that `_&4' is optional, unlike the
explicitly specified `_%3'.

Consider enabling `llama-fontify-mode' to highlight `##' and its
special arguments.

(fn FN &rest BODY)" nil t) (defvar llama-fontify-mode nil "Non-nil if Llama-Fontify mode is enabled.
See the `llama-fontify-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `llama-fontify-mode'.") (custom-autoload 'llama-fontify-mode "llama" nil) (autoload 'llama-fontify-mode "llama" "In Emacs Lisp mode, highlight the `##' macro and its special arguments.

This is a global minor mode.  If called interactively, toggle the
`Llama-Fontify mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='llama-fontify-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (register-definition-prefixes "llama" '("##" "all-completions" "elisp-" "intern" "lisp--el-match-keyword@llama" "llama-")) (provide 'llama-autoloads)) "magit-section" ((magit-section magit-section-autoloads) (autoload 'magit-add-section-hook "magit-section" "Add to the value of section hook HOOK the function FUNCTION.

Add FUNCTION at the beginning of the hook list unless optional
APPEND is non-nil, in which case FUNCTION is added at the end.
If FUNCTION already is a member, then move it to the new location.

If optional AT is non-nil and a member of the hook list, then
add FUNCTION next to that instead.  Add before or after AT, or
replace AT with FUNCTION depending on APPEND.  If APPEND is the
symbol `replace', then replace AT with FUNCTION.  For any other
non-nil value place FUNCTION right after AT.  If nil, then place
FUNCTION right before AT.  If FUNCTION already is a member of the
list but AT is not, then leave FUNCTION where ever it already is.

If optional LOCAL is non-nil, then modify the hook's buffer-local
value rather than its global value.  This makes the hook local by
copying the default value.  That copy is then modified.

HOOK should be a symbol.  If HOOK is void, it is first set to nil.
HOOK's value must not be a single hook function.  FUNCTION should
be a function that takes no arguments and inserts one or multiple
sections at point, moving point forward.  FUNCTION may choose not
to insert its section(s), when doing so would not make sense.  It
should not be abused for other side-effects.  To remove FUNCTION
again use `remove-hook'.

(fn HOOK FUNCTION &optional AT APPEND LOCAL)") (autoload 'magit--handle-bookmark "magit-section" "Open a bookmark created by `magit--make-bookmark'.

Call the generic function `magit-bookmark-get-buffer-create' to get
the appropriate buffer without displaying it.

Then call the `magit-*-setup-buffer' function of the the major-mode
with the variables' values as arguments, which were recorded by
`magit--make-bookmark'.

(fn BOOKMARK)") (register-definition-prefixes "magit-section" '("context-menu-region" "isearch-clean-overlays" "magit-")) (provide 'magit-section-autoloads)) "org-roam" ((org-roam-db org-roam-log org-roam-protocol org-roam-mode org-roam-graph org-roam-overlay org-roam-compat org-roam-dailies org-roam-utils org-roam-migrate org-roam-node org-roam-autoloads org-roam-capture org-roam org-roam-id org-roam-export) (autoload 'org-roam-list-files "org-roam" "Return a list of all Org-roam files under `org-roam-directory'.
See `org-roam-file-p' for how each file is determined to be as
part of Org-Roam.") (register-definition-prefixes "org-roam" '("org-roam-")) (autoload 'org-roam-capture- "org-roam-capture" "Main entry point of `org-roam-capture' module.
GOTO and KEYS correspond to `org-capture' arguments.
INFO is a plist for filling up Org-roam's capture templates.
NODE is an `org-roam-node' construct containing information about the node.
PROPS is a plist containing additional Org-roam properties for each template.
TEMPLATES is a list of org-roam templates.

(fn &key GOTO KEYS NODE INFO PROPS TEMPLATES)") (autoload 'org-roam-capture "org-roam-capture" "Launches an `org-capture' process for a new or existing node.
This uses the templates defined at `org-roam-capture-templates'.
Arguments GOTO and KEYS see `org-capture'.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.
The TEMPLATES, if provided, override the list of capture templates (see
`org-roam-capture-'.)
The INFO, if provided, is passed along to the underlying `org-roam-capture-'.

(fn &optional GOTO KEYS &key FILTER-FN TEMPLATES INFO)" t) (register-definition-prefixes "org-roam-capture" '("org-roam-capture-")) (register-definition-prefixes "org-roam-compat" '("org-roam--")) (autoload 'org-roam-dailies-capture-today "org-roam-dailies" "Create an entry in the daily-note for today.
When GOTO is non-nil, go the note without creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn &optional GOTO KEYS)" t) (autoload 'org-roam-dailies-goto-today "org-roam-dailies" "Find the daily-note for today, creating it if necessary.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn &optional KEYS)" t) (autoload 'org-roam-dailies-capture-tomorrow "org-roam-dailies" "Create an entry in the daily-note for tomorrow.

With numeric argument N, use the daily-note N days in the future.

With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn N &optional GOTO KEYS)" t) (autoload 'org-roam-dailies-goto-tomorrow "org-roam-dailies" "Find the daily-note for tomorrow, creating it if necessary.

With numeric argument N, use the daily-note N days in the
future.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn N &optional KEYS)" t) (autoload 'org-roam-dailies-capture-yesterday "org-roam-dailies" "Create an entry in the daily-note for yesteday.

With numeric argument N, use the daily-note N days in the past.

When GOTO is non-nil, go the note without creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn N &optional GOTO KEYS)" t) (autoload 'org-roam-dailies-goto-yesterday "org-roam-dailies" "Find the daily-note for yesterday, creating it if necessary.

With numeric argument N, use the daily-note N days in the
future.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn N &optional KEYS)" t) (autoload 'org-roam-dailies-capture-date "org-roam-dailies" "Create an entry in the daily-note for a date using the calendar.
Prefer past dates, unless PREFER-FUTURE is non-nil.
With a `C-u' prefix or when GOTO is non-nil, go the note without
creating an entry.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn &optional GOTO PREFER-FUTURE KEYS)" t) (autoload 'org-roam-dailies-goto-date "org-roam-dailies" "Find the daily-note for a date using the calendar, creating it if necessary.
Prefer past dates, unless PREFER-FUTURE is non-nil.

ELisp programs can set KEYS to a string associated with a template.
In this case, interactive selection will be bypassed.

(fn &optional PREFER-FUTURE KEYS)" t) (autoload 'org-roam-dailies-find-directory "org-roam-dailies" "Find and open `org-roam-dailies-directory'." t) (register-definition-prefixes "org-roam-dailies" '("org-roam-dailies-")) (autoload 'org-roam-db-sync "org-roam-db" "Synchronize the cache state with the current Org files on-disk.
If FORCE, force a rebuild of the cache from scratch.

(fn &optional FORCE)" t) (defvar org-roam-db-autosync-mode nil "Non-nil if Org-Roam-Db-Autosync mode is enabled.
See the `org-roam-db-autosync-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `org-roam-db-autosync-mode'.") (custom-autoload 'org-roam-db-autosync-mode "org-roam-db" nil) (autoload 'org-roam-db-autosync-mode "org-roam-db" "Global minor mode to keep your Org-roam session automatically synchronized.

Through the session this will continue to setup your
buffers (that are Org-roam file visiting), keep track of the
related changes, maintain cache consistency and incrementally
update the currently active database.

If you need to manually trigger resync of the currently active
database, see `org-roam-db-sync' command.

This is a global minor mode.  If called interactively, toggle the
`Org-Roam-Db-Autosync mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='org-roam-db-autosync-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (autoload 'org-roam-db-autosync-enable "org-roam-db" "Activate `org-roam-db-autosync-mode'.") (register-definition-prefixes "org-roam-db" '("emacsql-constraint" "org-roam-db")) (register-definition-prefixes "org-roam-export" '("org-roam-export--org-html--reference")) (autoload 'org-roam-graph "org-roam-graph" "Build and possibly display a graph for NODE.
ARG may be any of the following values:
  - nil       show the graph.
  - `\\[universal-argument]'     show the graph for NODE.
  - `\\[universal-argument]' N   show the graph for NODE limiting nodes to N steps.

(fn &optional ARG NODE)" t) (register-definition-prefixes "org-roam-graph" '("org-roam-")) (autoload 'org-roam-update-org-id-locations "org-roam-id" "Scan Org-roam files to update `org-id' related state.
This is like `org-id-update-id-locations', but will automatically
use the currently bound `org-directory' and `org-roam-directory'
along with DIRECTORIES (if any), where the lookup for files in
these directories will be always recursive.

Note: Org-roam doesn't have hard dependency on
`org-id-locations-file' to lookup IDs for nodes that are stored
in the database, but it still tries to properly integrates with
`org-id'. This allows the user to cross-reference IDs outside of
the current `org-roam-directory', and also link with \"id:\"
links to headings/files within the current `org-roam-directory'
that are excluded from identification in Org-roam as
`org-roam-node's, e.g. with \"ROAM_EXCLUDE\" property.

(fn &rest DIRECTORIES)" t) (register-definition-prefixes "org-roam-id" '("org-roam-id-")) (register-definition-prefixes "org-roam-log" '("org-roam-log-")) (autoload 'org-roam-migrate-wizard "org-roam-migrate" "Migrate all notes from to be compatible with Org-roam v2.
1. Convert all notes from v1 format to v2.
2. Rebuild the cache.
3. Replace all file links with ID links." t) (register-definition-prefixes "org-roam-migrate" '("org-roam-migrate-")) (autoload 'org-roam-buffer-display-dedicated "org-roam-mode" "Launch NODE dedicated Org-roam buffer.
Unlike the persistent `org-roam-buffer', the contents of this
buffer won't be automatically changed and will be held in place.

In interactive calls prompt to select NODE, unless called with
`universal-argument', in which case NODE will be set to
`org-roam-node-at-point'.

(fn NODE)" t) (register-definition-prefixes "org-roam-mode" '("org-roam-")) (autoload 'org-roam-node-find "org-roam-node" "Find and open an Org-roam node by its title or alias.
INITIAL-INPUT is the initial input for the prompt.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.
If OTHER-WINDOW, visit the NODE in another window.
The TEMPLATES, if provided, override the list of capture templates (see
`org-roam-capture-'.)

(fn &optional OTHER-WINDOW INITIAL-INPUT FILTER-FN PRED &key TEMPLATES)" t) (autoload 'org-roam-node-random "org-roam-node" "Find and open a random Org-roam node.
With prefix argument OTHER-WINDOW, visit the node in another
window instead.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.

(fn &optional OTHER-WINDOW FILTER-FN)" t) (autoload 'org-roam-node-insert "org-roam-node" "Find an Org-roam node and insert (where the point is) an \"id:\" link to it.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.
The TEMPLATES, if provided, override the list of capture templates (see
`org-roam-capture-'.)
The INFO, if provided, is passed to the underlying `org-roam-capture-'.

(fn &optional FILTER-FN &key TEMPLATES INFO)" t) (autoload 'org-roam-refile "org-roam-node" "Refile node at point to an org-roam NODE.

If region is active, then use it instead of the node at point.

(fn NODE)" t) (autoload 'org-roam-extract-subtree "org-roam-node" "Convert current subtree at point to a node, and extract it into a new file." t) (autoload 'org-roam-ref-find "org-roam-node" "Find and open an Org-roam node that's dedicated to a specific ref.
INITIAL-INPUT is the initial input to the prompt.
FILTER-FN is a function to filter out nodes: it takes an `org-roam-node',
and when nil is returned the node will be filtered out.

(fn &optional INITIAL-INPUT FILTER-FN)" t) (register-definition-prefixes "org-roam-node" '("org-roam-")) (register-definition-prefixes "org-roam-overlay" '("org-roam-overlay-")) (register-definition-prefixes "org-roam-protocol" '("org-roam-")) (autoload 'org-roam-version "org-roam-utils" "Return `org-roam' version.
Interactively, or when MESSAGE is non-nil, show in the echo area.

(fn &optional MESSAGE)" t) (autoload 'org-roam-diagnostics "org-roam-utils" "Collect and print info for `org-roam' issues." t) (register-definition-prefixes "org-roam-utils" '("org-roam-")) (provide 'org-roam-autoloads)) "simple-httpd" ((simple-httpd simple-httpd-autoloads) (autoload 'httpd-start "simple-httpd" "Start the web server process. If the server is already
running, this will restart the server. There is only one server
instance per Emacs instance." t) (autoload 'httpd-stop "simple-httpd" "Stop the web server if it is currently running, otherwise do nothing." t) (autoload 'httpd-running-p "simple-httpd" "Return non-nil if the simple-httpd server is running.") (autoload 'httpd-serve-directory "simple-httpd" "Start the web server with given `directory' as `httpd-root'.

(fn DIRECTORY)" t) (register-definition-prefixes "simple-httpd" '("defservlet" "httpd" "with-httpd-buffer")) (provide 'simple-httpd-autoloads)) "websocket" ((websocket-autoloads websocket) (register-definition-prefixes "websocket" '("websocket-")) (provide 'websocket-autoloads)) "org-roam-ui" ((org-roam-ui org-roam-ui-autoloads) (defvar org-roam-ui-mode nil "Non-nil if org-roam-ui mode is enabled.
See the `org-roam-ui-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `org-roam-ui-mode'.") (custom-autoload 'org-roam-ui-mode "org-roam-ui" nil) (autoload 'org-roam-ui-mode "org-roam-ui" "Enable org-roam-ui.

This serves the web-build and API over HTTP.

This is a global minor mode.  If called interactively, toggle the
`org-roam-ui mode' mode.  If the prefix argument is positive, enable the
mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='org-roam-ui-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (autoload 'org-roam-ui-open "org-roam-ui" "Ensure `org-roam-ui' is running, then open the `org-roam-ui' webpage." t) (autoload 'org-roam-ui-node-zoom "org-roam-ui" "Move the view of the graph to current node.
or optionally a node of your choosing.
Optionally takes three arguments:
The ID of the node you want to travel to.
The SPEED in ms it takes to make the transition.
The PADDING around the nodes in the viewport.

(fn &optional ID SPEED PADDING)" t) (autoload 'org-roam-ui-node-local "org-roam-ui" "Open the local graph view of the current node.
Optionally with ID (string), SPEED (number, ms) and PADDING (number, px).

(fn &optional ID SPEED PADDING)" t) (autoload 'org-roam-ui-add-to-local-graph "org-roam-ui" "Add current node to the local graph. If not in local mode, open local-graph for this node.

(fn &optional ID)" t) (autoload 'org-roam-ui-remove-from-local-graph "org-roam-ui" "Remove current node from the local graph. If not in local mode, open local-graph for this node.

(fn &optional ID)" t) (autoload 'org-roam-ui-sync-theme "org-roam-ui" "Sync your current Emacs theme with org-roam-ui." t) (defvar org-roam-ui-follow-mode nil "Non-nil if org-roam-ui-Follow mode is enabled.
See the `org-roam-ui-follow-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `org-roam-ui-follow-mode'.") (custom-autoload 'org-roam-ui-follow-mode "org-roam-ui" nil) (autoload 'org-roam-ui-follow-mode "org-roam-ui" "Set whether ORUI should follow your every move in Emacs.

This is a global minor mode.  If called interactively, toggle the
`org-roam-ui-Follow mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='org-roam-ui-follow-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t) (register-definition-prefixes "org-roam-ui" '("img/:file" "node/:id" "org-roam-ui-")) (provide 'org-roam-ui-autoloads))))

#s(hash-table test eq data (org-elpa #s(hash-table test equal data (version (16 "https://github.com/emacs-straight/org-mode.git") "use-package" nil "bind-key" nil "org" (org :type git :host github :protocol https :repo "emacs-straight/org-mode" :local-repo "org" :depth full :pre-build (straight-recipes-org-elpa--build) :build (:not autoloads) :files (:defaults "lisp/*.el" ("etc/styles/" "etc/styles/*"))) "denote" nil "org-roam" nil "dash" nil "emacsql" nil "magit-section" nil "compat" nil "seq" nil "cond-let" nil "llama" nil "org-roam-ui" nil "simple-httpd" nil "cl-lib" nil "websocket" nil)) melpa #s(hash-table test equal data (version 3 "use-package" nil "bind-key" nil "denote" nil "org-roam" (org-roam :type git :files (:defaults "extensions/*" "org-roam-pkg.el") :host github :repo "org-roam/org-roam") "dash" (dash :type git :files ("dash.el" "dash.texi" "dash-pkg.el") :host github :repo "magnars/dash.el") "emacsql" (emacsql :type git :files (:defaults "README.md" "sqlite" "emacsql-pkg.el") :host github :repo "magit/emacsql") "magit-section" (magit-section :type git :files ("lisp/magit-section.el" "docs/magit-section.texi" "magit-section-pkg.el" "magit-section-pkg.el") :host github :repo "magit/magit") "compat" nil "seq" nil "cond-let" (cond-let :type git :host github :repo "tarsius/cond-let") "llama" (llama :type git :files ("llama.el" ".dir-locals.el" "llama-pkg.el") :host github :repo "tarsius/llama") "org-roam-ui" (org-roam-ui :type git :files (:defaults "out" "org-roam-ui-pkg.el") :host github :repo "org-roam/org-roam-ui") "simple-httpd" (simple-httpd :type git :host github :repo "skeeto/emacs-web-server") "cl-lib" nil "websocket" (websocket :type git :host github :repo "ahyatt/emacs-websocket"))) gnu-elpa-mirror #s(hash-table test equal data (version 3 "use-package" (use-package :type git :host github :repo "emacs-straight/use-package" :files ("*" (:exclude ".git"))) "bind-key" (bind-key :type git :host github :repo "emacs-straight/bind-key" :files ("*" (:exclude ".git"))) "denote" (denote :type git :host github :repo "emacs-straight/denote" :files ("*" (:exclude ".git"))) "compat" (compat :type git :host github :repo "emacs-straight/compat" :files ("*" (:exclude ".git"))) "seq" (seq :type git :host github :repo "emacs-straight/seq" :files ("*" (:exclude ".git"))) "cl-lib" nil)) nongnu-elpa #s(hash-table test equal data (version (5 "https://github.com/emacsmirror/nongnu_elpa.git") "cl-lib" nil)) el-get #s(hash-table test equal data (version 2 "cl-lib" nil)) emacsmirror-mirror #s(hash-table test equal data (version 2 "cl-lib" nil))))

("websocket" "cl-lib" "simple-httpd" "org-roam-ui" "llama" "cond-let" "seq" "compat" "magit-section" "emacsql" "dash" "org-roam" "denote" "org" "bind-key" "use-package" "emacsmirror-mirror" "el-get" "nongnu-elpa" "gnu-elpa-mirror" "melpa" "org-elpa" "emacs" "straight")

t
