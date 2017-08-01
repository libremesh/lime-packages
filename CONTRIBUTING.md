# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method before making a change. 

Please note we have a code of conduct, please follow it in all your interactions with the project.

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

4. Checkout the `develop` branch.
   ```git checkout develop```

### Branching

Any changes that are made to the lime-packages code-base should be done in their own branch.  The branch
should be made from the tip of `develop`, which is the development branch.  Before starting
any piece of work, ensure that you fetch the latest upstream changes from the repository.
Doing so will ensure that you have an up-to-date copy of `develop`, that changes made by others
will not be lost, and will also reduce the chances of conflicts when it comes time to merging the
changes back to lime-packages.

#### Branch Names

There is only one key branch:

- `develop`: this branch is the working version that is currently under development.  All
    new feature branches should be made from the tip of `develop` and all PR's should have `develop`
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

   ```git fetch upstream develop```

2. Check-out you copy of develop and merge the upstream changes:

    ```git checkout develop```
    
    ```git merge upstream/develop```

    You now have an up-to-day copy of the `develop` branch.

3. Create a new branch for your changes:

    ```git checkout -b <branch name>```

4. Make your changes

5. Push the changes to `origin` (i.e. your fork)

    ```git push origin <branch name>```

6. Create a new Pull Request (see below).

#### Creating A Pull Request

In order to integrate your changes into the main lime-packages repository, you will
need to create a *Pull Request* in GitHub.

1. Log into GitHub and go to your fork of lime-packages.

2. Click "New Pull Request"

3. Make sure that the following properties are set:

    - Base fork = `libremesh/lime-packages`
    - Base = `develop`
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
rather than doing so on develop.

In order to do so:

1. Fetch the latest changes from the upstream `develop` branch

    ```git fetch upstream develop```

2. Make sure that you are on your feature branch.

3. Merge the upstream changes into develop.  You will see "conflict messages"

    ```git merge upstream/develop```
     
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

For more information, please see [Collaborating on projects using issues and pull requests](https://help.github.com/categories/collaborating-on-projects-using-issues-and-pull-requests/) in the GitHub help guide.
