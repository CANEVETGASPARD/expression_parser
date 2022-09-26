defmodule ExpressionParser do
  @moduledoc """
  Documentation for `ExpressionParser`.
  """

  @doc """
  take a char chain as input and return the list of char chain elements.
  """
  def tokenize(char_chain) do
    String.split(char_chain,~r{\s|\(|\)|\+|\-|\*|\/|=|!=|<=|<|>=|>}, trim: true, include_captures: true)
    |> Enum.filter(fn value -> value != " " end)
    |> Enum.map(fn char -> identify_char(char) end)
  end

  @doc """
  take a char element as input and return the tuple made of its class atom and its value
  """
  def identify_char(char) do
    cond do
      String.match?(char, ~r{^([0-9]*)$}) -> {:number, char}
      String.match?(char, ~r{^([a-z]*)$}) -> {:variable, char}
      String.match?(char, ~r{\(}) -> {:opening_parenthesis, char}
      String.match?(char, ~r{\)}) -> {:closing_parenthesis, char}
      String.match?(char, ~r{\+|\-|\*|\/}) -> {:operator, char}
      String.match?(char, ~r{!=|=|<=|<|>=|>}) -> {:comparator, char}
      true -> {:illegal_char, char}
    end
  end

  @doc """
  take the tokenized list of the char chain and predifined nil object as input and return the tree of the given list.
  """
  def parse(token, tree \\nil)

  def parse([],tree) do
      tree
    end
  def parse([head|tail],tree) do
    {validity_atom,validity_message} = check_validity(tree,head)
    case validity_atom do
      :error -> raise(validity_message)
      _ -> parse(tail,add(tree,head))
    end
  end

  @doc """
  take the tree of the char chain and a char tuple as input and return the tree with the new element added
  """
  def add(tree,char_tuple_to_add)

  def add(nil, {char_class,char_value}) do
    {{char_class,char_value},nil,nil}
  end
  def add({left_tree,mid_element,right_tree},{char_class,char_value}) do
    case {char_class,mid_element} do
      {:comparator, nil} -> {left_tree,{char_class,char_value},right_tree}
      {:comparator, _} -> {{left_tree,mid_element,right_tree},{char_class,char_value},nil}
      {:operator, nil} -> {left_tree,{char_class,char_value},right_tree}
      {:operator, {mid_element_atom,_}} -> cond do
        mid_element_atom == :comparator -> case right_tree do
          {_,_,_} ->{left_tree,mid_element,add(right_tree,{char_class,char_value})}
          _ -> {left_tree,mid_element,{right_tree,{char_class,char_value},nil}}
        end
        String.match?(char_value, ~r{\*|\/}) -> {left_tree,mid_element,{right_tree,{char_class,char_value},nil}}
        true -> {{left_tree,mid_element,right_tree},{char_class,char_value},nil}
      end
      {_, nil} -> case left_tree do
        nil -> {{char_class,char_value},mid_element,right_tree}
        _ -> {add(left_tree,{char_class,char_value}),mid_element,right_tree}
      end
      {_,_} -> case right_tree do
        nil -> {left_tree,mid_element,{char_class,char_value}}
        _ -> {left_tree,mid_element,add(right_tree,{char_class,char_value})}
      end
    end
  end

  @error_message %{:on_start => %{
    :comparator => "can't start expression with a comparator",
    :operator => "can't start expression with an operator",
     },
  :after_variable_or_number => %{
    :number => "can't put number just after number or variable",
    :variable => "can't put variable just after number or variable",
    },
  :after_operator_or_comparator => %{
    :comparator => "can't put comparator just after operator or comparator",
    :operator => "can't put operator just after operator or comparator",
    }
  }

  @doc """
  take the tree of the char chain and a char tuple to add as input and return a tuple {:error, error_message} if there is an error or a {nil,nil} tuple otherwise.
  """
  def check_validity(tree,char_to_add)

  def check_validity(_,{:illegal_char,_}) do
    {:error,"illegal char in the expression"}
  end
  def check_validity({_,{:comparator,_},_},{:comparator,_}) do
    {:error,"can't have two comparators in one expression"}
  end
  def check_validity(nil,{char_class,_}) do
    cond do
      Map.has_key?(@error_message[:on_start],char_class) -> {:error,@error_message[:on_start][char_class]}
      true -> {nil,nil}
    end
  end
  def check_validity({_,nil,_},{char_class,_}) do
    cond do
      Map.has_key?(@error_message[:after_variable_or_number],char_class) -> {:error,@error_message[:after_variable_or_number][char_class]}
      true -> {nil,nil}
    end
  end
  def check_validity({_,_,nil},{char_class,_}) do
    cond do
      Map.has_key?(@error_message[:after_operator_or_comparator],char_class) -> {:error,@error_message[:after_operator_or_comparator][char_class] }
      true -> {nil,nil}
    end
  end
  def check_validity({_,_,right_tree},{char_class,char_value}) do
    case right_tree do
      {_,_,_} -> check_validity(right_tree,{char_class,char_value})
      _ -> cond do
        Map.has_key?(@error_message[:after_variable_or_number],char_class) -> {:error,@error_message[:after_variable_or_number][char_class]}
        true -> {nil,nil}
      end
    end
  end

  @doc """
  take the char chain and the variable table (if there is at least one variable in the equation) as input and return true if the equation is verified and false if it is not.
  """
  def eval(char_chain, var_table \\ %{}) #function header with predefined empty var table

  def eval(char_chain,var_table) do
    tokenize(char_chain)
    |> parse
    |> eval_tree(var_table)
  end

  @doc """
  take the tree and the variable table as input and return true if the equation is verified and false if it is not.
  """
  def eval_tree(tree,var_table)

  def eval_tree({:number,value},_) do
    {parsed_float,_} =Float.parse(value)
    parsed_float
  end
  def eval_tree({:variable,value},var_table) do
    var_table[value]
  end
  def eval_tree({left_tree,mid_element,right_tree},var_table) do
    left_sub_tree = eval_tree(left_tree,var_table)
    right_sub_tree = eval_tree(right_tree,var_table)
    do_expression({left_sub_tree,mid_element,right_sub_tree})
  end

  @doc """
  take the tree and the variable table as input and return a value if it is an operator or a boolean if it is a comparator
  """
  def do_expression({left_tree_value,{_,mid_element_value},right_tree_value}) do
    cond do
      mid_element_value == "=" -> left_tree_value == right_tree_value
      mid_element_value == "!=" -> left_tree_value != right_tree_value
      mid_element_value == "<" -> left_tree_value < right_tree_value
      mid_element_value == "<=" -> left_tree_value <= right_tree_value
      mid_element_value == ">" -> left_tree_value > right_tree_value
      mid_element_value == ">=" -> left_tree_value >= right_tree_value
      mid_element_value == "+" -> left_tree_value + right_tree_value
      mid_element_value == "-" -> left_tree_value - right_tree_value
      mid_element_value == "*" -> left_tree_value * right_tree_value
      mid_element_value == "/" -> left_tree_value / right_tree_value
    end
  end
end
