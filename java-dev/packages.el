;;; packages.el --- java-dev layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author:  <rhythm@Rhythm>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `java-dev-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `java-dev/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `java-dev/pre-init-PACKAGE' and/or
;;   `java-dev/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst java-dev-packages
  '(
    company
    dap-mode
    flycheck
    ggtags
    counsel-gtags
    helm-gtags
    (java-mode :location built-in)
    maven-test-mode
    (meghanada :toggle (not (version< emacs-version "25.1")))
    mvn
    (lsp-java :requires lsp-mode)
    org
    smartparens)
  "The list of Lisp packages required by the java-dev layer.

Each entry is either:

1. A symbol, which is interpreted as a package to be installed, or

2. A list of the form (PACKAGE KEYS...), where PACKAGE is the
    name of the package to be installed or loaded, and KEYS are
    any number of keyword-value-pairs.

    The following keys are accepted:

    - :excluded (t or nil): Prevent the package from being loaded
      if value is non-nil

    - :location: Specify a custom installation location.
      The following values are legal:

      - The symbol `elpa' (default) means PACKAGE will be
        installed using the Emacs package manager.

      - The symbol `local' directs Spacemacs to load the file at
        `./local/PACKAGE/PACKAGE.el'

      - A list beginning with the symbol `recipe' is a melpa
        recipe.  See: https://github.com/milkypostman/melpa#recipe-format")

(defun java-dev/post-init-company ()
  (add-hook 'java-mode-local-vars-hook #'spacemacs//java-setup-company))

(defun java-dev/pre-init-dap-mode ()
  (pcase (spacemacs//java-backend)
    (`lsp (add-to-list 'spacemacs--dap-supported-modes 'java-mode)))
  (add-hook 'java-mode-local-vars-hook #'spacemacs//java-setup-dap))

(defun java-dev/post-init-flycheck ()
  (add-hook 'java-mode-local-vars-hook #'spacemacs//java-setup-flycheck))

(defun java-dev/post-init-ggtags ()
  (add-hook 'java-mode-local-vars-hook #'spacemacs/ggtags-mode-enable))

(defun java-dev/post-init-smartparens ()
  (with-eval-after-load 'smartparens
    (sp-local-pair 'java-mode "/** " " */" :trigger "/**")))

(defun java-dev/post-init-counsel-gtags ()
  (spacemacs/counsel-gtags-define-keys-for-mode 'java-mode))

(defun java-dev/post-init-helm-gtags ()
  (spacemacs/helm-gtags-define-keys-for-mode 'java-mode))

(defun java-dev/pre-init-org ()
  (spacemacs|use-package-add-hook org
    :post-config (add-to-list 'org-babel-load-languages '(java . t))))

(defun java-dev/init-java-mode ()
  (use-package java-mode
    :defer t
    :init
    (progn
      (add-hook 'java-mode-local-vars-hook #'spacemacs//java-setup-backend)
      (put 'java-backend 'safe-local-variable 'symbolp))))

(defun java-dev/init-maven-test-mode ()
  (use-package maven-test-mode
    :defer t
    :init
    (when (configuration-layer/package-usedp 'java-mode)
      (add-hook 'java-mode-hook 'maven-test-mode)
      (spacemacs/declare-prefix-for-mode 'java-mode "mm" "maven")
      (spacemacs/declare-prefix-for-mode 'java-mode "mmg" "goto")
      (spacemacs/declare-prefix-for-mode 'java-mode "mmt" "tests"))
    :config
    (progn
      (spacemacs|hide-lighter maven-test-mode)
      (spacemacs/set-leader-keys-for-minor-mode 'maven-test-mode
        "mga"    'maven-test-toggle-between-test-and-class
        "mgA"    'maven-test-toggle-between-test-and-class-other-window
        "mta"    'maven-test-all
        "mt C-a" 'maven-test-clean-test-all
        "mtb"    'maven-test-file
        "mti"    'maven-test-install
        "mtt"    'maven-test-method))))

(defun java-dev/init-meghanada ()
  (use-package meghanada
    :defer t
    :if (eq java-backend 'meghanada)
    :init
    (progn
      (setq meghanada-server-install-dir (concat spacemacs-cache-directory
                                                 "meghanada/")
            company-meghanada-prefix-length 1
            ;; let spacemacs handle company and flycheck itself
            meghanada-use-company nil
            meghanada-use-flycheck nil))
    :config
    (progn
      ;; key bindings
      (dolist (prefix '(("mc" . "compile")
                        ("mD" . "daemon")
                        ("mg" . "goto")
                        ("mr" . "refactor")
                        ("mt" . "test")
                        ("mx" . "execute")))
        (spacemacs/declare-prefix-for-mode
          'java-mode (car prefix) (cdr prefix)))
      (spacemacs/set-leader-keys-for-major-mode 'java-mode
        "cb" 'meghanada-compile-file
        "cc" 'meghanada-compile-project

        "Dc" 'meghanada-client-direct-connect
        "Dd" 'meghanada-client-disconnect
        "Di" 'meghanada-install-server
        "Dk" 'meghanada-server-kill
        "Dl" 'meghanada-clear-cache
        "Dp" 'meghanada-ping
        "Dr" 'meghanada-restart
        "Ds" 'meghanada-client-connect
        "Du" 'meghanada-update-server
        "Dv" 'meghanada-version

        "gb" 'meghanada-back-jump

        "=" 'meghanada-code-beautify
        "ri" 'meghanada-optimize-import
        "rI" 'meghanada-import-all

        "ta" 'meghanada--run-junit
        "tc" 'meghanada-run-junit-class
        "tl" 'meghanada-run-junit-recent
        "tt" 'meghanada-run-junit-test-case

        ;; meghanada-switch-testcase
        ;; meghanada-local-variable

        "x:" 'meghanada-run-task))))

(defun java-dev/init-lsp-java ()
  (use-package lsp-java
    :defer t
    :if (eq (spacemacs//java-backend) 'lsp)
    :config
    (progn
      (when (not (eq (spacemacs//java-java-path) nil))
        (setq lsp-java-java-path (spacemacs//java-java-path)))
      ;; key bindings
      (dolist (prefix '(("ma" . "actionable")
                        ("mc" . "compile/create")
                        ("mg" . "goto")
                        ("mr" . "refactor")
                        ("mra" . "add/assign")
                        ("mrc" . "create/convert")
                        ("mrg" . "generate")
                        ("mre" . "extract")
                        ("mp" . "project")
                        ("mq" . "lsp")
                        ("mt" . "test")
                        ("mx" . "execute")))
        (spacemacs/declare-prefix-for-mode
          'java-mode (car prefix) (cdr prefix)))
      (spacemacs/set-leader-keys-for-major-mode 'java-mode
        "pu"  'lsp-java-update-project-configuration

        ;; refactoring
        "ro" 'lsp-java-organize-imports
        "rcp" 'lsp-java-create-parameter
        "rcf" 'lsp-java-create-field
        "rci" 'lsp-java-conver-to-static-import
        "rec" 'lsp-java-extract-to-constant
        "rel" 'lsp-java-extract-to-local-variable
        "rem" 'lsp-java-extract-method

        ;; assign/add
        "rai" 'lsp-java-add-import
        "ram" 'lsp-java-add-unimplemented-methods
        "rat" 'lsp-java-add-throws
        "raa" 'lsp-java-assign-all
        "raf" 'lsp-java-assign-to-field

        ;; generate
        "rgt" 'lsp-java-generate-to-string
        "rge" 'lsp-java-generate-equals-and-hash-code
        "rgo" 'lsp-java-generate-overrides
        "rgg" 'lsp-java-generate-getters-and-setters

        ;; create/compile
        "cc"  'lsp-java-build-project
        "cp"  'lsp-java-spring-initializr

        "an"  'lsp-java-actionable-notifications))))

(defun java-dev/init-mvn ()
  (use-package mvn
    :defer t
    :init
    (when (configuration-layer/package-usedp 'java-mode)
      (spacemacs/declare-prefix-for-mode 'java-mode "mm" "maven")
      (spacemacs/declare-prefix-for-mode 'java-mode "mmc" "compile")
      (spacemacs/set-leader-keys-for-major-mode 'java-mode
        "mcc" 'mvn-compile
        "mcC" 'mvn-clean
        "mcr" 'spacemacs/mvn-clean-compile))))

;;; packages.el ends here
