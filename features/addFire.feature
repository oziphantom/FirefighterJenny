Feature: 
    Test the MulBy40

    Scenario Outline: Test Mul 40 + x4 
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <in>
      When I execute the procedure at AddFire for no more than 800000 instructions until PC = AddFireEndOf32BitMul
      Then I expect to see Pointer1 equal <lo>
      Then I expect to see Pointer1+1 equal <hi>

    Examples:
    | in | lo  | hi  |
    | 1  | 160 | $70 |
    | 5  | $20 | $73 |
    | 10 | $40 | $76 |
    | 40 | $00 | $89 |

    Scenario Outline: Test the Sub case Negative
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <in>
      And I write memory at LevelLinePtr with <ptrLo>
      And I write memory at LevelLinePtr+1 with <ptrHi>
      When I execute the procedure at AddFire for no more than 800000 instructions until PC = AddFireEndOf32BitMul__exit
      #Then I expect to see register st contain <result>
      Then I expect to see Pointer2+1 greater than 128

      Examples:
      |in|ptrLo|ptrHi|
      |1 | $e8 | $73 |
      |6 | $e8 | $73 |
  
  Scenario Outline: Test the Sub case Positive
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <in>
      And I write memory at LevelLinePtr with <ptrLo>
      And I write memory at LevelLinePtr+1 with <ptrHi>
      When I execute the procedure at AddFire for no more than 800000 instructions until PC = AddFireEndOf32BitMul__exit
      #Then I expect to see register st contain <result>
      Then I expect to see Pointer2+1 less than 128

      Examples:
      |in|ptrLo|ptrHi|
      |25| $e8 | $73 |
      |40| $e8 | $73 |

Scenario Outline: Test the Sub case Negative in Range
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <in>
      And I write memory at LevelLinePtr with <ptrLo>
      And I write memory at LevelLinePtr+1 with <ptrHi>
      When I execute the procedure at AddFire for no more than 800000 instructions until PC = AddFireEndOf32BitMul__exit
      #Then I expect to see register st contain <result>
      Then I expect to see Pointer2+1 greater than 251 
      # 251 > -4

      Examples:
      |in|ptrLo|ptrHi|
      |1 | $e8 | $73 |
      |6 | $e8 | $73 |

Scenario Outline: Test the Sub case Negative out of Range
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <in>
      And I write memory at LevelLinePtr with <ptrLo>
      And I write memory at LevelLinePtr+1 with <ptrHi>
      When I execute the procedure at AddFire for no more than 800000 instructions until PC = AddFireEndOf32BitMul__exit
      #Then I expect to see register st contain <result>
      Then I expect to see Pointer2+1 greater than 128
      Then I expect to see Pointer2+1 less than 251 
      # 251 > -4

      Examples:
      |in|ptrLo|ptrHi|
      |1 | $e8 | $80 |
      |6 | $e8 | $80 |

Scenario Outline: Test the logic map is updated 
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <y>
      And I write memory at Random with <x>
      And I write memory at LevelLinePtr with $e8
      And I write memory at LevelLinePtr+1 with $73
      When I execute the procedure at AddFire for no more than 800000 instructions
      Then I expect to see <loc> equal 3
      

      Examples:
      | y | x | loc |
      | 0 | 0 |$500 |
      | 0 | 1 |$501 |
      | 1 | 0 |$508 |
      |32 | 0 |$600 |

Scenario Outline: Test the screen dump map is updated
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <y>
      And I write memory at Random with <x>
      And I write memory at LevelLinePtr with $e8
      And I write memory at LevelLinePtr+1 with $73
      When I execute the procedure at AddFire for no more than 800000 instructions
      Then I expect to see <loc> equal 128

      Examples:
      | y | x | loc  |
      | 0 | 0 |$702D |
      | 0 | 1 |$7031 |
      | 1 | 0 |$70CD |
      |32 | 0 |$842D |

Scenario Outline: Test the screen is updated
      Given I have a simple overclocked 6502 system
      And I load prg "firefighterJenny.prg_test"
      And I load labels "firefighterJenny.acme"
      And I write memory at Random+1 with <y>
      And I write memory at Random with <x>
      And I write memory at LevelLinePtr with $e8
      And I write memory at LevelLinePtr+1 with $73
      When I execute the procedure at AddFire for no more than 800000 instructions
      Then I expect to see <loc> equal 128

      Examples:
      | y | x | loc  |
      | 0 | 0 |$3775 |
      | 0 | 1 |$3779 |
      | 1 | 0 |$36D5 |
      | 5 | 0 |$3455 |