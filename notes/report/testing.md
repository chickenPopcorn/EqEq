EqEq compiler has had _passing_ end-to-end tests from the [start][812f6446e1b12c9] - from the moment a basic "hello world" was compiling.

## Test Strategies: `make e2e`
Our compiler uses two types of test-coverage: the main tests via `make test` and extraneous tests, via `make lint`
 1. `make test`: this runs every `tests/{test,fail}-*.eq` file through the compiler - `eqeq.native` - and for each:
 
  | test file  | `eqeq.native` exit status | compared outputs |
  |------------|---------------------------|------------------|
  | `test-NAME.eq` | `0` (zero) | resulting target program output matches `test-NAME.out` golden sample |
  | `fail-NAME.eq` | `!= 0` (non-zero) | `./eqeq.native` error matches `fail-NAME.err` golden sample |
  
 2. `make lint`: anything general to _building_ our compiler

    eg: early on, this ensured our scanner/parser phase didn't produce
    `shift-reduce` warnings _(at one point, accidentally ignored)_

## Policy: Changes Must be Tested

Each change to the compiler - feature or bug-fix - was explicity required to be committed with a **new** test file before
being merged into `master`. In fact, the [official recommended steps to work on the compiler][contributing_guide] states:

> before creating [your new change] write tests for it [and] **ensure it FAILs**

When developing, members relied on `make test`'s report to look for their new test's red or green "FAIL"/"PASS" indicator.
This single testing command (`make test`) ran all of the compiler's existing tests as well. The benefit of this approach
was that, other team members could focus solely on their own feature's side-effect and get immediate, unsolicitated feedback
in the event of an inadvertent regression.

## Automation: `master` Must Pass

The compiler's github codebase is configured to send each `master` commit (including merges) to the popular automated test
[runner travis-ci.org](e2e) for a `make e2e` run. This means we all knew immediately if someone made a mistake and merged
their in-progress work from an experimental branch, into `master`, before it was ready. This came in handy more than once,
where we were able to simply revert the offending merge and get `master` passing again _(facilitating others to
keep branching for the next milestone)_.

## Strong Coverage
As a result, the compiler's codebase currently has over **120 test-EqualsEquals programs**, that [run with every merge][testrun].

[contributing_guide]: https://github.com/rxie25/PLT2016Spring/blob/f8cc35c95840d2a4be2b63940ec347ea44cfce78/src/CONTRIBUTING.md#code-in-branches
[812f6446e1b12c9]: https://github.com/rxie25/PLT2016Spring/commit/812f6446e1b12c9#diff-10
[e2e]: https://travis-ci.org/rxie25/PLT2016Spring
[testrun]: https://travis-ci.org/rxie25/PLT2016Spring/builds/128711835#L618
