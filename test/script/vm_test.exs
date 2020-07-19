defmodule Script.VMTest do
  use ExUnit.Case
  alias Script.VM
  doctest VM

  setup do
    %{vm: %VM{}}
  end


  describe "1. Constants" do
    test "pushes data to stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_0, "test123", :OP_TRUE, :OP_1NEGATE, :OP_10])
      assert vm.stack == [10, -1, 1, "test123", <<>>]
    end
  end


  describe "2. Flow control" do
    test "evals truthy side of OP_IF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_IF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["foo"]
    end

    test "evals falsey side of OP_IF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_0, :OP_IF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["bar"]
    end

    test "evals truthy side of OP_NOTIF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_NOTIF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["bar"]
    end

    test "evals falsey side of OP_NOTIF block", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_0, :OP_NOTIF, "foo", :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["foo"]
    end

    test "handles nested OP_IF blocks", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_IF, "foo", :OP_IF, "qux", :OP_ENDIF, :OP_ELSE, "bar", :OP_ENDIF])
      assert vm.stack == ["qux"]
    end
  end


  describe "3. Stack" do
    test "OP_TOALTSTACK moves top of stack to alt stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_TOALTSTACK])
      assert vm.stack == [1]
      assert vm.alt_stack == [2]
    end

    test "OP_FROMALTSTACK moves top of alt stack to stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_TOALTSTACK, :OP_FROMALTSTACK])
      assert vm.stack == [2, 1]
      assert vm.alt_stack == []
    end

    test "OP_2DROP removes top two items from stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_2DROP])
      assert vm.stack == [1]
    end

    test "OP_2DUP duplicates top two items on stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_2DUP])
      assert vm.stack == [2, 1, 2, 1]
    end

    test "OP_3DUP duplicates top three items on stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_3DUP])
      assert vm.stack == [3, 2, 1, 3, 2, 1]
    end

    test "OP_2OVER copies two items two spaces back on the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_9, :OP_9, :OP_2OVER])
      assert vm.stack == [2, 1, 9, 9, 2, 1]
    end

    test "OP_2ROT moves the 5th and 6th items to top of stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_6, :OP_2ROT])
      assert vm.stack == [2, 1, 6, 5, 4, 3]
    end

    test "OP_2SWAP swaps the top two pairs of items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_2SWAP])
      assert vm.stack == [2, 1, 4, 3]
    end

    test "OP_IFDUP duplicates the top item if it is truthy", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_IFDUP])
      assert vm.stack == [2, 2, 1]
    end

    test "OP_IFDUP wont duplicate the top item if it is not truthy", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_0, :OP_IFDUP])
      assert vm.stack == [<<>>, 1]
    end

    test "OP_DEPTH puts the stack length on top of the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_DEPTH])
      assert vm.stack == [4, 4, 3, 2, 1]
    end

    test "OP_DROP removes the top stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_DROP])
      assert vm.stack == [2, 1]
    end

    test "OP_DUP duplicates the top stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_DUP])
      assert vm.stack == [2, 2, 1]
    end

    test "OP_NIP removes the 2nd stack item", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_NIP])
      assert vm.stack == [2]
    end

    test "OP_OVER copies the 2nd stack item to the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_OVER])
      assert vm.stack == [1, 2, 1]
    end

    test "OP_PICK copies the nth stack item to the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_4, :OP_PICK])
      assert vm.stack == [1, 5, 4, 3, 2, 1]
    end

    test "OP_ROLL moves the nth stack item to the top", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_4, :OP_ROLL])
      assert vm.stack == [1, 5, 4, 3, 2]
    end

    test "OP_ROT rotates the top 3 items", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_4, :OP_5, :OP_ROT])
      assert vm.stack == [3, 5, 4, 2, 1]
    end

    test "OP_SWAP swaps the top two items on the stack", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_SWAP])
      assert vm.stack == [2, 3, 1]
    end

    test "OP_TUCK copies the top stack item and inserts 2 behind", %{vm: vm} do
      {:ok, vm} = VM.eval(vm, [:OP_1, :OP_2, :OP_3, :OP_TUCK])
      assert vm.stack == [3, 2, 3, 1]
    end
  end


end
