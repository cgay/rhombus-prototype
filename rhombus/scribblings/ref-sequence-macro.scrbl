#lang scribble/rhombus/manual
@(import:
    "common.rhm" open
    "nonterminal.rhm" open
    "macro.rhm")

@(def macro_eval: macro.make_macro_eval())

@(def dollar: @rhombus($))

@title{Sequence Macros}

@doc(
  ~nonterminal:
    outer_expr: block expr
    recur_id: block id
    recur_init_expr: block expr
    inner_expr: block expr
    outer_check_body: block body
    head_guard_body: block body
    pre_guard_body: block body
    post_guard_body: block body
    recur_arg_expr: block expr
    loop_body: block body
    done_expr: block expr

  class_clause.macro '«sequence '$pattern':
                         $body
                         ...»'
  interface_clause.macro '«sequence '$pattern':
                             $body
                             ...»'
){

 Forms for @rhombus(class) or @rhombus(interface) to supply an
 optimizing conversion in an @rhombus(each, ~for_clause) clause of @rhombus(for).
 The conversion applies whenever the right-hand side of
 @rhombus(each, ~for_clause) has static information for the class or
 interface containing the @rhombus(sequence, ~class_clause) declaration.
 Normally, @rhombus(sequence, ~class_clause) should be used in a class
 that implements @rhombus(Sequenceable, ~class) as the non-optimizing implementation.

 The input @rhombus(pattern) is matched to @rhombus(id ...: expr) where
 @rhombus(expr) is a @tech{parsed} expression for the right-hand side of
 @rhombus(each, ~for_clause), and the number of @rhombus(id)s reflects
 the number of expected result values. The result of the @rhombus(body)
 sequence must be either @rhombus(#false), in which case the
 implementation falls back to dynamic mode, or a syntax object of the
 form

@rhombusblock(
  '(~outer_binds:
      #,(@rhombus(outer_ids, ~var)): outer_expr
      ...,
    ~outer_check:
      outer_check_body
      ...,
    ~recur_binds:
      recur_id = recur_init_expr
      ...,
    ~head_guard:
      head_guard_body
      ...,
    ~inner_binds:
      #,(@rhombus(inner_ids, ~var)): inner_expr
      ...,
    ~pre_guard:
      pre_guard_body
      ...,
    ~post_guard:
      post_guard_body
      ...,
    ~recur_args:
      (recur_arg_expr, ...))'
)

 where each @rhombus(inner_ids, ~var) and @rhombus(outer_ids, ~var) is
 either an identifier or a parenthsized sequence of comma-separated
 identifiers. The keywords in this shape must appear in the shown order,
 but each is optional and defaults to either an empty binding sequence
 or a body sequence that produces @rhombus(#true).

 These pieces are integrated into a larger expression of roughly the
 following form, where @rhombus(loop_body) is an iteration body, and
 @rhombus(done_expr) is the reducer-generated result.

@rhombusblock(
  // bind and/or unpack the sequence
  let #,(@rhombus(outer_ids, ~var)) = outer_expr
  ...
  // maybe check that sequence is valid
  outer_check_body 
  ...
  // bind loop arguments, especially as the iteration position
  let recur_id = recur_init_expr
  ...
  fun loop(recur_id = recur_id, ...):
    if (block: head_guard_body; ...) // check continues at this position
    | let #,(@rhombus(inner_ids, ~var)) = inner_expr // bind variables for element 
      ...
      if (block: pre_guard_body; ...) // check continues for this element
      | loop_body
        ...
        if (block: post_guard_body; ...) // check continues *after* this
        | loop(recur_arg_expr, ...) // update the position for next iteration
        | done_expr
      | done_expr
    | done_expr
  loop()
)

 Typically, @rhombus(inner_ids, ~var) includes the the @rhombus(id)s
 supplied to the match for @rhombus(pattern), so they can be referenced
 in @rhombus(loop_body).

@examples(
  ~eval: macro_eval
  ~defn:
    class Posn(x, y):
      implements Sequenceable
      override method to_sequence():
        Sequence.make(~initial_position: 0,
                      ~continue_at_position: fun (i): i < 2,
                      ~position_to_next: fun (i): i + 1,
                      ~position_to_element: fun (i):
                                              if i == 0 | y | x)
      sequence '$lhs: $rhs':
        '(~outer_binds:
            p = $rhs,
          ~recur_binds:
            pos = 0,
          ~head_guard:
            pos < 2,
          ~inner_binds:
            $lhs = if pos == 0 | Posn.y(p) | Posn.x(p),
          ~recur_args:
            (pos + 1))'
  ~repl:
    for List:
      each j: dynamic(Posn(1, 2)) // uses `to_sequence`
      j
    for List:
      each j: Posn(1, 2) // uses `sequence` expansion
      j
)

}

@«macro.close_eval»(macro_eval)
