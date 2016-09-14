#!/usr/bin/env bash
set -e

function setupDeployKey() {
  echo "Setting up deploy key..."
  echo $SCALAFMT_PASSWORD | gpg --passphrase-fd 0 ${DEPLOY_KEY}.gpg
  echo $SCALAFMT_PASSWORD | gpg --passphrase-fd 0 secring.gpg.gpg
  echo $SCALAFMT_PASSWORD | gpg --passphrase-fd 0 homebrew_key.gpg
  chmod 600 ${DEPLOY_KEY}
  chmod 600 homebrew_key
  eval `ssh-agent -s`
  ssh-add ${DEPLOY_KEY}
  ssh-add homebrew_key
  git config --global user.name "Travis CI"
  git config --global user.email "$COMMIT_AUTHOR_EMAIL"
  echo "Done!"
}

function setupRelease() {
  echo "Installing github-release"
  wget https://github.com/aktau/github-release/releases/download/v0.6.2/linux-amd64-github-release.tar.bz2
  tar xvf linux-amd64-github-release.tar.bz2
  export PATH=$PATH:bin/linux/amd64
  echo "Done!"
}

if [[ ${TRAVIS_SECURE_ENV_VARS} == "true" && ${TRAVIS_BRANCH} == "master" ]]; then
  echo "Publishing snapshot..."
  setupDeployKey
  # Assert that nightly is set to snapshot.
  if grep "nightly.*SNAPSHOT" core/src/main/scala/org/scalafmt/Versions.scala; then
    echo "Publishing snapshot"
    sbt publish # snapshot
  else
    echo "Releasing"
    setupRelease
    ./bin/publish.sh -q
  fi
  ./bin/update-gh-pages.sh
else
  echo "Skipping publish"
fi