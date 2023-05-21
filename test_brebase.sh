#!/bin/bash

export BREBASE_MAIN_BRANCH="feature-1"  #// This value will be changed in test function.

function  Main() {
    TestPush
    TestPushNotMergeAndPull
    TestConflict
    TestUndefinedMainBranch
    echo  "Pass"
    rm -rf  "_work"
}

function  TestPush() {
    echo  ""
    echo  "TestPush =================================="
    ResetGitWorking  "_work"  "feature-1"
    pushd   "_work" > /dev/null  ||  Error
        #// Commit graph:
        #//     F
    local  firstFeatureCommitID="$( GetCommitID )"

    #// commit
        git checkout -b  "feature-1-local-A"  > /dev/null  2>&1
        echo  "a"  >  "a.txt"
        git add  "."  > /dev/null

        echo  '$ git commit -m "A1"'
        git commit -m "A1"
            #// Commit graph:
            #//     F - A
        local  status="$( ../brebase status )"
        echo "${status}"
        $assert  echo "${status}"  |  grep  "${AheadPhrase}" > /dev/null  ||  Error

    #// push
        echo  '$ brebase push'

        ../brebase push  ||  Error  #// Merge
            #// Commit graph:
            #//     o - F&A
        local  status="$( ../brebase status )"
        test  "${status}" == ""  ||  Error
        AssertExist  "a.txt"
        test  "$( GetCurrentGitBranch )" == "feature-1-local-A"  ||  Error
        local  localCommitID="$( GetCommitID )"
        git checkout  "feature-1"  > /dev/null  2>&1
        AssertExist  "a.txt"
        local  featureCommitID="$( GetCommitID )"

        test  "${localCommitID}" == "${featureCommitID}"  ||  Error
        test  "${featureCommitID}" != "${firstFeatureCommitID}"  ||  Error
    popd  > /dev/null
    rm -rf  "_work"
}

function  TestPushNotMergeAndPull() {
    echo  ""
    echo  "TestPushNotMergeAndPull =================================="
    ResetGitWorking  "_work"  "feature-1"
    pushd   "_work" > /dev/null  ||  Error
        #// Commit graph:
        #//     F
    git checkout -b  "old-feature-1"  > /dev/null  2>&1

    #// push local-A
        git checkout -b  "feature-1-local-A"  > /dev/null  2>&1
        echo  "a"  >  "a.txt"
        git add  "."  > /dev/null

        echo  '$ git commit -m "A1"'
        git commit -m "A1"

        echo  '$ brebase push'
        ../brebase push  ||  Error  #// Merge
            #// Commit graph:
            #//     o - F&A
        test  "$( GetCurrentGitBranch )" == "feature-1-local-A"  ||  Error

    #// push local-B
        git checkout  "old-feature-1"  > /dev/null  2>&1
        git checkout -b  "feature-1-local-B"  > /dev/null  2>&1
        echo  "b"  >  "b.txt"
        git add  "."  > /dev/null

        echo  '$ git commit -m "B1"'
        git commit -m "B1"
            #// Commit graph:
            #//         B
            #//       /
            #//     o - F&A

        echo  '$ brebase push'
        ../brebase push  2> "_err_out.log"  ||  Error
        local  errOut="$( cat "_err_out.log" )"
        rm  "_err_out.log"
        echo  "${errOut}"
        local  status="$( ../brebase status )"
        echo "${status}"
        $assert  echo "${status}"  |  grep  "${BehindPhrase}" > /dev/null  ||  Error
        AssertExist     "b.txt"
        AssertNotExist  "a.txt"
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  localBCommitID="$( GetCommitID )"
        local  featureCommitID="$( GetCommitID  "."  "feature-1" )"

        test  "${localBCommitID}" != "${featureCommitID}"  ||  Error
        $assert  echo "${errOut}" | grep "WARNING: brebase push did not merge" > /dev/null  ||  Error

    #// pull
        git checkout  "feature-1-local-B"  > /dev/null  2>&1

        echo  '$ brebase pull'
        ../brebase pull  ||  Error  #// Rebase
            #// Commit graph:
            #//               B
            #//             /
            #//     o - F&A
        local  status="$( ../brebase status )"
        echo "${status}"
        $assert  echo "${status}"  |  grep  "${AheadPhrase}" > /dev/null  ||  Error
        AssertExist  "a.txt"
        AssertExist  "b.txt"
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  localBCommitID="$( GetCommitID )"
        git checkout  "feature-1"  > /dev/null  2>&1
        AssertExist     "a.txt"
        AssertNotExist  "b.txt"
        local  featureCommitID="$( GetCommitID )"

        test  "${localBCommitID}" != "${featureCommitID}"  ||  Error

    #// push
        git checkout  "feature-1-local-B"  > /dev/null  2>&1

        echo  '$ brebase push'
        ../brebase push  ||  Error  #// Merge
            #// Commit graph:
            #//     o - A - F&B
        local  status="$( ../brebase status )"
        test  "${status}" == ""  ||  Error
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  localBCommitID="$( GetCommitID )"
        git checkout  "feature-1"  > /dev/null  2>&1
        AssertExist  "a.txt"
        AssertExist  "b.txt"
        local  featureCommitID="$( GetCommitID )"

        test  "${localBCommitID}" == "${featureCommitID}"  ||  Error

    #// push (It does nothing)
        git checkout  "feature-1-local-B"  > /dev/null  2>&1

        echo  '$ brebase push'
        ../brebase push  ||  Error  #// Do nothing
        local  status="$( ../brebase status )"
        test  "${status}" == ""  ||  Error
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  currentLocalBCommitID="$( GetCommitID )"
        local  oldLocalBCommitID="${localBCommitID}"

        test  "${currentLocalBCommitID}" == "${oldLocalBCommitID}"  ||  Error

    #// pull (It does nothing)
        git checkout  "feature-1-local-B"  > /dev/null  2>&1

        echo  '$ brebase pull'
        ../brebase pull  ||  Error  #// Do nothing
        local  status="$( ../brebase status )"
        test  "${status}" == ""  ||  Error
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  currentLocalBCommitID="$( GetCommitID )"
        local  oldLocalBCommitID="${localBCommitID}"

        test  "${currentLocalBCommitID}" == "${oldLocalBCommitID}"  ||  Error
    popd  > /dev/null
    rm -rf  "_work"
}

function  TestConflict() {
    echo  ""
    echo  "TestConflict =================================="
    ResetGitWorking  "_work"  "feature-1"
    pushd   "_work" > /dev/null  ||  Error
        #// Commit graph:
        #//     F
    git checkout -b  "old-feature-1"  > /dev/null  2>&1

    #// push local-A
        git checkout -b  "feature-1-local-A"  > /dev/null  2>&1
        echo  "a"  >  "0.txt"
        git add  "."  > /dev/null

        echo  '$ git commit -m "A1"'
        git commit -m "A1"

        echo  '$ brebase push'
        ../brebase push  ||  Error  #// Merge
            #// Commit graph:
            #//     o - F&A
        local  status="$( ../brebase status )"
        test  "${status}" == ""  ||  Error
        test  "$( GetCurrentGitBranch )" == "feature-1-local-A"  ||  Error

    #// push local-B
        git checkout  "old-feature-1"  > /dev/null  2>&1
        git checkout -b  "feature-1-local-B"  > /dev/null  2>&1
        echo  "b"  >  "0.txt"
        git add  "."  > /dev/null

        echo  '$ git commit -m "B1"'
        git commit -m "B1"

        echo  '$ brebase push'
        ../brebase push  2>&1 > "_err_out.log"  ||  Error  #// Not merge
            #// Commit graph:
            #//         B
            #//       /
            #//     o - F&A
        local  status="$( ../brebase status )"
        echo "${status}"
        $assert  echo "${status}"  |  grep  "${BehindPhrase}" > /dev/null  ||  Error
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  localBCommitID="$( GetCommitID )"
        git checkout  "feature-1"  > /dev/null  2>&1
        local  featureCommitID="$( GetCommitID )"

    #// pull (conflict)
        git checkout  "feature-1-local-B"  > /dev/null  2>&1

        echo  '$ brebase pull'
        ../brebase pull  &&  Error  #// git rebase "feature-1"
            #// interactive rebase is in progress

        echo  "a&b"  >  "0.txt"
        git add  "."  > /dev/null

        echo  '$ git rebase --continue'
        GIT_EDITOR=true  git rebase --continue  ||  Error
            #// Commit graph:
            #//               B
            #//             /
            #//     o - F&A
        local  status="$( ../brebase status )"
        echo "${status}"
        $assert  echo "${status}"  |  grep  "${AheadPhrase}" > /dev/null  ||  Error

        echo  '$ brebase push'
        ../brebase push  ||  Error
            #// Commit graph:
            #//     o - A - F&B
        local  status="$( ../brebase status )"
        test  "${status}" == ""  ||  Error
        test  "$( cat "0.txt" )" == "a&b"  ||  Error
        test  "$( GetCurrentGitBranch )" == "feature-1-local-B"  ||  Error
        local  localBCommitID="$( GetCommitID )"
        git checkout  "feature-1"  > /dev/null  2>&1
        local  featureCommitID="$( GetCommitID )"

        test  "${localBCommitID}" == "${featureCommitID}"  ||  Error
    popd  > /dev/null
    rm -rf  "_work"
}

function  TestUndefinedMainBranch() {
    echo  ""
    echo  "TestUndefinedMainBranch =================================="
    echo  "This is error handling tests."
    ResetGitWorking  "_work"  "feature-1"
    pushd   "_work" > /dev/null  ||  Error
    local  firstFeatureCommitID="$( GetCommitID )"
    local  oldEnv="${BREBASE_MAIN_BRANCH}"
    git checkout -b  "feature-1-local-A"  > /dev/null  2>&1

    echo  'BREBASE_MAIN_BRANCH=""'
    BREBASE_MAIN_BRANCH=""

    echo  '$ brebase push'
        ../brebase push  &&  Error
        local  currentFeatureCommitID="$( GetCommitID )"
        test  "${currentFeatureCommitID}" == "${firstFeatureCommitID}"  ||  Error

    echo  '$ brebase pull'
        ../brebase pull  &&  Error
        local  currentFeatureCommitID="$( GetCommitID )"
        test  "${currentFeatureCommitID}" == "${firstFeatureCommitID}"  ||  Error

    echo  'BREBASE_MAIN_BRANCH="not-defined-branch-name"'
    BREBASE_MAIN_BRANCH="not-defined-branch-name"

    echo  '$ brebase push'
        ../brebase push  &&  Error
        local  currentFeatureCommitID="$( GetCommitID )"
        test  "${currentFeatureCommitID}" == "${firstFeatureCommitID}"  ||  Error

    echo  '$ brebase pull'
        ../brebase pull  &&  Error
        local  currentFeatureCommitID="$( GetCommitID )"
        test  "${currentFeatureCommitID}" == "${firstFeatureCommitID}"  ||  Error
    popd  > /dev/null
    rm -rf  "_work"
    BREBASE_MAIN_BRANCH="${oldEnv}"
}


function  ResetGitWorking() {
    local  workFolderPath="$1"
    local  newBranchName="$2"
    rm -rf  "${workFolderPath}"
    mkdir   "${workFolderPath}"
    pushd   "${workFolderPath}" > /dev/null  ||  Error

    git init ${GitInitOption}  > /dev/null  2>&1
    git config --local user.email "you@example.com"
    git config --local user.name "Your Name"

    echo  "0"  >  "0.txt"
    git checkout -b  "${newBranchName}"  > /dev/null 2>&1
    git add  "."  > /dev/null
    git commit -m "First commit."  > /dev/null
    popd  > /dev/null
}

function  GetCurrentGitBranch() {
    git rev-parse --abbrev-ref HEAD
}

function  GetCommitID() {
    local  gitWorkingFolderPath="$1"
    local  branch="$2"
    if [ "${branch}" == "" ]; then
        branch="HEAD"
    fi
    if [ "${gitWorkingFolderPath}" == "" ]; then
        gitWorkingFolderPath="."
    fi
    pushd  "${gitWorkingFolderPath}"  > /dev/null  ||  Error

    git rev-parse --short "${branch}"
    popd  > /dev/null
}

function  gitInitOption() {
    if [ "$( LessThanVersion "$(git --version)" "2.31.1" )" == "${True}" ]; then
        echo  ""
    else
        echo  "-bmain"  #// "-b main" occurs an error in bash debug
    fi
}

# LessThanVersion
#     if [ "$( LessThanVersion "$(git --version)" "2.31.1")" == "${True}" ]; then
function  LessThanVersion() {
    local  textContainsVersionA="$1"
    local  textContainsVersionB="$2"
    local  isGoodFormat="${True}"
    echo "${textContainsVersionA}" | grep -e "[0-9]\+\.[0-9]\+\.[0-9]\+" > /dev/null  ||  isGoodFormat="${False}"
    echo "${textContainsVersionB}" | grep -e "[0-9]\+\.[0-9]\+\.[0-9]\+" > /dev/null  ||  isGoodFormat="${False}"
    if [ "${isGoodFormat}" == "${False}" ]; then
        Error  "\"${textContainsVersionA}\" or \"${textContainsVersionB}\" is not semantic version."
    fi

    local  numbersA=( $( echo "${textContainsVersionA}" | grep -o -e "[0-9]\+" ) )
    local  numbersB=( $( echo "${textContainsVersionB}" | grep -o -e "[0-9]\+" ) )
    if [ "${numbersA[0]}" -lt "${numbersB[0]}" ]; then
        echo "${True}"
        return
    elif [ "${numbersA[0]}" == "${numbersB[0]}" ]; then
        if [ "${numbersA[1]}" -lt "${numbersB[1]}" ]; then
            echo "${True}"
            return
        elif [ "${numbersA[1]}" == "${numbersB[1]}" ]; then
            if [ "${numbersA[2]}" -lt "${numbersB[2]}" ]; then
                echo "${True}"
                return
            fi
        fi
    fi
    echo "${False}"
}

function  AssertExist() {
    local  path="$1"
    local  leftOfWildcard="${path%\**}"
    if [ "${leftOfWildcard}" == "${path}" ]; then  #// No wildcard

        if [ ! -e "${path}" ]; then
            Error  "ERROR: Not found \"${path}\""
        fi
    else
        local  rightOfWildcard="${path##*\*}"
        if [ ! -e "${leftOfWildcard}"*"${rightOfWildcard}" ]; then
            Error  "ERROR: Not found \"${path}\""
        fi
    fi
}

function  AssertNotExist() {
    local  path="$1"

    if [ -e "${path}" ]; then
        Error  "ERROR: Found \"${path}\""
    fi
}

function  Error() {
    local  errorMessage="$1"
    local  exitCode="$2"
    if [ "${errorMessage}" == "" ]; then
        errorMessage="ERROR"
    fi
    if [ "${exitCode}" == "" ]; then  exitCode=2  ;fi

    echo  "${errorMessage}" >&2
    exit  "${exitCode}"
}

AheadPhrase="Your branch is ahead"
BehindPhrase="Your branch is behind"
assert=""  #// This assert indicates to test the exit code
True=0
False=1
GitInitOption=$(gitInitOption)

Main
