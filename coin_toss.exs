Mix.install([
  {:minigen, "~> 0.1", manager: :rebar3}
])
alias :minigen, as: MG
seed = 1000

simulate = fn gen ->
  gen
  |> Stream.iterate(fn g ->
    MG.then(g, fn _ -> gen end)
  end)
  |> Enum.reduce(
       {0, 0},
       fn g, {i_acc, n_acc} ->
         i =
           case MG.run_with_seed(g, seed) do
             true -> i_acc + 1
             false -> i_acc
           end

         n = n_acc + 1
         IO.puts("estimation: #{i / n} --- sample_size: #{n}")
         {i, n}
       end
     )
end

b_gen = MG.boolean()
simulate.(b_gen)
