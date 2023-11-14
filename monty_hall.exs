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

monty_opens_gen = fn player_init_choice, doors ->
  monty_choices = Enum.reject([0, 1, 2], &(&1 == player_init_choice))
  [monty_first_choice, monty_second_choice] = monty_choices

  case {Enum.at(doors, monty_first_choice), Enum.at(doors, monty_second_choice)} do
    {:car, :goat} ->
      MG.always(monty_second_choice)

    {:goat, :car} ->
      MG.always(monty_first_choice)

    {:goat, :goat} ->
      monty_choices
      |> MG.shuffled_list()
      |> MG.map(&Enum.at(&1, 0))
  end
end

did_player_win_gen = fn monty_opens_gen, doors, player_init_choice ->
  MG.then(
    monty_opens_gen,
    fn monty_opens ->
      [prayer_final_choice] =
        Enum.reject(
          [0, 1, 2],
          &(&1 == player_init_choice || &1 == monty_opens)
        )

      prayer_final_choice_gen = MG.always(prayer_final_choice)

      MG.map(
        prayer_final_choice_gen,
        fn prayer_final_choice ->
          Enum.at(doors, prayer_final_choice) == :car
        end
      )
    end
  )
end

b_gen =
  MG.then(
    MG.shuffled_list([:car, :goat, :goat]),
    fn doors ->
      MG.then(
        MG.integer(3),
        fn player_init_choice ->
          player_init_choice
          |> monty_opens_gen.(doors)
          |> did_player_win_gen.(doors, player_init_choice)
        end
      )
    end
  )

simulate.(b_gen)
