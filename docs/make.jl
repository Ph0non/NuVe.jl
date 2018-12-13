push!(LOAD_PATH, "../src/")

using Documenter
using NuVe

makedocs(
    sitename = "NuVe",
    format = :html,
    modules = [NuVe]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
