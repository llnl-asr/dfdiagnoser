# Configuration file for the Sphinx documentation builder.
#
# Single doc source shared by ReadTheDocs (GitHub) and GitLab Pages.

project = "dfdiagnoser"
copyright = "2026, Lawrence Livermore National Laboratory"
author = "Hariharan Devarajan"

extensions = []

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

try:
    import sphinx_rtd_theme  # noqa: F401
    html_theme = "sphinx_rtd_theme"
except ImportError:
    html_theme = "alabaster"

html_static_path = []
