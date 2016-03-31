# Development Workflow

## How & Where to Code

Use any editor you like, but **follow these steps for `git`**.

### Code in Branches

Say you're working on `fancyNewBuiltin()`

**tl;dr** _new_ branch for _every_ feature, `git diff` before committing!!

1. ensure your git repo is clean: `git status` _(and no output)_
2. `git checkout -b [yourhandle]-add-fancy-new-builtin`
3. before writing code:
  - [write tests](../src/#writing-tests)
  - ensure they `FAIL`, since you haven't coded yet
  - `git push origin [yourhandle]-add-fancy-new-builtin`
4. [open a pull request](https://help.github.com/articles/creating-a-pull-request/)
5. do these **until tests pass** and you're done:
  - write code
  - `make test`
  - `git diff` & **ensure** you like the diff!!
  - commit as you like
  - address questions in pull request
6. [merge your branch](https://help.github.com/articles/merging-a-pull-request/)
  when its: **green** and **comments are resolved**
7. `git branch -d [yourhandle]-add-fancy-new-builtin`
8. back to step #1 with for **new branch name**

### Collaborating in Branches

Say tianci is working on "cool-feature". I (jon) want to use her work:

Q: How do I work with someone else's in-progress branch, `tianci-cool-feature`?
A:

1. ensure you're in a clean repo: `git status` _(should output nothing)_
2. ensure your laptop's updated: `git fetch --all`
3. **start your own branch**, eg: for `jon-cool-feature` do:
   `git checkout -b jon-cool-feature origin/tianci-cool-feature`

Now just continue with a normal ["Code in Branches"](#code-in-branches) process.

Q: I'm Tianci, how do I get Jon's fork back into my branch? A:

1. ensure you're in a clean repo: `git status` _(should output nothing)_
2. ensure your laptop's updated: `git fetch --all`
3. ensure your'e in original branch: `git branch` outputs  `tianci-cool-feature`
4. Merge the fork of your branch back in: `git merge origin/jon-cool-feature`

It helps if you're talking to each other, of course, to avoid confusion :)
