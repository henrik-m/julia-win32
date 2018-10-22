# Julia Win32 GUI

Calling the Win32 API from Julia (last tested on v1.0.1).

## Getting started

```julia
include('winapi.jl')
using Main.WinApi

openwindow()
```

## Motivation

Compared to other native GUI options on the Windows platform, the Win32 API is
the fastest, the most flexible and by far the ugliest. So let's replace some
of the ugliness with idiomatic Julia and see where it takes us.

## More examples

For more examples, look at the files in the `examples` folder. If you
`include()` them from the Julia REPL, you need to restart your session
if you want to run the same or another example.
