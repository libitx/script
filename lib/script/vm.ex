defmodule Script.VM do
  @moduledoc """
  TODO
  """
  defstruct stack: [],
            alt_stack: [],
            if_stack: [],
            exit_status: nil

  @type vm :: %__MODULE__{
    stack: list,
    alt_stack: list,
    if_stack: list,
    exit_status: nil | integer
  }


  @doc """
  TODO
  """
  @spec eval(vm, list | atom | binary) :: {:ok, vm} | {:error, String.t}

  def eval(%__MODULE__{} = vm, script) when is_list(script) do
    vm = Enum.reduce_while(script, vm, fn
      _op, %{exit_status: status} = vm when is_integer(status) ->
        {:halt, vm}

      op, vm ->
        case eval(vm, op) do
          {:ok, vm} -> {:cont, vm}
          _ -> {:halt, vm}
        end
    end)
    {:ok, vm}
  end

  def eval(%__MODULE__{exit_status: status} = vm, _op)
    when is_integer(status),
    do: {:ok, vm}

  def eval(%__MODULE__{if_stack: [{:IF, false} | _]} = vm, op)
    when op != :OP_ELSE and op != :OP_ENDIF,
    do: {:ok, vm}

  def eval(%__MODULE__{if_stack: [{:ELSE, false} | _]} = vm, op)
    when op != :OP_ENDIF,
    do: {:ok, vm}

  def eval(%__MODULE__{} = vm, op) do
    case op do
      data when is_binary(data) -> op_pushdata(vm, data)

      # 1. Constants
      :OP_FALSE -> op_pushdata(vm, <<>>)
      :OP_0 -> op_pushdata(vm, <<>>)
      :OP_1NEGATE -> op_pushdata(vm, -1)
      :OP_TRUE -> op_pushdata(vm, 1)
      :OP_1 -> op_pushdata(vm, 1)
      :OP_2 -> op_pushdata(vm, 2)
      :OP_3 -> op_pushdata(vm, 3)
      :OP_4 -> op_pushdata(vm, 4)
      :OP_5 -> op_pushdata(vm, 5)
      :OP_6 -> op_pushdata(vm, 6)
      :OP_7 -> op_pushdata(vm, 7)
      :OP_8 -> op_pushdata(vm, 8)
      :OP_9 -> op_pushdata(vm, 9)
      :OP_10 -> op_pushdata(vm, 10)
      :OP_11 -> op_pushdata(vm, 11)
      :OP_12 -> op_pushdata(vm, 12)
      :OP_13 -> op_pushdata(vm, 13)
      :OP_14 -> op_pushdata(vm, 14)
      :OP_15 -> op_pushdata(vm, 15)
      :OP_16 -> op_pushdata(vm, 16)

      # 2. Control
      :OP_NOP -> op_nop(vm)
      :OP_VER -> op_ver(vm)
      :OP_IF -> op_if(vm)
      :OP_NOTIF -> op_notif(vm)
      :OP_VERIF -> op_verif(vm)
      :OP_VERNOTIF -> op_vernotif(vm)
      :OP_ELSE -> op_else(vm)
      :OP_ENDIF -> op_endif(vm)
      :OP_VERIFY -> op_verify(vm)
      :OP_RETURN -> op_return(vm)

      # 3. Stack
      :OP_TOALTSTACK -> op_toaltstack(vm)
      :OP_FROMALTSTACK -> op_fromaltstack(vm)
      :OP_2DROP -> op_2drop(vm)
      :OP_2DUP -> op_2dup(vm)
      :OP_3DUP -> op_3dup(vm)
      :OP_2OVER -> op_2over(vm)
      :OP_2ROT -> op_2rot(vm)
      :OP_2SWAP -> op_2swap(vm)
      :OP_IFDUP -> op_ifdup(vm)
      :OP_DEPTH -> op_depth(vm)
      :OP_DROP -> op_drop(vm)
      :OP_DUP -> op_dup(vm)
      :OP_NIP -> op_nip(vm)
      :OP_OVER -> op_over(vm)
      :OP_PICK -> op_pick(vm)
      :OP_ROLL -> op_roll(vm)
      :OP_ROT -> op_rot(vm)
      :OP_SWAP -> op_swap(vm)
      :OP_TUCK -> op_tuck(vm)

      # 4. Data manipulation
      #:OP_CAT -> op_cat(vm)
      #:OP_SPLIT -> op_split(vm)
      #:OP_NUM2BIN -> op_num2bin(vm)
      #:OP_BIN2NUM -> op_bin2num(vm)
      #:OP_SIZE -> op_size(vm)
    end
  end



  @doc """
  Generic pushdata. Pushes any given binary or integer to the stack.
  """
  def op_pushdata(%__MODULE__{} = vm, data)
    when is_binary(data) or is_integer(data),
    do: {:ok, update_in(vm.stack, & [data | &1])}


  @doc """
  No op. Does nothing and returns the vm.
  """
  def op_nop(%__MODULE__{} = vm), do: {:ok, vm}


  @doc """
  Puts the version of the protocol under which this transaction will be
  evaluated onto the stack. **DISABLED**
  """
  def op_ver(%__MODULE__{} = _vm), do: {:error, "OP_VER disabled"}


  @doc """
  Removes the top of the stack. If the top value is truthy, statements between
  OP_IF and OP_ELSE are executed. Otherwise statements between OP_ELSE and
  OP_ENDIF are executed.
  """
  def op_if(%__MODULE__{stack: []}), do: {:error, "OP_IF stack empty"}
  def op_if(%__MODULE__{stack: [top | stack]} = vm) do
    vm = vm
    |> Map.merge(%{
      stack: stack,
      if_stack: [{:IF, true?(top)} | vm.if_stack]
    })
    {:ok, vm}
  end


  @doc """
  Removes the top of the stack. If the top value is false, statements between
  OP_NOTIF and OP_ELSE are executed. Otherwise statements between OP_ELSE and
  OP_ENDIF are executed.
  """
  def op_notif(%__MODULE__{stack: []}), do: {:error, "OP_NOTIF stack empty"}
  def op_notif(%__MODULE__{stack: [top | stack]} = vm) do
    vm = vm
    |> Map.merge(%{
      stack: stack,
      if_stack: [{:IF, !true?(top)} | vm.if_stack]
    })
    {:ok, vm}
  end


  @doc """
  Removes the top of the stack. If the top value is equal to the version of the
  protocol under which the transaction is evaluated, statements between OP_IF
  and OP_ELSE are executed. Otherwise statements between OP_ELSE and OP_ENDIF
  are executed. **DISABLED**
  """
  def op_verif(%__MODULE__{} = _vm), do: {:error, "OP_VERIF disabled"}


  @doc """
  Removes the top of the stack. If the top value is not equal to the version of
  the protocol under which the transaction is evaluated, statements between
  OP_IF and OP_ELSE are executed. Otherwise statements between OP_ELSE and
  OP_ENDIF are executed. **DISABLED**
  """
  def op_vernotif(%__MODULE__{} = _vm), do: {:error, "OP_VERNOTIF disabled"}


  @doc """
  If the preceding OP_IF or OP_NOTIF was not executed, the the following
  statements are executed. If the preceding OP_IF or OP_NOTIF was executed, the
  following statements are not.
  """
  def op_else(%__MODULE__{if_stack: []}), do: {:error, "OP_ELSE used outside of IF block"}
  def op_else(%__MODULE__{if_stack: [{_, bool} | if_stack]} = vm) do
    vm = Map.put(vm, :if_stack, [{:ELSE, !bool} | if_stack])
    {:ok, vm}
  end


  @doc """
  Ends the current IF/ELSE block. All blocks must end or the script is
  **invalid**.
  """
  def op_endif(%__MODULE__{if_stack: []}), do: {:error, "OP_ENDIF used outside of IF block"}
  def op_endif(%__MODULE__{if_stack: [_ | if_stack]} = vm) do
    vm = put_in(vm.if_stack, if_stack)
    {:ok, vm}
  end


  @doc """
  Removes the top of the stack and marks the script as **invalid** unless the
  op element is truthy.
  """
  def op_verify(%__MODULE__{stack: []}), do: {:error, "OP_VERIFY stack empty"}
  def op_verify(%__MODULE__{stack: [top | stack]} = vm) do
    case true?(top) do
      true ->
        vm = put_in(vm.stack, stack)
        {:ok, vm}
      false ->
        {:error, "OP_VERIFY failed"}
    end
  end


  @doc """
  Returns the vm and no further statements are evaluated.
  """
  def op_return(%__MODULE__{} = vm), do: {:ok, put_in(vm.exit_status, 0)}


  @doc """
  Removes the top of the stack and puts it into the alt stack.
  """
  def op_toaltstack(%__MODULE__{stack: []}), do: {:error, "OP_TOALTSTACK stack empty"}
  def op_toaltstack(%__MODULE__{stack: [top | stack]} = vm) do
    vm = vm
    |> Map.merge(%{
      stack: stack,
      alt_stack: [top | vm.alt_stack]
    })
    {:ok, vm}
  end


  @doc """
  Removes the top of the alt stack and puts it into the stack.
  """
  def op_fromaltstack(%__MODULE__{alt_stack: []}), do: {:error, "OP_FROMALTSTACK alt stack empty"}
  def op_fromaltstack(%__MODULE__{alt_stack: [top | stack]} = vm) do
    vm = vm
    |> Map.merge(%{
      stack: [top | vm.stack],
      alt_stack: stack
    })
    {:ok, vm}
  end


  @doc """
  Removes the top two items from the stack.
  """
  def op_2drop(%__MODULE__{stack: stack})
    when length(stack) < 2,
    do: {:error, "OP_2DROP invalid stack length"}

  def op_2drop(%__MODULE__{stack: [_, _ | stack]} = vm) do
    vm = put_in(vm.stack, stack)
    {:ok, vm}
  end


  @doc """
  Duplicates the top two items on the stack.
  """
  def op_2dup(%__MODULE__{stack: stack})
    when length(stack) < 2,
    do: {:error, "OP_2DUP invalid stack length"}

  def op_2dup(%__MODULE__{stack: [a, b | _]} = vm) do
    vm = update_in(vm.stack, & [a, b | &1])
    {:ok, vm}
  end


  @doc """
  Duplicates the top three items on the stack.
  """
  def op_3dup(%__MODULE__{stack: stack})
    when length(stack) < 3,
    do: {:error, "OP_3DUP invalid stack length"}

  def op_3dup(%__MODULE__{stack: [a, b, c | _]} = vm) do
    vm = update_in(vm.stack, & [a, b, c | &1])
    {:ok, vm}
  end


  @doc """
  Copies two items two spaces back to the top of the stack.
  """
  def op_2over(%__MODULE__{stack: stack})
    when length(stack) < 4,
    do: {:error, "OP_2OVER invalid stack length"}

  def op_2over(%__MODULE__{stack: [_a, _b, c, d | _]} = vm) do
    vm = update_in(vm.stack, & [c, d | &1])
    {:ok, vm}
  end


  @doc """
  Moves the 5th and 6th items to top of stack.
  """
  def op_2rot(%__MODULE__{stack: stack})
    when length(stack) < 6,
    do: {:error, "OP_2ROT invalid stack length"}

  def op_2rot(%__MODULE__{stack: [a, b, c, d, e, f | stack]} = vm) do
    vm = put_in(vm.stack, [e, f, a, b, c, d | stack])
    {:ok, vm}
  end


  @doc """
  Swaps the top two pairs of items.
  """
  def op_2swap(%__MODULE__{stack: stack})
    when length(stack) < 4,
    do: {:error, "OP_2SWAP invalid stack length"}

  def op_2swap(%__MODULE__{stack: [a, b, c, d | stack]} = vm) do
    vm = put_in(vm.stack, [c, d, a, b | stack])
    {:ok, vm}
  end


  @doc """
  Duplicates the top stack item if it is truthy.
  """
  def op_ifdup(%__MODULE__{stack: []}), do: {:error, "OP_IFDUP stack empty"}
  def op_ifdup(%__MODULE__{stack: [top | _]} = vm) do
    case true?(top) do
      true ->
        vm = update_in(vm.stack, & [top | &1])
        {:ok, vm}
      false ->
        {:ok, vm}
    end
  end


  @doc """
  Counts the stack lenth and puts the result on the top of the stack.
  """
  def op_depth(%__MODULE__{stack: stack} = vm) do
    vm = put_in(vm.stack, [length(stack) | stack])
    {:ok, vm}
  end


  @doc """
  Removes the top item from the stack.
  """
  def op_drop(%__MODULE__{stack: []}), do: {:error, "OP_DROP stack empty"}
  def op_drop(%__MODULE__{stack: [_ | stack]} = vm) do
    vm = put_in(vm.stack, stack)
    {:ok, vm}
  end


  @doc """
  Duplicates the top item on the stack.
  """
  def op_dup(%__MODULE__{stack: []}), do: {:error, "OP_DUP stack empty"}
  def op_dup(%__MODULE__{stack: [top | _]} = vm) do
    vm = update_in(vm.stack, & [top | &1])
    {:ok, vm}
  end


  @doc """
  Removes the second to top item from the stack.
  """
  def op_nip(%__MODULE__{stack: stack})
    when length(stack) < 2,
    do: {:error, "OP_NIP invalid stack length"}

  def op_nip(%__MODULE__{} = vm) do
    vm = update_in(vm.stack, & List.delete_at(&1, 1))
    {:ok, vm}
  end


  @doc """
  Copies the second to top stack item to the top.
  """
  def op_over(%__MODULE__{stack: stack})
    when length(stack) < 2,
    do: {:error, "OP_OVER invalid stack length"}

  def op_over(%__MODULE__{stack: [_a, b | _]} = vm) do
    vm = update_in(vm.stack, & [b | &1])
    {:ok, vm}
  end


  @doc """
  Removes the top stack item and uses it as an index length, then copies the nth
  item on the stack to the top.
  """
  def op_pick(%__MODULE__{stack: []}), do: {:error, "OP_PICK stack empty"}
  def op_pick(%__MODULE__{stack: [top | stack]} = vm) do
    case Enum.at(stack, top) do
      nil ->
        {:error, "OP_PICK invalid stack length"}
      val ->
        vm = put_in(vm.stack, [val | stack])
        {:ok, vm}
    end
  end


  @doc """
  Removes the top stack item and uses it as an index length, then moves the nth
  item on the stack to the top.
  """
  def op_roll(%__MODULE__{stack: []}), do: {:error, "OP_ROLL stack empty"}
  def op_roll(%__MODULE__{stack: [top | stack]} = vm) do
    case List.pop_at(stack, top) do
      {nil, _} ->
        {:error, "OP_ROLL invalid stack length"}
      {val, stack} ->
        vm = put_in(vm.stack, [val | stack])
        {:ok, vm}
    end
  end


  @doc """
  Rotates the top three items on the stack, effictively moving the 3rd item to
  the top of the stack.
  """
  def op_rot(%__MODULE__{stack: stack})
    when length(stack) < 3,
    do: {:error, "OP_ROT invalid stack length"}

  def op_rot(%__MODULE__{stack: [a, b, c | stack]} = vm) do
    vm = put_in(vm.stack, [c, a, b | stack])
    {:ok, vm}
  end


  @doc """
  Rotates the top two items on the stack, effectively moving the 2nd item to the
  top of the stack.
  """
  def op_swap(%__MODULE__{stack: stack})
    when length(stack) < 2,
    do: {:error, "OP_SWAP invalid stack length"}

  def op_swap(%__MODULE__{stack: [a, b | stack]} = vm) do
    vm = put_in(vm.stack, [b, a | stack])
    {:ok, vm}
  end


  @doc """
  Copies the top item on the stack and inserts it before the second to top item.
  """
  def op_tuck(%__MODULE__{stack: stack})
    when length(stack) < 2,
    do: {:error, "OP_TUCK invalid stack length"}

  def op_tuck(%__MODULE__{stack: [top | _]} = vm) do
    vm = update_in(vm.stack, & List.insert_at(&1, 2, top))
    {:ok, vm}
  end



  # TODO
  defp true?(0), do: false
  defp true?(-1), do: false
  defp true?(<<>>), do: false
  defp true?(_), do: true


end
