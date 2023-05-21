# brebase

`brebase` command do rebase git merge strategy
by `push` or `pull` sub command to local another branch
like `git push|pull` command to|from remote repository.

    export BREBASE_MAIN_BRANCH=____
    brebase push  (or)  brebase pull

However, set the `BREBASE_MAIN_BRANCH` environment variable
to the name of the main feature branch before running brebase.

Exammple:
    ...
    $ git checkout  A   #// Working on A branch
    $ git commit -m "A1"
    $ export BREBASE_MAIN_BRANCH=F
    $ brebase push  #// Merge to F branch
    ...
    $ git commit -m "A2"
    $ brebase push
    WARNING: brebase push did not merge from "A" to "F", because "A" is behind "F".
    $ brebase pull  #// Merge from F branch
    $ brebase push  #// Merge to F branch


<!-- TOC depthFrom:1 -->

- [brebase](#brebase)

<!-- /TOC -->


## Push command


### (Set up) General git commit command

Commit graph before `git commit`:

    F&A

`git commit` command:

    git checkout A
    git add .
    git commit -m "A1"

Commit graph after `git commit`:

    F - A


### When your branch A is AHEAD of main feature branch F

Move feature branch F to the current commit position on branch A.

Commit graph before `brebase push`:

    F - A

`brebase push` command:

    $ export BREBASE_MAIN_BRANCH=F
    $ brebase push

Commit graph after `brebase push`:

    o - F&A


### When your branch B is BEHIND main feature branch F

Just warn. The exit code is 0 (successful).

Commit graph before `git commit`:

    B - F&A

`git commit` command:

    $ git add .
    $ git commit -m "B1"

Commit graph after `git commit` before `brebase push`:

        B
      /
    o - F&A

`brebase push` command:

    $ export BREBASE_MAIN_BRANCH=F
    $ brebase push
    WARNING: brebase push did not merge from "A" to "F", because "A" is behind "F".

Commit graph is not changed.

You must run `brebase pull` commad.


## Pull command

Run `git rebase __BranchName__` を実行します。

### When not in conflict

Commit graph before `brebase pull`:

        B
      /
    o - F&A

`brebase pull` command:

    $ export BREBASE_MAIN_BRANCH=F
    $ brebase pull

Commit graph after `brebase pull`:

              B
            /
    o - F&A

`brebase push` command:

    $ export BREBASE_MAIN_BRANCH=F
    $ brebase push

Commit graph after `brebase push`:

    o - A - F&B

### When in conflict

Commit graph before `brebase pull`:

        B
      /
    o - F&A

`brebase pull` command:

    $ export BREBASE_MAIN_BRANCH=F
    $ brebase pull

    git rebase "feature-1"
    Auto-merging 0.txt
    CONFLICT (content): Merge conflict in 0.txt
    error: could not apply d05667c... B1
    hint: Resolve all conflicts manually, mark them as resolved with
    hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
    hint: You can instead skip this commit: run "git rebase --skip".
    hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
    Could not apply d05667c... B1

It displays there was a conflict when running the `git rebase` command inside.

The exit code is 1.

Please edit the conflicted files to resolve the conflict
and complete by running `git rebase --continue`.

    vi 0.txt
    git add  "."
    git rebase --continue

Commit graph after `git rebase --continue`:

              B
            /
    o - F&A

`brebase push` command:

    $ export BREBASE_MAIN_BRANCH=F
    $ brebase push

Commit graph after `brebase push`:

    o - A - F&B

## Status command

Run the `git status` command and
display if `brebase push` or `brebase pull` command needs to be run.
Every messages are printed to standard output.
The exit code is 0 (successful).

    $ export BREBASE_MAIN_BRANCH=____
    $ brebase status
    (git status output)
    WARNING: Your branch is behind '____'. Hint: run "brebase pull" and "brebase push" command.
    Your branch is ahead of '____'. Hint: run "brebase push" command.

If it is clean, nothing will be displayed.

    $ export BREBASE_MAIN_BRANCH=____
    $ brebase status
    $

When shell script branches, check the following phrase.

    Your branch is behind
    Your branch is ahead
