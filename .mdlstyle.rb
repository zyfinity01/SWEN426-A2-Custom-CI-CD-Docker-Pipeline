################################################################################
# Style file for markdownlint.
#
# https://github.com/markdownlint/markdownlint/blob/master/docs/configuration.md
#
# This file is referenced by the project `.mdlrc`.
################################################################################

# Enforce a consistent style.
all
rule 'MD003', :style => :atx
rule 'MD004', :style => :dash
rule 'MD007', :indent => 2
rule 'MD009', :br_spaces => 2
rule 'MD035', :style => "---"
rule 'MD026', :punctuation => ".,;:!" # Allow '?' at the end of heading lines

exclude_rule 'MD013' # Line length
exclude_rule 'MD024' # Multiple headers with the same content
exclude_rule 'MD033' # Inline HTML
