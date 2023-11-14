seed = 1000
:rand.seed(:exs1024, seed)
_ = :rand.uniform() # <- new line
x = :rand.uniform()
IO.puts("x: #{x}")
