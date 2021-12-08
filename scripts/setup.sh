#!/bin/bash

# prerequisites: krew needs to be installed. https://krew.sigs.k8s.io/docs/user-guide/setup/install/
# on mac OS:
brew install krew

# install kuttl: https://github.com/kudobuilder/kuttl
kubectl krew install kuttl
