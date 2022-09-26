defmodule ExpressionParserTest do
  use ExUnit.Case
  doctest ExpressionParser

  test "tokenize" do
    assert ExpressionParser.tokenize(" ( 123 +   55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:operator,"+"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var- 55)") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:operator,"-"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( var * 55) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:operator,"*"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123 / 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:operator,"/"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var <= 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,"<="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var >= 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,">="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var < 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,"<"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var > 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,">"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123!= 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:comparator,"!="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123= 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:comparator,"="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123 @ 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:illegal_char,"@"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123 + 55) <= 3500 ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:operator,"+"}, {:number,"55"}, {:closing_parenthesis,")"}, {:comparator,"<="}, {:number,"3500"}]
  end

  test "add" do
    assert ExpressionParser.add(nil,{:number,"51"}) == {{:number, "51"}, nil, nil}
    assert ExpressionParser.add(nil,{:variable,"x"}) == {{:variable,"x"},nil,nil}
    assert ExpressionParser.add({{:variable,"x"},{:operator,"+"},nil},{:variable,"x"}) == {{:variable,"x"},{:operator,"+"},{:variable,"x"}}
    assert ExpressionParser.add({{:variable,"x"},{:operator,"+"},{{:variable,"x"},{:operator,"+"},nil}},{:variable,"y"}) == {{:variable,"x"},{:operator,"+"},{{:variable,"x"},{:operator,"+"},{:variable,"y"}}}
  end

  test "parse" do
    tokenized_char = ExpressionParser.tokenize(" 123 + 55 ")
    assert ExpressionParser.parse(tokenized_char,nil) == {{:number, "123"}, {:operator, "+"}, {:number, "55"}}
    tokenized_char = ExpressionParser.tokenize("3*4 + 6 + 4*5 ")
    assert ExpressionParser.parse(tokenized_char,nil) == {{{{:number, "3"}, {:operator, "*"}, {:number, "4"}},{:operator, "+"}, {:number, "6"}}, {:operator, "+"},{{:number, "4"}, {:operator, "*"}, {:number, "5"}}}
    tokenized_char = ExpressionParser.tokenize("3*4 + 6 + 4*5 <= 3*4 + 6 + 4*5")
    assert ExpressionParser.parse(tokenized_char,nil) == {{{{{:number, "3"}, {:operator, "*"}, {:number, "4"}},{:operator, "+"}, {:number, "6"}}, {:operator, "+"},{{:number, "4"}, {:operator, "*"}, {:number, "5"}}},{:comparator, "<="},{{{{:number, "3"}, {:operator, "*"}, {:number, "4"}},{:operator, "+"}, {:number, "6"}}, {:operator, "+"},{{:number, "4"}, {:operator, "*"}, {:number, "5"}}}}
  end

  test "parse error handling" do
    tokenized_char_with_illegal_char = ExpressionParser.tokenize(" 123 @ 55 ")
    assert_raise(RuntimeError, "illegal char in the expression", fn  -> ExpressionParser.parse(tokenized_char_with_illegal_char,nil) end)
    tokenized_char_with_two_comparators = ExpressionParser.tokenize(" 123 = 4 <= 55 ")
    assert_raise(RuntimeError, "can't have two comparators in one expression", fn  -> ExpressionParser.parse(tokenized_char_with_two_comparators,nil) end)
    tokenized_char_with_illegal_comparator = ExpressionParser.tokenize("= 123 + 55 ")
    assert_raise(RuntimeError, "can't start expression with a comparator", fn  -> ExpressionParser.parse(tokenized_char_with_illegal_comparator,nil) end)
    tokenized_char_with_illegal_comparator = ExpressionParser.tokenize(" 123 = + 55 ")
    assert_raise(RuntimeError, "can't put operator just after operator or comparator", fn  -> ExpressionParser.parse(tokenized_char_with_illegal_comparator,nil) end)
    tokenized_char_with_illegal_oparator = ExpressionParser.tokenize("3*4 + 6 + 4*5 <= 3*4 + 6 + + 4*5")
    assert_raise(RuntimeError, "can't put operator just after operator or comparator", fn  -> ExpressionParser.parse(tokenized_char_with_illegal_oparator,nil) end)
    tokenized_char_with_illegal_variable = ExpressionParser.tokenize("3*4 + 6 + 4*5 <= 3 y")
    assert_raise(RuntimeError, "can't put variable just after number or variable", fn  -> ExpressionParser.parse(tokenized_char_with_illegal_variable,nil) end)
  end

  test "eval" do
    assert ExpressionParser.eval("4<3",%{}) == false
    assert ExpressionParser.eval("x<z",%{"x"=>3,"z"=>10}) ==true
    assert ExpressionParser.eval("3*4 + 6 + 4*5 <= 3*y",%{"y"=>40}) == true
    assert ExpressionParser.eval("3*4 + 6 + 40/5 = 3+y",%{"y"=>40}) == false
  end
end
