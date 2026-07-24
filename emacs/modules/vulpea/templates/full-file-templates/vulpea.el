;;; templates/full-file-templates/vulpea.el -*- lexical-binding: t; -*-

(defvar my/capture-vulpea
  (doct
   `(("Vulpea"
      :keys "n"
      :children
      (("New note" :keys "n"
        :type plain
        :function (lambda () (my/vulpea-capture-new-file))
        :unnarrowed t)
       ("Task" :keys "t"
        :type plain
        :function (lambda () (my/vulpea-capture-task-file))
        :unnarrowed t)
       ("Heading" :keys "h"
        :type plain
        :function (lambda () (my/vulpea-capture-heading))
        :unnarrowed t))))))
