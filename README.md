# SWEN 426 _Advanced Software Implementation and Development_

## Assignment 2: Containerisation with Docker

The second assignment is to learn to use containerisation with Docker to support DevOps principles and practices: fast feedback, continuous integration, automation and immutable infrastructure. We will do this by (1) creating a Docker image for use in the GitLab CI/CD pipeline and (2) creating a Docker image which can be run as a container  serving your WordPress blog created in a previous assignment. You're expected to post your experiences to your blog as part of the assignment.

This assignment has a Core &ndash; Completion &ndash; Challenge structure weighted 50% &ndash; 30% &ndash; 20% of the assignment mark. Each stage has greater task difficulty than the preceding stage, so you may expect to spend more time attempting Challenge tasks than completing the Core requirements. Some Completion and Challenge tasks may be best addressed at the beginning of the assignment rather than at the end, you are expected to read the brief and plan your work based on the requirements you choose to meet.

You will need to have the Docker engine available to you for this assignment, either by installing Docker on your local machine or by using one of the ECS workstations. Using a package manager like Homebrew https://brew.sh (macOS) or APT (Debian/Ubuntu) is recommended for local installations, but manually downloading and running the Docker Desktop installing from <https://www.docker.com> is a viable alternative for all platforms. Not all ECS workstations have Docker available, you must use the workstations in Cotton [CO246](https://ecs.wgtn.ac.nz/cgi-bin/equip/room?location=CO246) from the console or via SSH.

### Core Requirements

To meet the core requirements of this assignment you must construct a  Dockerfile which will build an image suitable for running static analysis tests ("linting") automatically in the GitLab CI/CD pipeline [1].

The previous assignment required [pre-commit](https://pre-commit.com) to be installed locally, on the development machine, and to configure it to run various linting tests automatically on the files to be committed. It's desirable to run these tests on _all_ files in the repository when changes are committed, but this may be prohibitively time-consuming for some tests. It's also desirable to independently run tests to detect problems missed on the development machine due to misconfigured development environments or (occasionally) the intentional disabling of local tests in order to commit work which does not pass tests locally to the remote repository. Continuous Integration (CI) software operating on a remote server, which is often a separate machine to the repository server, enables these tests to be run without unduly impeding developers.

While it is possible to install the various lint packages on the CI server itself, or into a Docker image with a package manager, the drawbacks are:

- an ongoing maintenance overhead of having to update lint package versions in two places, the pre-commit configuration and the Dockerfile, and
- lint tests running in inconsistent, mutable environments which can easily cause unexpected and frustratingly hard-to-debug problems where tests pass in one environment and fail in the other.

Both of these drawbacks can be mitigated, if not eliminated, by running pre-commit in the Docker container where pre-commit will manage the required environments. To accomplish this you must:

1. **Create a Dockerfile** which contains all of the required packages to run pre-commit;
1. **Build the Docker Image**, test it and push it to your GitLab Project's container registry;
1. **Create a GitLab CI Configuration File** to define a `lint` stage and a `lint` job which will execute `pre-commit run --all-files` in a Docker container from the Project container registry.

**Requirement:** One of the strengths of pre-commit is its ability to manage language dependencies, without requiring local installation. To explore this feature, the `.pre-commit-config.yaml` file from the previous assignment, or the example below, must be extended to add Markdownlint <https://github.com/markdownlint/markdownlint/> version 0.12.0 (it is important to use this version because the most recent version contains a nasty bug). Markdownlint requires Ruby, so we must either install Ruby in the development environment or  tell pre-commit to manage the Ruby language itself by setting the `language_version` to a compatible version (see <https://pre-commit.com/#overriding-language-version> for details). Please be aware that you may need to install language build requirements both locally and in the Docker image.

#### 1. Create a Dockerfile

The first step is create and build a Docker image suitable for running pre-commit in a GitLab CI/CD pipeline `lint` job. The requirements are:

- base image is the official Ubuntu 24.04 image;
- the same version of required packages installed locally are installed in the Docker image;
- pre-commit can successfully build Ruby when run in the container;
- the Dockerfile passes linting tests

To fulfil the last requirement, you must use the Haskell Dockerfile Linter, Hadolint <https://github.com/hadolint/hadolint>, either installing locally (preferably with a package manager) _or_ by running Hadolint in a Docker container as described in the Hadolint README.

If you choose to use `pip3` to install required packages in the Dockerfile (a wise choice) then you will likely find that the `pip3 install ... ` command fails with an "externally-managed-environment" error. This is due to a recent change in Python and has caught-out many. It's acceptable to brute-force the install with the `--break-system-packages` flag.

**Note:** it's recommended that you first create a Dockerfile which successfully runs pre-commit _without_ the Markdownlint hook and then add the Markdownlint hook to a known-working Docker image.

#### 2. Build a Docker Image

Building the Docker image is accomplished with the `docker build` command, as detailed in _Docker Deep Dive_ [2]; you will likely also find the _Dockerfile Reference_ [3] helpful. Attention should be paid to _Building best practices_ [4] and to current best practice for image tagging and build reproducibility described in the blog posts.

If you want to test-run your Docker image locally before pushing to the container registry (a wise choice) then you can run pre-commit in your container manually:

```text
$ docker run --rm --interactive --tty --volume .:<mountpath> <tag-or-digest>
root@<digest>:/# cd <mountpath>
root@<digest>:/<mountpath># pre-commit run --all-files
[INFO] Initialising environment for https://github.com/pre-commit/pre-commit-hooks
...
trim trailing whitespace.................................................Passed
fix end of files.........................................................Passed
check for added large files..............................................Passed
yamllint.................................................................Passed
ansible-lint.............................................................Passed
```

Once built, the image must be pushed to the ECS GitLab container registry. Commands for building and pushing specific to the ECS instance may be found on the Container Registry page (from GitLab's left sidebar select `Deploy` &rarr; `Container Registry`).

#### 3. Create a GitLab CI Configuration File

Now that the lint Docker image is in your GitLab Project's container registry, you can reference it in a `.gitlab-ci.yml` file. An example file is provided, but you will have to amend it to remove deprecated keywords and tidy the structure. Refer to the GitLab documentation [1] for information on how the variables  used in the example control how the CI pipeline executes.

One thing that is _highly_ desirable is to have the pre-commit cache persist between pipeline runs. Without caching, pre-commit will install its environment to the container _every_ time it is run. To cache the pre-commit files, a `cache` keyword is used in the example, taken from the pre-commit documentation <https://pre-commit.com/#gitlab-ci-example>. Note that the

#### Definition of Done

You will meet the Core requirements when the `lint` job in your CI pipeline runs `pre-commit run --all-files` and passes.

#### Example Files

The following example files may exhibit both poor practice and/or obsolete conventions and pinned version, and may require amendment to successfully complete this assignment.

##### Example `.pre-commit-config.yaml` File

```yaml
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more supported hooks
# See also: https://pypi.org/project/pre-commit-hooks/

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-added-large-files
        args: ['--maxkb=10240']
  - repo: https://github.com/adrienverge/yamllint.git
    rev: v1.35.1
    hooks:
      - id: yamllint
  - repo: https://github.com/ansible/ansible-lint
    rev: v24.6.0
    hooks:
      - id: ansible-lint
  - repo: https://github.com/jorisroovers/gitlint
    rev: v0.19.1
    hooks:
      - id: gitlint
```

#### Example `.gitlab-ci.yml` Configuration

```yaml
image: python:3

default:
  tags:
    - docker

stages:
  - lint

####################################################
# LINT STAGE
####################################################

lint:
  stage: lint
  image: $CI_REGISTRY_IMAGE:lint
  variables:
    PRE_COMMIT_HOME: ${CI_PROJECT_DIR}/.cache/pre-commit
  cache:
    paths:
      - ${PRE_COMMIT_HOME}
  script:
    - pre-commit run --all-files
```

##### Example Dockerfile

```docker
# A Docker image containing packages required for lint (and build).
FROM ubuntu:22.04
ENV TZ=Pacific/Auckland
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --quiet --assume-yes --no-install-recommends \
        apt-utils=2.4.8 \
        tzdata=2022c-0ubuntu0.22.04.0 \
        git=1:2.34.1-1ubuntu1.4 \
        ruby=1:3.0~exp1 \
        python3=3.10.6-1~22.04 \
        python3-pip=22.0.2+dfsg-1 \
        make=4.3-4.1build1 \
        curl && \
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install --quiet --assume-yes --no-install-recommends nodejs && \
    pip3 install \
        pre-commit==2.19.0 \
        pylint==2.13.4 \
        pylint-ignore==2021.1024 \
        mpy-cross==1.14 && \
    apt-get remove apt-utils curl --quiet --assume-yes && \
    apt-get autoremove --quiet --assume-yes && \
    rm -rf /var/lib/apt/lists/*
CMD ["bash"]
```

### Completion Task

The next step is to take the WordPress blog created in the previous assignment and run it in a container.

The recommended way to do this is to run the WordPress and MySQL services in separate containers, using  Docker Compose with a `docker-compose.yml` file to define the configuration. There is a _significant_ body of examples online of how to run WordPress in a Docker container, and Docker Deep Dive [2] gives instruction on using Docker Compose, to help you reach the goal of "containerising" your WordPress blog. You will be assessed on how well you communicate the steps taken to achieve the Completion goal.

**There is only one specific requirement:** your containerised WordPress blog must be accessible from a web browser by visiting either <http://localhost:8000> or, equivalently, <http://127.0.0.1:8000>.

#### Definition of Done

When your WordPress site can be deployed directly from version control, i.e. from a `git clone` of your repository your containerised WordPress instance can be spun-up and visiting <http://localhost:8000> in a web browser shows blog posts (plural!) written by you, then you've reached Completion!

**Note:** this assignment requires you to maintain your WordPress database under version control, i.e. to commit changes to the database to your repository alongside your source code. This is not necessarily best practice!

### Challenges!

These are more advanced tasks focussed on good practice, automation and reliability. It is not necessary to complete all challenge tasks to receive full marks for this section, attempting one or two of the hardest challenges to a high standard, or achieving three or four of the easier challenges to high standard will earn full marks. There is significant uncertainty associated with these tasks: some challenge tasks may be easier than expected while others may be difficult or even impossible. If you can't complete a challenge within the time allocated don't worry, documenting your attempt and what you learned is most important.

For each challenge you attempt, write a short post in your blog reflecting on what you achieved or learned. **The blog post forms part of the assessment.**

1. **`Just for Fun`** Vagrant has providers for several virtualisation platforms, including Docker. How hard is it to run your Ansible Playbook from the previous assignment on an Ubuntu 24.04 Docker container using Vagrant? What differences can you see between configuration management with Ansible and Docker Compose?

1. **`Relatively Easy`** The recent divergence of CPU architectures has given rise to Docker images which are not portable. For example, if you are working with a Mac which has a Silicon processor then the image you build will not, by default, be built to run on any other architecture. This may cause a Docker image built on a Macintosh to not run, or to run with warnings and errors, on a CI server which has a different architecture. Docker now supports multi-architecture builds with `buildx` which creates images for several (configurable) architectures in one build and allows Docker to manage the manifest when a container is created from the multi-architecture image. What are the steps required to create a multi-architecture build and what pitfalls (if any) did you encounter?

1. **`Moderately Hard`** Assess the security of your WordPress instance. Questions to answer include: How can you determine the vulnerabilities which affect your instance? What are the recognised security practices for running WordPress, PHP, nginx and MySQL in an Ubuntu container? How many of the security practices are you following? How will security be handled during upgrades, will security be a manual or an automated process? What are you doing to ensure that security is an actioned consideration at the beginning, when the Docker image is constructed, rather than at the end once the container is running?

1. **`Moderately Hard`** Follow the recommended practice and add a job to your `.gitlab-ci.yml` file build your Docker images and push them to your container registry _only_ when the Dockerfile or Docker Compose files change. You will have to run Docker in Docker, the official image may be found at <https://hub.docker.com/_/docker>. You will need to automate the tagging, perhaps also need to pass data to the Dockerfile by specifying the `ARG` command, or specifying environment variables for Docker Compose, and also find the GitLab CI configuration options [1] which specify rules for running jobs. GitLab Hint: you will have to work out how to use

   ```yaml
   rules:
    - changes:
        - <filepath>
   ```

1. **`Hard`** While it is best practice is to run one process per container, as was accomplished in the Completion section, it is possible to run WordPress, PHP, nginx and MySQL in a single container analogous to the Virtualbox/VMware virtual machine from the previous assignment. Without using Ansible (that would be too easy!) what is required to run your WordPress instance in a single container from an image specified in a single Dockerfile? What can you say about this experience compared to

### Submission

Submit a link to your GitLab Project via the ECS Submission system <https://apps.ecs.vuw.ac.nz/submit/SWEN426>. The purpose of this is to indicate to staff that your work is ready for marking.

**Remember:** you must maintain your WordPress DB under version control, in order to have your blog posts available for marking. The process defined in the _Making a Backup_ section of the previous assignment should allow you to preserve your valuable posts... remember to commit them to version control before submitting!

### Marking Criteria

This assignment is less-specified that the previous assignment, simply completing a well-specified goal is not sufficient to perform to a high standard. What is assessed is your communication of _how_ you achieved the goals in the Core, Completion and Challenge sections and _why_ you took the specific steps on the way to reaching the goals. This is a crucial part of DevOps, the "S" in CALMRS stands for "Sharing", after all!

Thus, in addition to an operating CI pipeline and a containerised WordPress instance meeting the "Definitions of Done", it is expected that:

1. The Methodological Advice is followed: work is planned; Issues contain descriptions, details and links; Merge Requests represent a coherent body of work and consequently will typically comprise more than one commit; Labels are used to effectively communicate work.

1. The commit history on `main` shows squash commits of the form `type(scope): description (#X via !Y)`.<br/> GitLab hyperlinks the `#X` and `!Y` in its interface and these links will be used for assessment purposes. From the Methodological Advice: see <https://blog.carbonfive.com/always-squash-and-rebase-your-git-commits> for historic advocacy of this workflow.

1. Best practice, defined in the References section, has been followed: the Dockerfile will pass Hadolint tests and the "best practice" advice adopted and adapted to "good practice" for this assignment.

The highest level of performance is a submission which shows _how_ and _why_ the working CI pipeline and containerised WordPress instance were achieved, allowing your work to be operated, maintained and extended by others.


## References

1. Get started with GitLab CI/CD <https://docs.gitlab.com/ee/ci>
1. Docker Deep Dive by Nigel Poulton <https://learning.oreilly.com/library/view/docker-deep-dive/9781835081709/>
1. Dockerfile reference <https://docs.docker.com/reference/dockerfile>
1. Building best practices <https://docs.docker.com/build/building/best-practices>

### Blog Posts

1. What Makes a Build Reproducible, Part 1 <https://blogs.vmware.com/opensource/2022/07/12/what-makes-a-build-reproducible-part-1>
1. What Makes a Build Reproducible, Part 2 <https://blogs.vmware.com/opensource/2022/07/14/what-makes-a-build-reproducible-part-2>
1. Reproducibility Best Practices Meet Docker <https://blogs.vmware.com/opensource/2022/08/23/reproducibility-best-practices-meet-docker>
1. Docker Best Practices for Python Developers <https://testdriven.io/blog/docker-best-practices>
1. Docker Tagging: Best practices for tagging and versioning Docker images <https://stevelasker.blog/2018/03/01/docker-tagging-best-practices-for-tagging-and-versioning-docker-images>
1. Docker Commands Cheat Sheet <https://medium.com/@v.ben/docker-commands-cheat-sheet-part-1-image-management-9da8aeda6044>

---
