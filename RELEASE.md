# Release process

All releases
------------

This document simply outlines the release process:

1. Update version string in this project's gemspec file, and commit the change

1. Tag the current commit, build and push the gem to rubygems.org by running `rake publish`

1. Ensure `CHANGELOG.md` is updated by running `rake changelog`,  committing and pushing the changes.
