# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method before making a change. 

Please note we have a code of conduct, please follow it in all your interactions with the project.


## How to use AI to contribute

We do not explicitly encourage the employment of Artificial Intelligence tools, like LLM and
coding assistants. But we do not forbid it neither, and we will not discard contributions made
using AI-LLM tools. You can use such tools for contributing to the LibreMesh project respecting
the following requirements:

### Be honest and transparent, tell us how much you used AI for your contribution

It is not the same to review a human-written contribution or a LLM-written one.
Humans make typos and small mistakes, while LLM make conceptual errors, useless tests and
duplicated code.
For helping the code review process, we ask you to disclose if, how much and which AI-LLM you used
(e.g., "I used XYZ for writing the code but then I checked every detail myself").

### Make sure you learn something

LibreMesh is about empowering communities giving them an easy to use tool for creating mesh
networks. But it is also about allowing users to get empowered becoming developers.
When you contribute, make sure you understand what you are doing and learn something new.
If you cannot understand what AI wrote, ask for help in the
[LibreMesh communication channels](https://github.com/libremesh/lime-packages/tree/master#get-in-touch-with-libremesh-community).

### Be critical, check the code with your own brain

As mentioned above, LLM can make conceptual errors and write useless or duplicate code.
Please use your own judgment and properly check the code. Then execute the code on your host or
router or virtual machine before submitting it for review.

### Take responsibility

When you submit some code, we will assume that you thoroughly checked and tested it
in a virtual machine or on a real device. If AI makes bad code, either improve it yourself
or avoid contributing it. Respect the opinion of the reviewers even if AI disagrees.


## Forks and Pull Requests

Development on lime-packages follows the Fork and Pull Request method popularized by GitHub:

- Every contributor has their own complete copy, called a *Fork*
- Contributors implement features or fix bugs on their own fork in a feature branch.
- When the contributor wants to integrate their changes back into the main repository,
  they will create a *Pull Request*.

Each of these steps will be discussed in turn:

#### Forking

The first thing that you will need for development, is to create a new copy of the repository to
work on.  This is known as "Forking" and is a defining characteristic of distributed
SCM systems: each person works on their own complete copy of the repository.  Git is designed to
make it trivially easy to keep these repositories in sync by passing signed revisions amongst the
individual copies.

In order to create a fork:

1. Log into GitHub and go to the [lime-packages GitHub repository](https://github.com/libremesh/lime-packages).

2. Click "Fork".  You should be redirected to a complete copy of the repository which now resides in your account.

3. On your workstation, create a clone of the Git repository:
    ```git clone git@github.com:<your-username>/lime-packages.git```
    This will create yet another complete copy of the repository: one that will reside
    on your workstation.

4. Checkout the `master` branch.
   ```git checkout master```

### Branching

Any changes that are made to the lime-packages code-base should be done in their own branch.  The branch
should be made from the tip of `master`, which is the development branch.  Before starting
any piece of work, ensure that you fetch the latest upstream changes from the repository.
Doing so will ensure that you have an up-to-date copy of `master`, that changes made by others
will not be lost, and will also reduce the chances of conflicts when it comes time to merging the
changes back to lime-packages.

#### Branch Names

There is only one key branch:

- `master`: this branch is the working version that is currently under development.  All
    new feature branches should be made from the tip of `master` and all PR's should have `master`
    set as the target.

For any new feature branches, the following naming convention is recommended:

### `<type>/<name>`

#### `<type>`
```
issue     - Code changes linked to a known issue.
feature   - New feature.
hotfix    - Quick fixes to the codebase.
sandbox   - Experiments (will never be merged).
```

#### `<name>`
Always use dashes to seperate words, and keep it short.

##### Examples
```
issue/133
feature/smonit
hotfix/driver-xxx
sandbox/new-crazy-thing
```

#### General Workflow

The general workflow for branching is as follows:

1. Fetch the latest changes from `upstream` (i.e. the main repository):

   ```git fetch upstream master```

2. Check-out you copy of `master` and merge the upstream changes:

    ```git checkout master```
    
    ```git merge upstream/master```

    You now have an up-to-day copy of the `master` branch.

3. Create a new branch for your changes:

    ```git checkout -b <branch name>```

4. Run the tests: read [[Testing docs](TESTING.md)].

5. Make your changes, we encourage you to try to add a test.

6. Make sure the tests are still running with success.

7. Run lint locally or set up the pre-push hook: to set up a git pre-push hook that runs lint locally, copy `tools/ci/lint/pre-push.sample` to `.git/hooks/pre-push` and make it executable.

8. Push the changes to `origin` (i.e. your fork)

    ```git push origin <branch name>```

9. Create a new Pull Request (see below).

#### Creating A Pull Request

In order to integrate your changes into the main lime-packages repository, you will
need to create a *Pull Request* in GitHub.

1. Log into GitHub and go to your fork of lime-packages.

2. Click "New Pull Request"

3. Make sure that the following properties are set:

    - Base fork = `libremesh/lime-packages`
    - Base = `master`
    - Head fork = your fork of lime-packages
    - Compare = the branch you wish to merge

4. Add a description of what the change is and click "Create Pull Request".

At this point, it is recommended to notify one of the other developers of the 
pull request and ask them to perform a quick review.  They will make any comments
in the pull request itself, which you should receive as GitHub notifications or as
emails.

Once the reviewer has OK the pull request, and GitHub has indicated that it can
be merged automatically, you are free to merge the pull request.

#### Dealing With Conflicts

Sometimes GitHub will report that the Pull Request cannot be merged automatically,
which usually means that there are merge conflicts.

It is usually a good idea to resolve the conflicts on the branch you are working on,
rather than doing so on `master`.

In order to do so:

1. Fetch the latest changes from the upstream `master` branch

    ```git fetch upstream master```

2. Make sure that you are on your feature branch.

3. Merge the upstream changes into master.  You will see "conflict messages"

    ```git merge upstream/master```
     
4. Use a merge tool to resolve the conflicts.  If one is configured with Git,
    running `git mergetool` should bring it up.  Some GUI tools like 
    [this](https://git-scm.com/download/gui/linux) have one built in.

5. Ensure that the merge was successful by building and testing the changes.

6. Commit the changes and push to origin.

     ```git commit```

     ```git push origin <branch>```

If you have a Pull Request already pending, GitHub should pick up the recent
changes and indicate that the PR is ready to be merged.


### More Information

For more information, please see [Quickstart for pull requests](https://docs.github.com/en/pull-requests/get-started/pull-request-quickstart) in the GitHub documentation.
