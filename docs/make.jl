push!(LOAD_PATH, "../src/")

using Documenter
using NuVe

makedocs(
    sitename = "NuVe",
    format = Documenter.Markdown(),
    modules = [NuVe]
)


deploydocs(
    repo = "github.com/Ph0non/NuVe.jl.git"
    target = "build"
)
