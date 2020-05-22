#!/usr/bin/env python3
# ----------------------------------------------------------------------------
# Description: Script to update all the LCLS-II repos to the same submodule configuration
# ----------------------------------------------------------------------------
# This file is part of the 'SLAC Firmware Standard Library'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'SLAC Firmware Standard Library', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
# ----------------------------------------------------------------------------

import os
import argparse
import click

import github # PyGithub

#############################################################################################

#####################################
# [repo name, pull respect reviewers]
#####################################
repoList  =  [
    ###############################
    # application engineer = leosap
    ###############################
    ['slaclab/lcls2-bcm',           ['leosap']],
    ['slaclab/lcls2-blen',          ['leosap']],
    ['slaclab/lcls2-bpm-stripline', ['leosap']],
    ['slaclab/lcls2-fws',           ['leosap']],
    ['slaclab/lcls2-mps',           ['leosap']],
    ['slaclab/lcls-mr-bcm',         ['leosap']],
    ['slaclab/lcls-mr-blen',        ['leosap']],
    ############################################
    # application engineer = thatweaver/jmdewart
    ############################################
    ['slaclab/lcls2-rfOvrFbr',  ['thatweaver','jmdewart']],
    ['slaclab/lcls-mr-llrf',    ['thatweaver','jmdewart']],
    ['slaclab/lcls-ued-llrf',   ['thatweaver','jmdewart']],
    ['slaclab/lcls-pcav',       ['thatweaver','jmdewart']],
    ['slaclab/lcls2-pcav',      ['thatweaver','jmdewart']],
    ['slaclab/lcls2-pcav-test', ['thatweaver','jmdewart']],
    ['slaclab/lcls2-timing',    ['thatweaver','jmdewart']],
    ###############################
    # application engineer = ruck314
    ###############################
    ['slaclab/amc-carrier-project-template',['ruck314']],
    ['slaclab/lcls2-llrf',                  ['ruck314']],
]

#############################################################################################

########################################
# [submodule name, tag release]
# Must match amc-carrier-core/ruckus.tcl
########################################

submoduleConfig  =  [
    ['amc-carrier-core','v3.3.0'],
    ['lcls-timing-core','v2.0.0'],
    ['ruckus',          'v2.5.0'],
    ['surf',            'v2.5.0'],
]

#############################################################################################

# Create the body pull request and commit string
msg  = '### Submodule Configuration\n'
msg += '|Submodule|Tag|\n'
msg += '| :-:|:-:|\n'
for [submodule, tag] in submoduleConfig:
    msg += f'|{submodule}|{tag}|\n'

#############################################################################################

# Convert str to bool
def argBool(s):
    return s.lower() in ['true', 't', 'yes', '1']

# Set the argument parser
parser = argparse.ArgumentParser('Create New Project')

# Add arguments
parser.add_argument(
    '--token',
    type     = str,
    required = False,
    default  = None,
    help     = 'Token for github'
)

# Get the arguments
args = parser.parse_args()

#############################################################################################

def githubLogin():

    # Inform the user that you are logging in
    click.secho('\nLogging into github....\n', fg='green')

    # Check if token arg defined
    if args.token is not None:

        # Inform the user that command line arg is being used
        print('Using github token from command line arg.')

        # Set the token value
        token = args.token

    # Check if token arg NOT defined
    else:

        # Set the token value from environmental variable
        token = os.environ.get('GITHUB_TOKEN')

        # Check if token is NOT defined
        if token is None:

            # Ask for the token from the command line prompt
            print('Enter your github token. If you do no have one you can generate it here:')
            print('    https://github.com/settings/tokens')
            print('You may set it in your environment as GITHUB_TOKEN\n')

            # Set the token value
            token = input('\nGithub token: ')

        # Else the token was defined
        else:

            # Inform the user that you are using GITHUB_TOKEN
            print('Using github token from user\'s environment.\n')

    # Now that you have a token, log into Github
    gh = github.Github(token)

    # Return the github login object
    return gh


#############################################################################################

def updateRepoSubmodules(repo):
    click.secho(f'Updating {repo.name} Submodules ...', fg='green')

    # Submodule directory path
    baseDir = f'{repo.name}/firmware/submodules'

    # Create a temporary clone the repo
    os.system(f'git clone --quiet --recursive git@github.com:{repo.full_name}')

    # Make a new branch
    os.system(f'cd {baseDir}; git branch -f submodule-update; git checkout submodule-update')

    # Update the submodule tag release
    for [submodule, tag] in submoduleConfig:
        click.secho(f'submodules={submodule},tag={tag}', fg='blue')
        os.system(f'cd {baseDir}/{submodule}; git fetch; git checkout {tag}')

    # Add and commit
    os.system(f'cd {baseDir}; git fetch; git add .; git commit -m \"updating submodule configuration\" -m \"{msg}\" ' )

    # Push the changes to Github
    os.system(f'cd {baseDir}; git push --force --set-upstream origin submodule-update')

    # Remove the temporary clone
    os.system(f'rm -rf {repo.name}')

    print('\n')

#############################################################################################
def createPullRequest(repo,reviewers):
    click.secho(f'Creating {repo.name} pull request ...', fg='green')

    # Create the pull request
    pr = repo.create_pull(
        title     = 'Updating sumodule configuration',
        body      = msg,
        head      = 'submodule-update',
        base      = 'master',
    )

    # Check that I am not the reviewer
    if ( 'ruck314' not in reviewers):

        # Assign the reviewer
        pr.create_review_request(reviewers=reviewers)

    # Print the PR URL
    click.secho(f'{pr.html_url}', fg='yellow')

#############################################################################################

if __name__ == '__main__':

    # Log into Github
    gh   = githubLogin()

    # Loop through repos
    for [name, user] in repoList:

        # open Github repo
        repo =  gh.get_repo(name)

        # Update Repo submodules
        # updateRepoSubmodules(repo)

    # Loop through repos
    for [name, reviewers] in repoList:

        # Create the pull request
        createPullRequest(repo,reviewers)

    click.secho('Success', fg='green')
