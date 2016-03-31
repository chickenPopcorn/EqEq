# Development Workflow

Use any editor you like, but **follow these steps for `git`**.

## How & Where to Code

The high-level overview of git is:

1. `git checkout` a **branch** to [isolate your work](#code-in-branches)
  - `git branch` to **verify** you're in your branch
2. Edit files _(open your text editor, change stuff, **save**)_
3. `git status && git diff` to **really** verify step #2 went as planned!
4. `make test` to see what our **tests think** you did
5. happy with #3 & #4? No matter how small the change _(smaller is better)_:
  - tell git about *just* what to commit: `git add path/to/speicific-file`
  - `git commit 'fixed typo, dog not spelled "doog"'`
  - `git status` to verify it worked
6. share with everyone: `git push origin your-branch-name`

Each of these ^ steps is detailed more below and in ["Coding, Building,
Testing"](#coding-building-testing).

### Code in Branches

Say you're working on `fancyNewBuiltin()`

**tl;dr** _new_ branch for _every_ feature, `git diff` before committing!!

1. `git checkout -b [yourhandle]-add-fancy-new-builtin`
2. **test your feature**, before create it:
  - [write new tests](../src/#writing-tests) for your `fancyNewBuiltin()`
  - ensure it `FAIL`s, since you haven't coded yet
  - `git push origin [yourhandle]-add-fancy-new-builtin`
3. [open pull request](https://help.github.com/articles/creating-a-pull-request/) for `[yourhandle]-add-fancy-new-builtin`
4. **do in loop**, until tests `PASS`:
  - write code for `fancyNewBuiltin()`
  - `make test`
  - `git diff` & `git commit` whatever small pieces you like
  - answer any questions in pull request
5. [merge your branch](https://help.github.com/articles/merging-a-pull-request/)
  when its: **green** and **comments are resolved**
6. to **cleanup on laptop**:
  - fetch your new merge: `git checkout master && git fetch --all && git pull origin master`
  - delete yor laptop's branch: `git branch -d [yourhandle]-add-fancy-new-builtin`

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
